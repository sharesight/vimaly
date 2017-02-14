require 'faraday'
require 'faraday_middleware'
require 'date'

module Obeya
  class Client

    OBEYA_ROOT_URL = "https://beta.getobeya.com"
    CUSTOM_FIELD_TYPES = [::NilClass, ::String, ::Float, ::Integer, ::Array, ::Date]

    def initialize(company_id, username, password, logger=nil)
      @company_id = company_id
      @username = username
      @password = password
      @logger = logger

      @bin_tickets = {}
    end

    def create_ticket(title, description, format: 'text', ticket_type_name: 'bug', bin_name: /please panic/i, **others)
      ticket = Ticket.new({
        title: title,
        description: description,
        format: format,
        ticket_type: ticket_type(ticket_type_name),
        bin: bin(bin_name) }.
        merge(others)
      )

      ticket_to_json = ticket.to_json(custom_field_name_map)
      response = post("/tickets/#{next_ticket_id}", ticket_to_json)
      case response.status
      when 200..299
        true
      else
        log_warn "status: #{response.status}"
        log_warn "        #{response.inspect}"
        false
      end
    end

    def update_ticket(id, other_fields)
      ticket = Ticket.new(other_fields)

      response = put("/tickets/#{id}", ticket.to_json(custom_field_name_map, true))
      case response.status
        when 200..299
          true
        else
          log_warn "status: #{response.status}"
          log_warn "        #{response.inspect}"
          false
      end
    end

    def bin(name_or_regex)
      case name_or_regex
      when String
        bins.detect { |bin| bin.name == name_or_regex }
      when Regexp
        bins.detect { |bin| bin.name =~ name_or_regex }
      end
    end

    def bins
      @bins ||= begin
        get('/bins').map do |bin_data|
          Bin.new(bin_data['_id'], bin_data['name'])
        end
      end
    end

    def ticket_type(name_or_regex)
      case name_or_regex
      when String
        ticket_types.detect { |tt| tt.name == name_or_regex }
      when Regexp
        ticket_types.detect { |tt| tt.name =~ name_or_regex }
      end
    end

    def ticket_types
      @ticket_types ||= begin
        get('/ticket-types').map do |bin_data|
          TicketType.new(bin_data['_id'], bin_data['name'])
        end
      end
    end

    def tickets_in_named_bin(bin_name)
      named_bin = bin(bin_name)
      raise "Bin #{bin_name} not found" unless named_bin
      tickets_in_bin(named_bin.id)
    end

    def tickets_in_bin(bin_id)
      ticket_type_map = Hash[ticket_types.map { |t| [t.id, t] }]
      bin_map = Hash[bins.map { |b| [b.id, b] }]

      @bin_tickets[bin_id] ||= begin
        get("/tickets?bin_id=#{bin_id}").map do |ticket_data|
          Ticket.from_obeya(ticket_data, ticket_type_map, bin_map, custom_fields)
        end
      end
    end

    def matching_tickets_in_named_bin(bin_name, title_matcher)
      named_bin = bin(bin_name)
      raise "Bin #{bin_name} not found" unless named_bin
      matching_tickets_in_bin(named_bin.id, title_matcher)
    end

    def matching_tickets_in_bin(bin_id, title_matcher)
      tickets = tickets_in_bin(bin_id)
      case title_matcher
      when String
        tickets.select { |t| t.title == title_matcher }
      when Regexp
        tickets.select { |t| t.title =~ title_matcher }
      end
    end

    # Get custom fields as a hash of id => {id, name, type}
    def custom_fields
      @custom_fields ||= begin
        Hash[get('/custom-fields').map do |cf|
          [cf['_id'], { id: cf['_id'], name: cf['name'], type: CUSTOM_FIELD_TYPES[cf['type'].to_i] }]
        end]
      end
    end

    private

    def custom_field_name_map
      @custom_field_name_map ||= Hash[custom_fields.values.map {|v| [v[:name], v] }]
    end

    def next_ticket_id
      get('/ids?amount=1')[0]
    end

    def get(api_path)
      response = faraday.get("/rest/1/#{@company_id}#{api_path}") do |request|
        request.headers.update({ accept: 'application/json', content_type: 'application/json' })
      end
      unless response.success?
        raise("Obeya #{api_path} call failed")
      end
      JSON.parse(response.body)
    end

    def post(api_path, json)
      faraday.post("/rest/1/#{@company_id}#{api_path}", json) do |request|
        request.headers.update({ accept: 'application/json', content_type: 'application/json' })
      end
    end

    def put(api_path, json)
      faraday.put("/rest/1/#{@company_id}#{api_path}", json) do |request|
        request.headers.update({ accept: 'application/json', content_type: 'application/json' })
      end
    end

    def faraday
      @faraday ||= Faraday.new(OBEYA_ROOT_URL).tap do |connection|
        connection.basic_auth(@username, @password)
        connection.request(:json)
      end
    end

    def log_warn(s)
      @logger.warn(s) if @logger
    end

  end
end

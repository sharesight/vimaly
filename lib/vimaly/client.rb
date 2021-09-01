require 'faraday'
require 'faraday_middleware'
require 'date'

module Vimaly
  class Client

    VIMALY_ROOT_URL = "https://o1.vimaly.com"
    CUSTOM_FIELD_TYPES = [::NilClass, ::String, ::Float, ::Integer, ::Array, ::Date]

    def initialize(company_id, user_credentials: nil, auth_key: nil, logger: nil)
      @company_id = company_id
      @user_credentials = user_credentials
      @auth_key = auth_key
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

      ticket_id = next_ticket_id
      ticket_to_json = ticket.to_json(custom_field_name_map)
      response = post("/tickets/#{ticket_id}", ticket_to_json)
      case response.status
      when 200..299
        ticket_id
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
        id
      else
        log_warn "status: #{response.status}"
        log_warn "        #{response.inspect}"
        false
      end
    end

    def search_tickets(query_string, state: 'active')
      ticket_type_map = Hash[ticket_types.map { |t| [t.id, t] }]
      bin_map = Hash[bins.map { |b| [b.id, b] }]

      get("/ticket-search?text=#{query_string}&state=#{state}").map do |ticket_data|
        Ticket.from_vimaly(ticket_data, ticket_type_map, bin_map, custom_fields)
      end
    end

    def add_attachment(ticket_id, file_name, file_content, request_options={})
      response = post("/tickets/#{ticket_id}/attachments?name=#{CGI.escape(file_name)}", file_content, request_options)
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

    def bins(options={})
      @bins ||= begin
        # 500 is the vimaly limit
        bins_per_request = options[:bins_per_request] || 500
        # 5000 is just a random value here; hopefully we never reach this limit
        max_number_of_bins = options[:max_number_of_bins] || 5000

        bins = []
        current_page = 0
        while bins.size < max_number_of_bins
          # those request parameters are not documented, maybe this gets added at some
          # point to https://vimaly.com/public/rest-help.html#Bins
          chunk_of_bins = get("/bins?max-results=#{bins_per_request}&page-token=#{current_page * bins_per_request}")
          current_page += 1
          bins += chunk_of_bins
          break if chunk_of_bins.size < bins_per_request
        end
        bins.map do |bin|
          Bin.new(bin['_id'], bin['name'])
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

      get("/tickets?bin_id=#{bin_id}").map do |ticket_data|
        Ticket.from_vimaly(ticket_data, ticket_type_map, bin_map, custom_fields)
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
      response = faraday.get("/rest/2/#{@company_id}#{api_path}") do |request|
        update_request_headers(request)
      end
      unless response.success?
        raise Vimaly::ConnectionError.new("Vimaly #{api_path} call failed with response #{response.status}")
      end
      JSON.parse(response.body)
    end

    def post(api_path, content, headers={})
      faraday.post("/rest/2/#{@company_id}#{api_path}", content) do |request|
        update_request_headers(request, headers)
      end
    end

    def put(api_path, json)
      faraday.put("/rest/2/#{@company_id}#{api_path}", json) do |request|
        update_request_headers(request)
      end
    end

    def faraday
      @faraday ||= Faraday.new(VIMALY_ROOT_URL).tap do |connection|
        connection.basic_auth(@user_credentials[:username], @user_credentials[:password]) if @user_credentials
        connection.request(:json)
      end
    end

    def update_request_headers(request, headers={})
      request.headers.update({ accept: 'application/json', content_type: 'application/json' })
      request.headers.update({ authorization: "bearer #{@auth_key}" }) if @auth_key
      request.headers.update(headers)
    end

    def log_warn(s)
      @logger.warn(s) if @logger
    end

  end
end

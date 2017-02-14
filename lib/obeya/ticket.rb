module Obeya
  class Ticket

    # title, description, format, ticket_type, bin, id=nil
    def initialize(*params)
      if params.first.is_a?(Hash)
        @ticket_fields = params.first
      else
        @ticket_fields = {}
        [:title, :description, :format, :ticket_type, :bin, :id].each_with_index do |param_key, idx|
          break if idx>=params.size
          @ticket_fields[param_key] = params[idx]
        end
      end
    end

    def self.from_obeya(src_hash, ticket_types, bins, custom_fields)
      ticket_fields = Hash[
        src_hash.map do |obeya_name, field_value|
          case(obeya_name)
            when 'rtformat'
              [:format, field_value]
            when 'name'
              [:title, field_value]
            when 'ticketType_id'
              [:ticket_type, ticket_types[field_value.to_i]]
            when 'bin_id'
              [:bin, bins[field_value.to_i]]
            when 'customFields'
              nil
            else
              [obeya_name.to_sym, field_value]
          end
        end.compact
      ]

      (src_hash['customFields'] || []).each do |custom_field_id, value|
        ticket_fields[custom_fields[custom_field_id][:name]] = value
      end

      Obeya::Ticket::new(ticket_fields)
    end

    def to_obeya(custom_field_name_map, for_update=false)
      obeya_fields = Hash[@ticket_fields.map do |field_name, field_value|
        case(field_name)
          when :format
            ['rtformat', field_value]
          when :title
            ['name', field_value]
          when :description
            ['description', normalise(field_value)]
          when :ticket_type
            ['ticketType_id', field_value.id]
          when :bin
            ['bin_id', field_value.id]
          else
            if for_update
              fdef = custom_field_name_map[field_name.to_s]
              ["customFields.#{fdef[:id]}", cast_to_obeya(field_value, fdef[:type])]
            else
              nil
            end
        end
      end.compact
      ]

      unless for_update
        custom_fields = @ticket_fields.select {|fn, _v| ![:format, :title, :description, :ticket_type, :bin].include?(fn) }
        if custom_fields && !custom_fields.empty?
          obeya_fields['customFields'] =
            Hash[custom_fields.map do |field_name, field_value|
              fdef = custom_field_name_map[field_name.to_s]
              [fdef[:id], cast_to_obeya(field_value, fdef[:type])]
            end]
        end
      end

      obeya_fields
    end

    def cast_to_obeya(value, type)
      case type.to_s
        when 'String'
          value.to_s
        when 'Float'
          value.to_f
        when 'Integer'
          value.to_i
        when 'Array'
          value
        when 'Date'
          Date.parse(value.to_s).strftime('%Y-%m-%dT%H:%M:%S.%LZ')
      end
    end

    def to_json(custom_field_name_map, for_update=false)
      to_obeya(custom_field_name_map, for_update).to_json
    end

    def [](name)
      @ticket_fields[name]
    end

    def method_missing(name)
      return @ticket_fields[name] if @ticket_fields.key?(name)

      super
    end

    private

    def normalise(text)
      text.length > 40_000 ? (text[0...39_950] + '...[truncated]') : text
    end

  end
end

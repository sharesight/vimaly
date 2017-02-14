module Vimaly
  class TicketType

    attr_reader :id, :name

    def initialize(id, name)
      @id = id
      @name = name
    end

  end
end

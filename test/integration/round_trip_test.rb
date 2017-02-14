# Obeya integration test
#
# To use, create obeya_config.rb with a copy of obeya.config.example and your local obeya settings
#
# You need a bin called TestAdmin
# a ticket type called Incident
# and custom fields 'Last seen' and 'First seen' in Obeya
#
require 'test_helper'

class RoundTripTest < Minitest::Test

  context 'Obeya API' do
    setup do
      begin
        require_relative 'obeya_config'
        @do_tests = true
      rescue LoadError
      end

      WebMock.allow_net_connect!

      @obeya = ::Obeya::Client.new(COMPANY_ID, USERNAME, PASSWORD) if @do_tests
    end

    context 'bin method' do

      should 'find our bin by full name' do
        skip unless @do_tests
        bin = @obeya.bin('TestAdmin')
        assert_equal 'TestAdmin', bin.name
      end

      should 'find our bin by regex' do
        skip unless @do_tests
        bin = @obeya.bin(/Admin/)
        assert_equal 'TestAdmin', bin.name
      end
    end

    context 'ticket_type method' do

      should 'find our ticket_type by full name' do
        skip unless @do_tests
        tt = @obeya.ticket_type('Incident')
        assert_equal 'Incident', tt.name
      end
    end

    context 'round trip' do

      should 'create, read and update a ticket' do
        skip unless @do_tests

        title = "#{DateTime.now.to_s} Integration test"
        @obeya.create_ticket title, 'Integration test ticket', ticket_type_name: 'Incident', bin_name: 'TestAdmin',
                             'Last seen': Date.new(2016,8,1)

        tickets = @obeya.matching_tickets_in_named_bin('TestAdmin', title)
        assert_equal 1, tickets.size
        assert_equal title, tickets.first.title
        assert_equal 'Integration test ticket', tickets.first.description
        assert_equal '2016-08-01', tickets.first['Last seen']

        @obeya.update_ticket tickets.first._id, description: 'Updated test ticket', 'Last seen': Date.new(2016,8,2)

        @obeya = ::Obeya::Client.new(COMPANY_ID, USERNAME, PASSWORD)  # clear cache
        tickets = @obeya.matching_tickets_in_named_bin('TestAdmin', title)
        assert_equal 1, tickets.size
        assert_equal title, tickets.first.title
        assert_equal 'Updated test ticket', tickets.first.description
        assert_equal '2016-08-02', tickets.first['Last seen']
      end
    end

  end

end

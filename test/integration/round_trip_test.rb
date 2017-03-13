# Vimaly integration test
#
# To use, create vimaly_config.rb with a copy of vimaly.config.example and your local vimaly settings
#
# You need a bin called TestAdmin
# a ticket type called Incident
# and custom fields 'Last seen' and 'First seen' in Vimaly
#
require 'test_helper'

class RoundTripTest < Minitest::Test

  context 'Vimaly API' do
    setup do
      begin
        require_relative 'vimaly_config'
        @do_tests = true
      rescue LoadError
      end

      WebMock.allow_net_connect!

      @vimaly = ::Vimaly::Client.new(COMPANY_ID, USERNAME, PASSWORD) if @do_tests
    end

    context 'bin method' do

      should 'find our bin by full name' do
        skip unless @do_tests
        bin = @vimaly.bin('TestAdmin')
        assert_equal 'TestAdmin', bin.name
      end

      should 'find our bin by regex' do
        skip unless @do_tests
        bin = @vimaly.bin(/TestAdmin/)
        assert_equal 'TestAdmin', bin.name
      end
    end

    context 'ticket_type method' do

      should 'find our ticket_type by full name' do
        skip unless @do_tests
        tt = @vimaly.ticket_type('Incident')
        assert_equal 'Incident', tt.name
      end
    end

    context 'round trip' do

      should 'create, read and update a ticket' do
        skip unless @do_tests

        title = "#{DateTime.now.to_s} Integration test"
        @vimaly.create_ticket title, 'Integration test ticket', ticket_type_name: 'Incident', bin_name: 'TestAdmin',
                             'Last seen': Date.new(2016,8,1)

        tickets = @vimaly.matching_tickets_in_named_bin('TestAdmin', title)
        assert_equal 1, tickets.size
        assert_equal title, tickets.first.title
        assert_equal 'Integration test ticket', tickets.first.description
        assert_equal '2016-08-01', tickets.first['Last seen'].to_s

        @vimaly.update_ticket tickets.first._id, description: 'Updated test ticket', 'Last seen': Date.new(2016,8,2)

        @vimaly = ::Vimaly::Client.new(COMPANY_ID, USERNAME, PASSWORD)  # clear cache
        tickets = @vimaly.matching_tickets_in_named_bin('TestAdmin', title)
        assert_equal 1, tickets.size
        assert_equal title, tickets.first.title
        assert_equal 'Updated test ticket', tickets.first.description
        assert_equal '2016-08-02', tickets.first['Last seen'].to_s
      end

      should 'desist from spamming vimaly when multiple duplicate tickets created in a request' do
        skip unless @do_tests

        title = "#{DateTime.now.to_s} Integration test 2"
        @vimaly.create_ticket title, 'Integration test ticket 2', ticket_type_name: 'Incident', bin_name: 'TestAdmin',
                              'Last seen': Date.new(2016,8,1)

        tickets = @vimaly.matching_tickets_in_named_bin('TestAdmin', title)
        assert_equal 1, tickets.size
        assert_equal title, tickets.first.title
        assert_equal 'Integration test ticket 2', tickets.first.description
        assert_equal '2016-08-01', tickets.first['Last seen']

        @vimaly.update_ticket tickets.first._id, description: 'Updated test ticket', 'Last seen': Date.new(2016,8,2)

        tickets = @vimaly.matching_tickets_in_named_bin('TestAdmin', title)
        assert_equal 1, tickets.size
        assert_equal title, tickets.first.title
        assert_equal 'Updated test ticket', tickets.first.description
        assert_equal '2016-08-02', tickets.first['Last seen']
      end
    end

  end

end

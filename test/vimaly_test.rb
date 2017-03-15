require 'test_helper'
require 'stub_vimaly'

class VimalyTest < Minitest::Test

  include StubVimaly

  context 'Vimaly API' do
    setup do
      stub_ticket_types
      stub_bins
      stub_next_ticket_id
      stub_custom_fields
      stub_update_ticket

      @vimaly = Vimaly::Client.new('company_id', 'username', 'password')
    end


    should 'create and update tickets' do

      title = "#{DateTime.now.to_s} Integration test 2"
      description = 'Integration test ticket 2'
      stub_create_ticket(title, description, {'2' => '2016-08-01'} )
      @vimaly.create_ticket title, description, ticket_type_name: 'bug', bin_name: 'Alpha',
                            'Last seen': Date.new(2016,8,1)

      binned_tickets = [ { '_id' => '3',
                         'name' => title,
                         'description' => description,
                         'bin_id' => '1',
                         'ticketType_id' => '1',
                         'order' => 102,
                         'customFields' => {'2' => '2016-08-01' }
                         } ]
      stub_tickets_in_bin binned_tickets
      tickets = @vimaly.matching_tickets_in_named_bin('Alpha', title)
      assert_equal 1, tickets.size
      assert_equal title, tickets.first.title
      assert_equal description, tickets.first.description
      assert_equal '2016-08-01', tickets.first['Last seen']

      updated_description = 'Updated test ticket'
      stub_update_ticket(3, {'description' => updated_description, 'customFields.2' => '2016-08-02' } )
      @vimaly.update_ticket tickets.first._id, description: updated_description, 'Last seen': Date.new(2016, 8, 2)

      binned_tickets = [ { '_id' => '3',
                           'name' => title,
                           'description' => updated_description,
                           'bin_id' => '1',
                           'ticketType_id' => '1',
                           'order' => 102,
                           'customFields' => {'2' => '2016-08-02' }
                         } ]
      stub_tickets_in_bin binned_tickets
      tickets = @vimaly.matching_tickets_in_named_bin('Alpha', title)
      assert_equal 1, tickets.size
      assert_equal title, tickets.first.title
      assert_equal updated_description, tickets.first.description
      assert_equal '2016-08-02', tickets.first['Last seen']
    end

  end

end

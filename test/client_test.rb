require 'test_helper'
require 'stub_vimaly'

class ClientTest < Minitest::Test

  include StubVimaly

  context "creating tickets" do
    setup do
      stub_ticket_types
      stub_bins
      stub_next_ticket_id
      stub_custom_fields

      @client = Vimaly::Client.new('company_id', 'username', 'password')
    end

    should "succeed for standard params" do
      stub_create_ticket

      @client.create_ticket(
        'title',
        'description',
        format: 'text',
        ticket_type_name: 'bug',
        bin_name: /alpha/i
      )
    end

    should "succeed with defaulted params" do
      stub_create_ticket

      @client.create_ticket(
          'title',
          'description',
          bin_name: /alpha/i
      )
    end

    should "succeed with extra params" do
      stub_create_ticket_with_extras

      @client.create_ticket(
          'title',
          'description',
          bin_name: /alpha/i,
          'First seen': Date.new(2016,1,1),
          'Last seen': Date.new(2016,1,15)
      )
    end

  end

  context "updating tickets" do
    setup do
      stub_ticket_types
      stub_bins
      stub_next_ticket_id
      stub_custom_fields
      stub_create_ticket

      @client = Vimaly::Client.new('company_id', 'username', 'password')

      @client.create_ticket(
          'title',
          'description',
          format: 'text',
          ticket_type_name: 'bug',
          bin_name: /alpha/i
      )
    end

    should "succeed for standard params" do
      stub_update_ticket

      @client.update_ticket(
          123,
          title: 'updated title',
          description: 'updated description'
      )
    end

    should "succeed for custom params" do
      stub_update_ticket_custom

      @client.update_ticket(
          123,
          title: 'updated title',
          description: 'updated description',
          'Last seen': Date.new(2016,1,20)
      )
    end

  end

  context "finding a ticket type" do
    should "succeed" do
      stub_ticket_types

      client = Vimaly::Client.new('company_id', 'username', 'password')
      type = client.ticket_type('bug')
      assert_equal 'bug', type.name
      assert_equal 1, type.id
    end
  end

  context "loading ticket types" do
    should "succeed" do
      stub_ticket_types

      client = Vimaly::Client.new('company_id', 'username', 'password')
      types = client.ticket_types
      assert_equal 2, types.size
      assert_equal 'bug', types[0].name
      assert_equal 1, types[0].id
      assert_equal 'feature', types[1].name
      assert_equal 2, types[1].id
    end
  end

  context "finding a bin" do
    should "succeed" do
      stub_bins

      client = Vimaly::Client.new('company_id', 'username', 'password')
      type = client.bin('Alpha')
      assert_equal 'Alpha', type.name
      assert_equal 1, type.id
    end
  end

  context "loading bins" do
    should "succeed" do
      stub_bins

      client = Vimaly::Client.new('company_id', 'username', 'password')
      bins = client.bins

      assert_equal 2, bins.size
      assert_equal 'Alpha', bins[0].name
      assert_equal 1, bins[0].id
      assert_equal 'Beta', bins[1].name
      assert_equal 2, bins[1].id
    end
  end

  context 'load tickets from bin' do
    setup do
      stub_bins
      stub_ticket_types
      stub_tickets_in_bin
      stub_custom_fields

      @client = Vimaly::Client.new('company_id', 'username', 'password')
    end

    should 'succeed for all tickets' do
      all_tickets = @client.tickets_in_bin(1)

      assert_equal 2, all_tickets.size
      assert_equal 'Test ticket 1', all_tickets.first.title
      assert_equal 'This is a test', all_tickets.first.description
      assert_equal 'Alpha', all_tickets.first.bin.name
      assert_equal 'bug', all_tickets.first.ticket_type.name

      assert_equal 'Other test ticket 2', all_tickets.last.title
      assert_equal 'This is another test', all_tickets.last.description
      assert_equal 'Alpha', all_tickets.last.bin.name
      assert_equal 'bug', all_tickets.last.ticket_type.name
    end

    should 'succeed with matcher' do
      all_tickets = @client.matching_tickets_in_bin(1, /Other/)

      assert_equal 1, all_tickets.size
      assert_equal 'Other test ticket 2', all_tickets.last.title
      assert_equal 'This is another test', all_tickets.last.description
      assert_equal 'Alpha', all_tickets.last.bin.name
      assert_equal 'bug', all_tickets.last.ticket_type.name
    end

  end


end

require 'test_helper'

class ClientTest < Minitest::Test

  TEST_TICKETS = [
      { '_id' => '1',
        'name' => 'Test ticket 1',
        'description' => 'This is a test',
        'bin_id' => '1',
        'ticketType_id' => '1',
        'order' => 100},
      { '_id' => '2',
        'name' => 'Other test ticket 2',
        'description' => 'This is another test',
        'bin_id' => '1',
        'ticketType_id' => '1',
        'order' => 101}
  ]

  context "creating tickets" do
    setup do
      stub_ticket_types
      stub_bins
      stub_next_ticket_id
      stub_custom_fields

      @client = Vimaly::Client.new('company_id', user_credentials: { username: 'username', password: 'password' })
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

    should "handle bad gateway errors" do
      stub_ticket_types(status: 502)

      assert_raises Vimaly::ConnectionError do
        @client.create_ticket(
          'title',
          'description',
          format: 'text',
          ticket_type_name: 'bug',
          bin_name: /alpha/i
        )
      end
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
  end # creating tickets

  context "updating tickets" do
    setup do
      stub_ticket_types
      stub_bins
      stub_next_ticket_id
      stub_custom_fields
      stub_create_ticket

      @client = Vimaly::Client.new('company_id', user_credentials: { username: 'username', password: 'password' })

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

      id = @client.update_ticket(
        123,
        title: 'updated title',
        description: 'updated description'
      )
      assert_equal 123, id
    end

    should "succeed for custom params" do
      stub_update_ticket_custom

      id = @client.update_ticket(
        123,
        title: 'updated title',
        description: 'updated description',
        'Last seen': Date.new(2016,1,20)
      )
      assert_equal 123, id
    end
  end # updating tickets

  context "adding an attachment to a ticket" do
    setup do
      @client = Vimaly::Client.new('company_id', user_credentials: { username: 'username', password: 'password' })
    end

    should "succeed" do
      stub_add_attachment
      @client.add_attachment('ticket-id-13', 'filename.txt', 'some content in a text file', content_type: 'plain/text')
    end
  end # adding an attachment to a ticket

  context "finding a ticket type" do
    should "succeed" do
      stub_ticket_types

      client = Vimaly::Client.new('company_id', user_credentials: { username: 'username', password: 'password' })
      type = client.ticket_type('bug')
      assert_equal 'bug', type.name
      assert_equal 1, type.id
    end
  end

  context "loading ticket types" do
    should "succeed" do
      stub_ticket_types

      client = Vimaly::Client.new('company_id', user_credentials: { username: 'username', password: 'password' })
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

      client = Vimaly::Client.new('company_id', user_credentials: { username: 'username', password: 'password' })
      type = client.bin('Alpha')
      assert_equal 'Alpha', type.name
      assert_equal 1, type.id
    end
  end

  context "loading bins" do
    should "succeed" do
      stub_bins

      client = Vimaly::Client.new('company_id', user_credentials: { username: 'username', password: 'password' })
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

      @client = Vimaly::Client.new('company_id', user_credentials: { username: 'username', password: 'password' })
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

  private

  def stub_bins
    stub_request(:get, %r{#{Vimaly::Client::VIMALY_ROOT_URL}/rest/2/company_id/bins}).to_return(
      status: 200,
      body: [{name: 'Alpha', _id: 1}, {name: 'Beta', _id: 2}]
    )
  end

  def stub_ticket_types(overrides={})
    default_response = {
      status: 200,
      body: [{name: 'bug', _id: 1}, {name: 'feature', _id: 2}]
    }
    stub_request(:get, "#{Vimaly::Client::VIMALY_ROOT_URL}/rest/2/company_id/ticket-types").to_return(
      default_response.merge(overrides)
    )
  end

  def stub_custom_fields
    stub_request(:get, "#{Vimaly::Client::VIMALY_ROOT_URL}/rest/2/company_id/custom-fields").to_return(
        status: 200,
        body: [{name: 'First seen', _id: 1, type: 1}, {name: 'Last seen', _id: 2, type: 1}]
    )
  end

  def stub_next_ticket_id
    stub_request(:get, "#{Vimaly::Client::VIMALY_ROOT_URL}/rest/2/company_id/ids?amount=1").to_return(
      status: 200,
      body: [13]
    )
  end

  def stub_create_ticket
    request_body = "{\"name\":\"title\",\"description\":\"description\",\"rtformat\":\"text\",\"ticketType_id\":1,\"bin_id\":1}"
    stub_request(:post, "#{Vimaly::Client::VIMALY_ROOT_URL}/rest/2/company_id/tickets/13").
      with(body: request_body).
      to_return(status: 200, body: "")
  end

  def stub_add_attachment
    request_body = "some content in a text file"
    stub_request(:post, "#{Vimaly::Client::VIMALY_ROOT_URL}/rest/2/company_id/tickets/ticket-id-13/attachments?name=filename.txt").
      with(body: request_body, headers: { 'Content-Type' => 'plain/text' }).
      to_return(status: 200, body: "")
  end

  def stub_update_ticket
    request_body = "{\"name\":\"updated title\",\"description\":\"updated description\"}"
    stub_request(:put, "#{Vimaly::Client::VIMALY_ROOT_URL}/rest/2/company_id/tickets/123").
        with(body: request_body).
        to_return(status: 200, body: "")
  end

  def stub_update_ticket_custom
    request_body = "{\"name\":\"updated title\",\"description\":\"updated description\",\"customFields.2\":\"2016-01-20\"}"
    stub_request(:put, "#{Vimaly::Client::VIMALY_ROOT_URL}/rest/2/company_id/tickets/123").
        with(body: request_body).
        to_return(status: 200, body: "")
  end

  def stub_create_ticket_with_extras
    request_body = {'name':'title','description':'description','rtformat':'text','ticketType_id':1,'bin_id':1,
      'customFields': {'1': "2016-01-01",
                        '2': "2016-01-15"}}.to_json

    stub_request(:post, "#{Vimaly::Client::VIMALY_ROOT_URL}/rest/2/company_id/tickets/13").
        with(body: request_body).
        to_return(status: 200, body: "")
  end

  def stub_tickets_in_bin
    stub_request(:get, "#{Vimaly::Client::VIMALY_ROOT_URL}/rest/2/company_id/tickets?bin_id=1").
        to_return(status: 200, body: TEST_TICKETS.to_json)
  end

end

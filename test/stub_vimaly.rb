module StubVimaly

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

  def stub_bins
    stub_request(:get, "#{Vimaly::Client::VIMALY_ROOT_URL}/rest/1/company_id/bins").to_return(
        status: 200,
        body: [{name: 'Alpha', _id: 1}, {name: 'Beta', _id: 2}]
    )
  end

  def stub_ticket_types
    stub_request(:get, "#{Vimaly::Client::VIMALY_ROOT_URL}/rest/1/company_id/ticket-types").to_return(
        status: 200,
        body: [{name: 'bug', _id: 1}, {name: 'feature', _id: 2}]
    )
  end

  def stub_custom_fields
    stub_request(:get, "#{Vimaly::Client::VIMALY_ROOT_URL}/rest/1/company_id/custom-fields").to_return(
        status: 200,
        body: [{name: 'First seen', _id: 1, type: 1}, {name: 'Last seen', _id: 2, type: 1}]
    )
  end

  def stub_next_ticket_id
    stub_request(:get, "#{Vimaly::Client::VIMALY_ROOT_URL}/rest/1/company_id/ids?amount=1").to_return(
        status: 200,
        body: [13]
    )
  end

  def stub_create_ticket(title='title', description='description', custom_fields=nil)
    request_body = '{"name":"' + title + '","description":"' + description + '","rtformat":"text","ticketType_id":1,"bin_id":1'
    request_body << ',"customFields":' + custom_fields.to_json if custom_fields
    request_body << '}'

    stub_request(:post, "#{Vimaly::Client::VIMALY_ROOT_URL}/rest/1/company_id/tickets/13").
        with(body: request_body).
        to_return(status: 200, body: "")
  end

  def stub_update_ticket(id=123, body=nil)
    request_body = body&.to_json || "{\"name\":\"updated title\",\"description\":\"updated description\"}"
    stub_request(:put, "#{Vimaly::Client::VIMALY_ROOT_URL}/rest/1/company_id/tickets/#{id}").
        with(body: request_body).
        to_return(status: 200, body: "")
  end

  def stub_update_ticket_custom
    request_body = "{\"name\":\"updated title\",\"description\":\"updated description\",\"customFields.2\":\"2016-01-20\"}"
    stub_request(:put, "#{Vimaly::Client::VIMALY_ROOT_URL}/rest/1/company_id/tickets/123").
        with(body: request_body).
        to_return(status: 200, body: "")
  end

  def stub_create_ticket_with_extras
    request_body = {'name':'title','description':'description','rtformat':'text','ticketType_id':1,'bin_id':1,
                    'customFields': {'1': "2016-01-01",
                                     '2': "2016-01-15"}}.to_json

    stub_request(:post, "#{Vimaly::Client::VIMALY_ROOT_URL}/rest/1/company_id/tickets/13").
        with(body: request_body).
        to_return(status: 200, body: "")
  end

  def stub_tickets_in_bin(extra_tickets = [])
    stub_request(:get, "#{Vimaly::Client::VIMALY_ROOT_URL}/rest/1/company_id/tickets?bin_id=1").
        to_return(status: 200, body: (TEST_TICKETS + extra_tickets).to_json)
  end

end

require 'spec_helper'
require 'curlyrest'

describe Curlyrest do
  SIMPLE_URL = 'https://oauth.brightcove.com/v4/public_operations'.freeze
  it 'has a version number' do
    expect(Curlyrest::VERSION).not_to be nil
  end

  it 'handles a generic request' do
    expect do
      RestClient::Request.execute(method: :get,
                                  url: SIMPLE_URL)
    end.not_to raise_error
  end

  it 'correctly processes a curl request' do
    expect do
      RestClient::Request.execute(
        method: :get,
        url: SIMPLE_URL, headers: { use_curl: true }
      )
    end.not_to raise_error
  end

  it 'correctly processes error response' do
    response = 'HTTP/1.1 400 Bad Request
X-Powered-By: Express
Access-Control-Allow-Origin: *
Content-Type: application/json
Date: Thu, 06 Sep 2018 19:05:26 GMT
content-length: 388
l5d-success-class: 1.0
Via: 1.1 linkerd, 1.1 linkerd

yabba dabba doo
'
    parser = Curlyrest::CurlResponseParser.new(response)
    expect(parser.response.message).to eq('Bad Request')
  end

  it 'correctly processes http 2 response' do
    response = 'HTTP/2 200
X-Powered-By: Express
Access-Control-Allow-Origin: *
Content-Type: application/json
Date: Thu, 06 Sep 2018 19:05:26 GMT
content-length: 388
l5d-success-class: 1.0
Via: 1.1 linkerd, 1.1 linkerd

yabba dabba doo
'
    parser = Curlyrest::CurlResponseParser.new(response)
    expect(parser.response.message).to eq('')
  end

  it 'correctly appends headers' do
    response = 'HTTP/2 200
X-Powered-By: Express
Access-Control-Allow-Origin: *
Content-Type: application/json
Date: Thu, 06 Sep 2018 19:05:26 GMT
content-length: 388
l5d-success-class: 1.0
Via: 1.1 linkerd, 1.1 linkerd
Junk: Fred
Junk: Barney
Junk: Wilma

yabba dabba doo
'
    parser = Curlyrest::CurlResponseParser.new(response)
    expect(parser.response.to_hash['junk']).to eq(%w[Fred Barney Wilma])
  end

  it 'response from curl matches rest-client' do
    r1 = RestClient::Request.execute(
      method: :get,
      url: 'http://example.com', headers: { use_curl: false }
    )
    r2 = RestClient::Request.execute(
      method: :get,
      url: 'http://example.com', headers: { use_curl: true }
    )
    expect(r1).to eq(r2)
    r1.headers.reject! do |h|
      h['server'] || h['accept_ranges'] || h['date'] ||
        h['expires'] || h['etag']
    end
    r2.headers.reject! do |h|
      h['server'] || h['accept_ranges'] || h['date'] ||
        h['expires'] || h['etag']
    end
    expect(r1.headers).to eq(r2.headers)
  end

  it 'passes data on a POST with 100 continue', todos: true do
    expect do
      RestClient::Request.execute(
        method: :post,
        url: 'http://localhost:3000/todos',
        headers: { use_curl: true, no_restclient_headers: true },
        payload: { title: 'bar', created_by: 'kw',
                   junk: 'a' * 1500 }
      )
    end .not_to raise_error
  end

  it 'handles timeout option' do
    RestClient::Request.execute(timeout: 10,
                                method: :get,
                                url: 'http://example.com',
                                headers: { use_curl: true })
  end

  it 'handles data without single quotes' do
    ct = Curlyrest::CurlTransmitter.new(nil, '', {}, {})
    expect(ct.curl_data('stuff here')).to eq('-d \'stuff here\'')
  end

  it 'handles data with embedded single quotes' do
    ct = Curlyrest::CurlTransmitter.new(nil, '', {}, {})
    payload = "some json with 's"
    expect(ct.curl_data(payload))
      .to eq('--data-binary @/tmp/curl_quoted_binary')
  end
end

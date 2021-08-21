# frozen_string_literal: true

require 'spec_helper'
require 'curlyrest'

describe Curlyrest do
  include_context 'curlyrest shared'

  it 'has a version number' do
    expect(Curlyrest::VERSION).not_to be nil
  end

  it 'handles a non-curl request' do
    expect do
      RestClient::Request.execute(method: :get,
                                  url: simple_url)
    end.not_to raise_error
  end

  it 'handles a generic request w No-Restclient-Headers' do
    expect do
      RestClient::Request.execute(method: :get,
                                  url: simple_url,
                                  headers: { no_restclient_headers: true,
                                             use_curl: true })
    end.not_to raise_error
  end

  it 'correctly processes a curl request' do
    expect do
      RestClient::Request.execute(
        method: :get,
        url: simple_url, headers: { use_curl: true }
      )
    end.not_to raise_error
  end

  it 'correctly processes error response' do
    parser = Curlyrest::CurlResponseParser.new(error_response)
    expect(parser.response.message).to eq('Bad Request')
  end

  it 'correctly processes http 2 response' do
    parser = Curlyrest::CurlResponseParser.new(simple_response)
    expect(parser.response.message).to eq('')
  end

  it 'correctly appends headers' do
    parser = Curlyrest::CurlResponseParser.new(response_w_headers)
    expect(parser.response.to_hash['junk']).to eq(%w[Fred Barney Wilma])
  end

  it 'detects invalid line in response' do
    expect { Curlyrest::CurlResponseParser.new(invalid_response) }
      .to raise_error(RuntimeError,
                      "invalid line while parsing headers: nonsense\n")
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
      %i[server accept_ranges date expires etag age].include?(h)
    end
    r2.headers.reject! do |h|
      %i[server accept_ranges date expires etag age].include?(h)
    end
    expect(r1.headers.sort).to eq(r2.headers.sort)
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
    end.not_to raise_error
  end

  it 'handles timeout option' do
    RestClient::Request.execute(method: :get,
                                url: 'http://example.com',
                                headers: { timeout: 10,
                                           use_curl: true })
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

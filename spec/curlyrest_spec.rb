require 'spec_helper'

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
                   junk: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' }
      )
    end .not_to raise_error
  end
end

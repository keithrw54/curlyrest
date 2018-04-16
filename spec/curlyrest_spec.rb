require 'spec_helper'

describe Curlyrest do
  it 'has a version number' do
    expect(Curlyrest::VERSION).not_to be nil
  end

  it 'handles a generic request' do
    expect{r = RestClient::Request.execute(method: :get,
      url: 'http://example.com')
    }.not_to raise_error
  end

  it 'correctly processes a curl request' do
    expect{r = RestClient::Request.execute(method: :get,
      url: 'http://example.com', headers: {use_curl: true})
    }.not_to raise_error
  end

  it 'response from curl matches rest-client' do
    r1 = RestClient::Request.execute(method: :get,
      url: 'http://example.com', headers: {use_curl: false})
    r2 = RestClient::Request.execute(method: :get,
      url: 'http://example.com', headers: {use_curl: 'debug'})
    expect(r1).to eq(r2)
    r1.headers.reject!{|h|h['server']}
    r2.headers.reject!{|h|h['server']}
    expect(r1.headers).to eq(r2.headers)
  end
end

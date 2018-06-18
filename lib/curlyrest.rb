require "curlyrest/version"
require 'rest-client'
require 'byebug'

module Curlyrest
  class CurlResponse
    include Net::HTTPHeader
    attr_reader :code, :http_version, :message, :headers
    attr_accessor :body, :inflate
    def initialize(http_version, status, message)
      @message = message
      @http_version = http_version
      @code = status
      @body = ''
      @inflate = Zlib::Inflate.new(32 + Zlib::MAX_WBITS)
      initialize_http_header nil
    end
    def body=(value)
      @body = value
    end
    def unzip_body(gzip)
      @body = @inflate.inflate(gzip)
    end
  end

  def parse_response(r)
    t = :http_status
    n = nil
    body = ''
    lines = r.lines
    i = 0
    while (i < lines.length)
      case t
      when :http_status
        rem = /^HTTP\/(\d+\.\d+) (\d+) (.+)$/.match(lines[i])
        if rem[2] == '100'
          t = :wait_for_another_http
        else
          t = :headers
          n = CurlResponse.new(rem[1], rem[2], rem[3].chop)
        end
      when :wait_for_another_http
        t = :http_status if rem = /^HTTP\/(\d+\.\d+) (\d+) (.+)$/.match(lines[i+1])
      when :headers
        if /^[\r\n]+$/.match(lines[i])
          t = :body
        else
          rem = /^([\w-]+):\s(.*)/.match(lines[i].chop)
          n[rem[1]] = rem[2]
        end 
      when :body
        body << lines[i]
      end
      i += 1
    end
    if n.to_hash.keys && n.to_hash.keys.include?('content-encoding') &&
      n.to_hash['content-encoding'].include?('gzip')
        n.unzip_body(body)
    else
      n.body = (body)
    end
    n
  end

  def curl_data(payload)
    payload.to_s if payload
  end

  def curl_proxy(option)
    option ? " -x #{option}" : ''
  end
  
  def curl_headers(headers)
    ret_headers = ' '
    headers.each{|k,v| ret_headers << "-H '#{k}: #{v}' "}
    ret_headers
  end

  def transmit(uri, method, headers, payload, &block)
    curlyrest_option = headers.delete('Use-Curl') || headers.delete(:use_curl)
    proxy_option = headers.delete('Use-Proxy') || headers.delete(:use_proxy)
    headers.delete('No-Restclient-Headers') || headers.delete(:no_restclient_headers)
    curl_line = "curl -isS -X #{method.upcase}#{curl_proxy(proxy_option)}#{curl_headers(headers)}'#{uri}' -d '#{curl_data(payload)}'"
    puts curl_line if curlyrest_option == 'debug'
    r = `#{curl_line}`
    puts r if curlyrest_option == 'debug'
    parse_response(r)
  end
end

include Curlyrest

module RestClient
  class Request
    def execute & block
      # With 2.0.0+, net/http accepts URI objects in requests and handles wrapping
      # IPv6 addresses in [] for use in the Host request header.
      case processed_headers['Use-Curl']
      when 'debug', 'true'
        h = processed_headers['No-Restclient-Headers'] == 'true' ? headers : processed_headers
        r = Curlyrest.transmit(uri, method, h, payload, &block)
        RestClient::Response.create(r.body, r, self)
      else
        transmit uri, 
          net_http_request_class(method).new(uri, processed_headers),
            payload, & block
      end
    ensure
      payload.close if payload
    end
  end
end

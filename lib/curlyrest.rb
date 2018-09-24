require 'curlyrest/version'
require 'rest-client'
require 'byebug'

# module extending Rest-Client to optionally do via curl
module Curlyrest
  # class for a constructing a curl response
  class CurlResponse
    include Net::HTTPHeader
    attr_reader :code, :http_version, :message, :headers
    attr_accessor :body, :inflate
    def initialize(http_version, status, message = '')
      @message = message
      @http_version = http_version
      @code = status
      @body = ''
      @inflate = Zlib::Inflate.new(32 + Zlib::MAX_WBITS)
      initialize_http_header nil
    end

    def unzip_body(gzip)
      @body = @inflate.inflate(gzip)
    end
  end

  # class for parsing curl responses
  class CurlResponseParser
    attr_accessor :response
    def initialize(response)
      @state = :read_status
      @response = nil
      @body = ''
      parse(response)
    end

    def parse(response)
      response.lines.each do |line|
        parse_line(line)
      end
      ce = @response.to_hash.dig('content-encoding')
      if ce&.include?('gzip')
        @response.unzip_body(@body)
      else
        @response.body = @body
      end
    end

    def parse_status(line)
      re = %r{^HTTP\/(\d+|\d+\.\d+)\s(\d+)\s*(.*)$}
      return unless re.match(line.chop)
      r = Regexp.last_match(2)
      return if r && r == '100'
      @state = :headers
      @response = CurlResponse.new(Regexp.last_match(1),
                                   Regexp.last_match(2),
                                   Regexp.last_match(3))
    end

    def add_header(key, value)
      if @response.key?(key)
        if @response[key].class.name == 'Array'
          @response[key] << value
        else
          @response[key] = [@response[key], value]
        end
      else
        @response[key] = value
      end
    end

    def parse_headers(line)
      if /^\s*$/.match?(line)
        @state = :body
        return
      end
      /^([\w-]+):\s(.*)/ =~ line.chop
      add_header(Regexp.last_match(1), Regexp.last_match(2))
    end

    def parse_line(line)
      case @state
      when :body
        @body << line
      when :read_status
        parse_status(line)
      when :headers
        parse_headers(line)
      else
        puts "parser error on #{line}"
      end
    end
  end

  # class for transmitting curl requests
  class CurlTransmitter
    attr_accessor :options, :headers, :line, :timeout
    def initialize(uri, method, headers, payload)
      @payload = payload
      @method = method
      @uri = uri
      @headers, @options = calc_options(headers)
      @line = curl_command
    end

    def opts_from_headers(headers, options = {})
      [[:curl, 'Use-Curl', :use_curl],
       [:proxy, 'Use-Proxy', :use_proxy],
       [:timeout, 'Timeout', :timeout]].each do |a|
        options[a[0]] = headers.delete(a[1]) || headers.delete(a[2])
      end
      [headers, options]
    end

    def calc_options(headers)
      headers, options = opts_from_headers(headers)
      headers.delete('No-Restclient-Headers') ||
        headers.delete(:no_restclient_headers)
      headers.delete('Accept-Encoding') ||
        headers.delete('accept_encoding')
      [headers, options]
    end

    def curl_data(payload)
      payload&.to_s
    end

    def curl_proxy(option)
      option ? " -x #{option}" : ''
    end

    def curl_start
      timeout = options[:timeout]
      timeout_str = ''
      timeout_str << " --max-time #{timeout}" unless timeout.nil?
      "curl -isS -X #{@method.upcase}#{timeout_str}"
    end

    def curl_headers(headers)
      ret_headers = ' '
      headers.each { |k, v| ret_headers << "-H '#{k}: #{v}' " }
      ret_headers
    end

    def curl_command
      @line = "#{curl_start}#{curl_proxy(@options[:proxy])}"\
              "#{curl_headers(@headers)}'#{@uri}' -d '#{curl_data(@payload)}'"
    end

    def exec_curl
      debug = options[:curl] == 'debug' || ENV['FORCE_CURL_DEBUG']
      puts line if debug
      r = `#{line}`
      puts r if debug
      r
    end
  end

  def curl_transmit(uri, method, headers, payload)
    ct = CurlTransmitter.new(uri, method, headers, payload)
    r = ct.exec_curl
    CurlResponseParser.new(r).response
  end
end

# restclient monkeypatch
module RestClient
  # restClient request class
  class Request
    prepend Curlyrest
    def execute(& block)
      # With 2.0.0+, net/http accepts URI objects in requests and handles
      # wrapping IPv6 addresses in [] for use in the Host request header.
      if processed_headers['Use-Curl'] || ENV['FORCE_CURL_DEBUG']
        curl_execute(& block)
      else
        transmit(uri, net_http_request_class(method)
                        .new(uri, processed_headers),
                 payload, & block)
      end
    ensure
      payload&.close
    end

    def curl_execute(& block)
      h = if processed_headers['No-Restclient-Headers'] == true
            headers
          else
            processed_headers
          end
      r = curl_transmit(uri, method, h, payload, &block)
      RestClient::Response.create(r.body, r, self)
    end

    def process_cookie_args!(uri, headers, args)

      # Avoid ambiguity in whether options from headers or options from
      # Request#initialize should take precedence by raising ArgumentError when
      # both are present. Prior versions of rest-client claimed to give
      # precedence to init options, but actually gave precedence to headers.
      # Avoid that mess by erroring out instead.
      if headers[:cookies] && args[:cookies]
        raise ArgumentError.new(
          "Cannot pass :cookies in Request.new() and in headers hash")
      end

      cookies_data = headers.delete(:cookies) || args[:cookies]

      # this method has problems if no cookies are in the request
      return if cookies_data.nil?

      # return copy of cookie jar as is
      if cookies_data.is_a?(HTTP::CookieJar)
        return cookies_data.dup
      end

      # convert cookies hash into a CookieJar
      jar = HTTP::CookieJar.new

      (cookies_data || []).each do |key, val|

        # Support for Array<HTTP::Cookie> mode:
        # If key is a cookie object, add it to the jar directly and assert that
        # there is no separate val.
        if key.is_a?(HTTP::Cookie)
          if val
            raise ArgumentError.new("extra cookie val: #{val.inspect}")
          end

          jar.add(key)
          next
        end

        if key.is_a?(Symbol)
          key = key.to_s
        end

        # assume implicit domain from the request URI, and set for_domain to
        # permit subdomains
        jar.add(HTTP::Cookie.new(key, val, domain: uri.hostname.downcase,
                                 path: '/', for_domain: true))
      end

      jar
    end
  end
end

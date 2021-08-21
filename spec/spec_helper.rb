# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

require 'curlyrest'

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

RSpec.shared_context 'curlyrest shared', shared_context: :metadata do
  let(:simple_url) { 'https://oauth.brightcove.com/v4/public_operations' }
  let(:error_response) do
    '
HTTP/1.1 400 Bad Request
X-Powered-By: Express
Access-Control-Allow-Origin: *
Content-Type: application/json
Date: Thu, 06 Sep 2018 19:05:26 GMT
content-length: 388
l5d-success-class: 1.0
Via: 1.1 linkerd, 1.1 linkerd

yabba dabba doo
'
  end
  let(:simple_response) do
    '
HTTP/2 200
X-Powered-By: Express
Access-Control-Allow-Origin: *
Content-Type: application/json
Date: Thu, 06 Sep 2018 19:05:26 GMT
content-length: 388
l5d-success-class: 1.0
Via: 1.1 linkerd, 1.1 linkerd

yabba dabba doo
'
  end
  let(:response_w_headers) do
    '
HTTP/2 200
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
  end
  let(:invalid_response) do
    '
HTTP/2 200
nonsense
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
  end
end

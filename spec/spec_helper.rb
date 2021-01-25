# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

require 'curlyrest'

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

RSpec.shared_context 'curlyrest shared', shared_context: :metadata do
  let(:simple_url) { 'https://oauth.brightcove.com/v4/public_operations' }
end

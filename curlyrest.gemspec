lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'curlyrest/version'

Gem::Specification.new do |spec|
  spec.name          = 'curlyrest'
  spec.version       = Curlyrest::VERSION
  spec.authors       = ['Keith Williams']
  spec.email         = ['keithrw@comcast.net']

  spec.summary       =
    'gem extending rest-client, allowing use/debug of curl for request'
  spec.description   =
    'gem extending rest-client, allowing use/debug of curl for request'
  spec.homepage      = 'https://github.com/keithrw54/curlyrest.git'
  spec.license       = 'MIT'

  spec.files         =
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{^(test|spec|features)/})
    end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rest-client', '~> 2.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end

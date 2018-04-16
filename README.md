# Curlyrest

Welcome to curlyrest. In years of testing RESTful APIs, it was regularly beneficial to be able to substitute execution via curl for a request which normally would have been executed with RestClient. This might have been because observation of the exact request wasn't easy, or because RestClient had some unexplained restriction. Having a tool that could execute the request via curl and optionally expose the output, allowed observing the exact failing request. It was also possible to pass the curl request to a colleague without having them deal with environment, ruby, or data complications to be able to replicate a failure.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'curlyrest'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install curlyrest

## Usage

Simply replace your use of require 'rest-client' with require 'curlyrest', and optionally add header :params of :use_curl with true or 'debug' which will cause the request to be executed with curl and response parsed to be compatable with rest-client.

## Development

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Limitations

Curlyrest works with basic requests, including responses with content-encoding: 'gzip'. I would not be suprised to find some more complicated requests that are not supported at this time.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/keithrw54/curlyrest.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).


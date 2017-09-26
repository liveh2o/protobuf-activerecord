require "rubygems"
require "bundler"

require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
end

Bundler.require(:default, :development, :test)

require "support/db"
require "support/models"
require "support/protobuf/messages.pb"

# Silence protobuf"s logger
Protobuf::Logging.logger.level = ::Logger::FATAL

RSpec.configure do |config|
  # Turn deprecation warnings into errors with full backtrace.
  config.raise_errors_for_deprecations!

  # Verifies the existance of any stubbed methods, replaces better_receive and better_stub
  # https://www.relishapp.com/rspec/rspec-mocks/v/3-1/docs/verifying-doubles/partial-doubles
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end

# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
end

require "protobuf-activerecord"

require "active_support/testing/time_helpers"

require "support/db"
require "support/models"
require "support/protobuf/messages.pb"

# Silence protobuf"s logger
Protobuf::Logging.logger.level = ::Logger::FATAL

RSpec.configure do |config|
  config.include ActiveSupport::Testing::TimeHelpers

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Verify the existence of any stubbed methods
  config.mock_with :rspec do |c|
    c.verify_partial_doubles = true
  end

  # Turn deprecation warnings into errors with full backtrace.
  config.raise_errors_for_deprecations!
end

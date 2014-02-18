require 'active_record'
require 'active_support/concern'
require 'heredity'
require 'protobuf'

# To support Rails 4 apps that use Mass-Assignment Security, attempt to
# load the protected_attributes gem. If it's not present, move along...
begin
  require 'protected_attributes'
rescue LoadError
  # These aren't the droids you're looking for... move along.
end

require 'protobuf/active_record/config'
require 'protobuf/active_record/middleware/connection_management'
require 'protobuf/active_record/middleware/query_cache'
require 'protobuf/active_record/model'
require 'protobuf/active_record/version'

module Protobuf
  module ActiveRecord
    def self.config
      @config ||= Protobuf::ActiveRecord::Config.new
    end

    # Initialize the config
    config
  end
end

require 'protobuf/active_record/railtie' if defined?(Rails)

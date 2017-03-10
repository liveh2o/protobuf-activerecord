module Protobuf
  module ActiveRecord
    class Config < ActiveSupport::OrderedOptions
      def initialize(options = {})
        super

        self[:autoload] = true
        self[:connection_reaping_interval] = 6
        self[:connection_reaping_timeout_interval] = 5
      end
    end
  end
end

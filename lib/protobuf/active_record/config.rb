module Protobuf
  module ActiveRecord
    class Config < ActiveSupport::OrderedOptions
      def initialize(options = {})
        super

        self[:autoload] = true
        self[:async_execution_interval] = 6
        self[:async_timeout_interval] = 5
      end
    end
  end
end

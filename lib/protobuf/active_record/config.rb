module Protobuf
  module ActiveRecord
    class Config < ActiveSupport::OrderedOptions
      def initialize(options = {})
        super

        self[:autoload] = true
      end
    end
  end
end

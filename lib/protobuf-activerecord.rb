require 'active_record'
require 'active_support/concern'
require 'heredity'
require 'protobuf'

require 'protobuf/active_record/model'
require 'protobuf/active_record/version'

require 'protobuf/active_record/railtie' if defined?(Rails)

module Protobuf
  module ActiveRecord
    module LoadHooks
      def inherited(klass)
        super

        klass.class_eval do
          include Protobuf::ActiveRecord::Model
        end
      end
    end
  end
end

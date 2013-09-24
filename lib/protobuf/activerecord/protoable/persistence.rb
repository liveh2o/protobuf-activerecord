require 'active_support/concern'

module Protoable
  module Persistence
    extend ::ActiveSupport::Concern

    included do
      # Override Active Record's initialize method so it can accept a protobuf
      # message as it's attributes. Need to do it in included block since initialize
      # is defined in ActiveRecord::Base.
      # :noapi:
      def initialize(*args, &block)
        args[0] = attributes_from_proto(args.first) if args.first.is_a?(::Protobuf::Message)

        super(*args, &block)
      end
    end

    module ClassMethods
      # :nodoc:
      def create(attributes = {}, &block)
        attributes = attributes_from_proto(attributes) if attributes.is_a?(::Protobuf::Message)

        super(attributes, &block)
      end

      # :nodoc:
      def create!(attributes = {}, &block)
        attributes = attributes_from_proto(attributes) if attributes.is_a?(::Protobuf::Message)

        super(attributes, &block)
      end
    end

    # :nodoc:
    def assign_attributes(attributes)
      attributes = attributes_from_proto(attributes) if attributes.is_a?(::Protobuf::Message)

      super(attributes)
    end

    # :nodoc:
    def update_attributes(attributes)
      attributes = attributes_from_proto(attributes) if attributes.is_a?(::Protobuf::Message)

      super(attributes)
    end

    # :nodoc:
    def update_attributes!(attributes)
      attributes = attributes_from_proto(attributes) if attributes.is_a?(::Protobuf::Message)

      super(attributes)
    end
  end
end

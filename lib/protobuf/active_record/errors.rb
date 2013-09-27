module Protobuf
  module ActiveRecord
    # = Protobuf Active Record errors
    #
    # Generic Protobuf Active Record exception class
    class ProtobufActiveRecordError < StandardError
    end

    # Raised by `attribute_from_proto` when the transformer method
    # given is not callable.
    class AttributeTransformerError < ProtobufActiveRecordError
      def message
        "Attribute transformers must be called with a callable or block!"
      end
    end

    # Raised by `field_from_record` when the convert method
    # given not callable.
    class FieldTransformerError < ProtobufActiveRecordError
      def message
        "Field transformers must be called with a callable or block!"
      end
    end

    # Raised by `to_proto` when no protobuf message is defined.
    class MessageNotDefined < ProtobufActiveRecordError
      attr_reader :class_name

      def initialize(klass)
        @class_name = klass.name
      end

      def message
        "#{class_name} does not define a protobuf message"
      end
    end

    # Raised by `field_scope` when given scope is not defined.
    class SearchScopeError < ProtobufActiveRecordError
    end
  end
end

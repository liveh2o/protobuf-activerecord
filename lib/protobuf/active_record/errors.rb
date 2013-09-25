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
    end

    # Raised by `field_from_record` when the convert method
    # given not callable.
    class FieldTransformerError < ProtobufActiveRecordError
    end

    # Raised by `field_scope` when given scope is not defined.
    class SearchScopeError < ProtobufActiveRecordError
    end
  end
end

module Protoable

  # = Protoable errors
  #
  # Generic Protoable exception class
  class ProtoableError < StandardError
  end

  # Raised by Protoable.attribute_from_proto when the transformer method
  # given is not callable.
  class AttributeTransformerError < ProtoableError
  end

  # Raised by Protoable.field_from_record when the convert method
  # given not callable.
  class FieldTransformerError < ProtoableError
  end

  # Raised by Protoable.field_scope when given scope is not defined.
  class SearchScopeError < ProtoableError
  end
end

module Protoable

  # = Protoable errors
  #
  # Generic Protoable exception class
  class ProtoableError < StandardError
  end

  # Raised by Protoable.protoable_attribute when the convert method given is
  # not callable.
  class AttributeConverterError < ProtoableError
  end

  # Raised by Protoable.protobuf_column_transform when the transformer method
  # given is not defined, nil, or not callable.
  class ColumnTransformerError < ProtoableError
  end

  # Raised by Protoable.protobuf_field_convert when the convert method
  # given is not defined, nil, or not callable.
  class FieldConverterError < ProtoableError
  end
end

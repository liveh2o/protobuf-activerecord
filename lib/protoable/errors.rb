module Protoable

  # = Protoable errors
  #
  # Generic Protoable exception class
  class ProtoableError < StandardError
  end

  # Raised by Protoable.protobuf_column_convert when the convert method
  # given is not defined, nil, or not callable.
  class ColumnConverterError < ProtoableError
  end

  # Raised by Protoable.protobuf_column_transform when the transformer method
  # given is not defined, nil, or not callable.
  class ColumnTransformerError < ProtoableError
  end
end

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

  module Errors
    OK = 200
    BAD_REQUEST = 400
    NOT_FOUND = 404
    INTERNAL_SERVER_ERROR = 500

    def errors_for_protobuf
      return [] if !changed? || valid?

      errors.messages.map do |field, error_messages|
        {
          :field => field.to_s,
          :messages => error_messages.dup
        }
      end
    end

    def status_code_for_protobuf
      return !changed? || valid? ? OK : BAD_REQUEST
    end
  end
end

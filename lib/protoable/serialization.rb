module Protoable
  module Serialization
    def self.included(klass)
      klass.extend Protoable::Serialization::ClassMethods

      klass.class_eval do
        class << self
          attr_accessor :protobuf_fields, :_protobuf_field_converters
        end

        @_protobuf_field_converters = {}
      end
    end

    module ClassMethods
      # Define a field conversion from db to protobuf. Accepts a callable,
      # Symbol, or Hash.
      #
      # When given a callable, it is directly used to convert the field.
      #
      # When a Hash is given, :from and :to keys are expected and expand
      # to extracting a class method in the format of
      # "_convert_#{from}_to_#{to}".
      #
      # When a symbol is given, it extracts the method with the same name,
      # if any. When method is not available it is assumed as the "from"
      # data type, and the "to" value is extracted based on the
      # name of the column.
      #
      # Examples:
      #   proto_field_convert :created_at, :int64
      #   proto_field_convert :public_key, method(:extract_public_key_from_proto)
      #   proto_field_convert :public_key, :extract_public_key_from_proto
      #   proto_field_convert :status, lambda { |proto_field| ... }
      #   proto_field_convert :symmetric_key, :base64
      #   proto_field_convert :symmetric_key, :from => :base64, :to => :encoded_string
      #   proto_field_convert :symmetric_key, :from => :base64, :to => :raw_string
      #
      def proto_field_convert(field, callable = nil, &blk)
        callable ||= blk

        if callable.is_a?(Hash)
          callable = :"_convert_#{callable[:from]}_to_#{callable[:to]}"
        end

        if callable.is_a?(Symbol)
          unless self.respond_to?(callable)
            column = _protobuf_columns[field.to_sym]
            callable = :"_convert_#{callable}_to_#{column.try(:type)}"
          end
          callable = method(callable) if self.respond_to?(callable)
        end

        if callable.nil? || !callable.respond_to?(:call)
          raise FieldConverterError, 'Field converters must be a callable or block!'
        end

        _protobuf_field_converters[field.to_sym] = callable
      end

      def protobuf_message(message = nil)
        unless message.nil?
          klass = message.to_s.classify.constantize

          define_method(:to_proto) do
            klass.new(self.to_proto_hash)
          end

          define_method(:to_proto_hash) do
            protoable_attributes
          end

          self.protobuf_fields = klass.fields.values.map do |field|
            name = field.respond_to?(:setup) ? field.setup.name : field.name
            name.to_sym
          end

          @protobuf_message = klass
        end

        @protobuf_message
      end
    end

    def protoable_attributes
      protoable_attributes = protobuf_fields.inject({}) do |hash, field|
        value = respond_to?(field) ? __send__(field) : nil
        hash[field] = _protobuf_convert_columns(field, value)
        hash
      end

      protoable_attributes
    end

  private

    def protobuf_fields
      self.class.protobuf_fields || []
    end
  end
end

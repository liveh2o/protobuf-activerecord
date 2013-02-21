require 'heredity/inheritable_class_instance_variables'

module Protoable
  module Transformation
    def self.included(klass)
      klass.extend Protoable::Transformation::ClassMethods
      klass.__send__(:include, ::Heredity::InheritableClassInstanceVariables)

      klass.class_eval do
        class << self
          attr_accessor :_protobuf_attribute_transformers
        end

        @_protobuf_attribute_transformers = {}

        inheritable_attributes :_protobuf_attribute_transformers
      end
    end

    module ClassMethods
      # Filters accessible attributes that exist in the given protobuf message's
      # fields or have attribute transformers defined for them.
      #
      # Returns a hash of attribute fields with their respective values.
      #
      # :nodoc:
      def _filter_attribute_fields(proto)
        fields = proto.to_hash
        fields.select! { |key, value| proto.has_field?(key) && !proto.get_field_by_name(key).repeated? }

        attribute_fields = attribute_names.inject({}) do |hash, column_name|
          symbolized_column = column_name.to_sym

          if fields.has_key?(symbolized_column) ||
            _protobuf_attribute_transformers.has_key?(symbolized_column)
            hash[symbolized_column] = fields[symbolized_column]
          end

          hash
        end

        attribute_fields
      end

      # :nodoc:
      def _protobuf_convert_fields_to_columns(key, value)
        return value if value.nil?

        value = case
                when _protobuf_date_column?(key) then
                  convert_int64_to_date(value)
                when _protobuf_datetime_column?(key) then
                  convert_int64_to_datetime(value)
                when _protobuf_time_column?(key) then
                  convert_int64_to_time(value)
                when _protobuf_timestamp_column?(key) then
                  convert_int64_to_time(value)
                else
                  value
                end

        return value
      end

      # Define an attribute transformation from protobuf. Accepts a Symbol,
      # callable, or block.
      #
      # When given a callable or block, it is directly used to convert the field.
      #
      # When a symbol is given, it extracts the method with the same name.
      #
      # The callable or method must accept a single parameter, which is the
      # proto message.
      #
      # Examples:
      #   attribute_from_proto :public_key, :extract_public_key_from_proto
      #   attribute_from_proto :status, lambda { |proto| # Do some stuff... }
      #   attribute_from_proto :status do |proto|
      #     # Do some blocky stuff...
      #   end
      #
      def attribute_from_proto(attribute, transformer = nil, &block)
        transformer ||= block

        if transformer.is_a?(Symbol)
          callable = lambda { |value| self.__send__(transformer, value) }
        else
          callable = transformer
        end

        unless callable.respond_to?(:call)
          raise AttributeTransformerError, 'Attribute transformers need a callable or block!'
        end

        _protobuf_attribute_transformers[attribute.to_sym] = callable
      end


      # Creates a hash of attributes from a given protobuf message.
      #
      # It converts and transforms field values using the field converters and
      # attribute transformers, ignoring repeated and nil fields.
      #
      def attributes_from_proto(proto)
        attribute_fields = _filter_attribute_fields(proto)

        attributes = attribute_fields.inject({}) do |hash, (key, value)|
          if _protobuf_attribute_transformers.has_key?(key)
            attribute = _protobuf_attribute_transformers[key].call(proto)
            hash[key] = attribute unless attribute.nil?
          else
            hash[key] = _protobuf_convert_fields_to_columns(key, value)
          end

          hash
        end

        attributes
      end

      # :nodoc:
      def convert_int64_to_time(int64)
        Time.at(int64.to_i)
      end

      # :nodoc:
      def convert_int64_to_date(int64)
        convert_int64_to_time(int64).utc.to_date
      end

      # :nodoc:
      def convert_int64_to_datetime(int64)
        convert_int64_to_time(int64).to_datetime
      end
    end

    # Calls up to the class version of the method.
    #
    def attributes_from_proto(proto)
      self.class.attributes_from_proto(proto)
    end
  end
end

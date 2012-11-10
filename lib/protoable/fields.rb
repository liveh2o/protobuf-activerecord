require 'heredity/inheritable_class_instance_variables'

module Protoable
  module Fields
    def self.extended(klass)
      klass.extend Protoable::Fields::ClassMethods
      klass.__send__(:include, ::Heredity::InheritableClassInstanceVariables)

      klass.class_eval do
        class << self
          attr_accessor :_protobuf_columns, :_protobuf_column_types,
            :_protobuf_attribute_transformers, :_protobuf_field_converters
        end

        @_protobuf_attribute_transformers = {}
        @_protobuf_columns = {}
        @_protobuf_column_types = Hash.new { |h,k| h[k] = [] }
        @_protobuf_field_converters = {}

        # NOTE: Make sure each inherited object has the database layout
        inheritable_attributes :_protobuf_attribute_transformers, :_protobuf_columns,
          :_protobuf_column_types, :_protobuf_field_converters
      end

      _protobuf_map_columns(klass)
    end

    # Map out the columns for future reference on type conversion
    #
    def self._protobuf_map_columns(klass)
      return unless klass.table_exists?
      klass.columns.map do |column|
        klass._protobuf_columns[column.name.to_sym] = column
        klass._protobuf_column_types[column.type.to_sym] << column.name.to_sym
      end
    end

    module ClassMethods
      # Define a field conversion from protobuf to db. Accepts a Symbol,
      # Hash, callable or block.
      #
      # When given a callable or block, it is directly used to convert the field.
      #
      # When a Hash is given, :from and :to keys are expected and expand
      # to extracting a class method in the format of
      # "convert_#{from}_to_#{to}".
      #
      # When a symbol is given, it extracts the method with the same name.
      #
      # Examples:
      #   convert_field :public_key, :extract_public_key_from_proto
      #   convert_field :symmetric_key, :from => :base64, :to => :encoded_string
      #   convert_field :status, lambda { |proto_field| # Do some stuff... }
      #   convert_field :status do |proto_field|
      #     # Do some blocky stuff...
      #   end
      #
      def convert_field(field, converter = nil, &blk)
        converter ||= blk
        converter = :"convert_#{converter[:from]}_to_#{converter[:to]}" if converter.is_a?(Hash)

        if converter.is_a?(Symbol)
          callable = lambda { |value| self.__send__(converter, value) }
        else
          callable = converter
        end

        unless callable.respond_to?(:call)
          raise FieldConverterError, 'Field converters must be a callable or block!'
        end

        _protobuf_field_converters[field.to_sym] = callable
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
      #   attribute_from_proto :status, lambda { |proto_field| # Do some stuff... }
      #   attribute_from_proto :status do |proto_field|
      #     # Do some blocky stuff...
      #   end
      #
      def attribute_from_proto(field, transformer = nil, &blk)
        transformer ||= blk

        if transformer.is_a?(Symbol)
          callable = lambda { |value| self.__send__(transformer, value) }
        else
          callable = transformer
        end

        unless callable.respond_to?(:call)
          raise AttributeTransformerError, 'Attribute transformers need a callable or block!'
        end

        _protobuf_attribute_transformers[field.to_sym] = callable
      end

      def transform_column(field, transformer = nil, &blk)
        warn "[DEPRECATION] `transform_column` is deprecated and will be removed in v1.2.  Please use `attribute_from_proto` instead."
        attribute_from_proto(field, transformer, &blk)
      end
    end
  end
end

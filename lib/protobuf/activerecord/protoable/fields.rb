require 'heredity/inheritable_class_instance_variables'

module Protoable
  module Fields
    def self.extended(klass)
      klass.extend Protoable::Fields::ClassMethods
      klass.__send__(:include, ::Heredity::InheritableClassInstanceVariables)

      klass.class_eval do
        class << self
          attr_accessor :_protobuf_attribute_transformers, :_protobuf_columns,
            :_protobuf_column_types

        end

        @_protobuf_attribute_transformers = {}
        @_protobuf_columns = {}
        @_protobuf_column_types = Hash.new { |h,k| h[k] = [] }

        # NOTE: Make sure each inherited object has the database layout
        inheritable_attributes :_protobuf_attribute_transformers, :_protobuf_columns,
          :_protobuf_column_types
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
    end
  end
end

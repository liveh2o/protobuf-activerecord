require 'protoable/inheritable_class_instance_variables'

module Protoable
  module Fields
    def self.extended(klass)
      klass.extend Protoable::Fields::ClassMethods
      klass.__send__(:include, Protoable::InheritableClassInstanceVariables)

      klass.class_eval do
        class << self
          attr_accessor :_protobuf_columns, :_protobuf_column_types,
            :_protobuf_column_transformers, :_protobuf_field_converters

          alias_method :convert_field_to_column, :convert_field
          alias_method :transform_column_from_proto, :transform_column
        end

        @_protobuf_columns = {}
        @_protobuf_column_types = Hash.new { |h,k| h[k] = [] }
        @_protobuf_column_transformers = {}
        @_protobuf_field_converters = {}

        # NOTE: Make sure each inherited object has the database layout
        inheritable_attributes :_protobuf_columns, :_protobuf_column_types,
          :_protobuf_field_converters, :_protobuf_column_transformers
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
      # Define a field conversion from protobuf to db. Accepts a callable,
      # Symbol, or Hash.
      #
      # When given a callable, it is directly used to convert the field.
      #
      # When a Hash is given, :from and :to keys are expected and expand
      # to extracting a class method in the format of
      # "convert_#{from}_to_#{to}".
      #
      # When a symbol is given, it extracts the method with the same name,
      # if any. When method is not available it is assumed as the "from"
      # data type, and the "to" value is extracted based on the
      # name of the column.
      #
      # Examples:
      #   convert_field :created_at, :int64
      #   convert_field :public_key, :extract_public_key_from_proto
      #   convert_field :status, lambda { |proto_field| ... }
      #   convert_field :symmetric_key, :from => :base64, :to => :encoded_string
      #
      def convert_field(field, transformer = nil, &blk)
        transformer ||= blk
        transformer = :"convert_#{transformer[:from]}_to_#{transformer[:to]}" if transformer.is_a?(Hash)

        if transformer.is_a?(Symbol)
          unless self.respond_to?(transformer, true)
          column = _protobuf_columns[field.to_sym]
            transformer = :"convert_#{transformer}_to_#{column.try(:type)}"
          end

          callable = lambda { |value| self.__send__(transformer, value) }
        else
          callable = transformer
        end

        unless callable.respond_to?(:call)
          raise FieldConverterError, 'Field converters must be a callable or block!'
        end

        _protobuf_field_converters[field.to_sym] = callable
      end

      # Define a column transformation from protobuf to db. Accepts a callable,
      # or Symbol.
      #
      # When given a callable, it is directly used to convert the field.
      #
      # When a symbol is given, it extracts the method with the same name.
      #
      # The callable or method must accept a single parameter, which is the
      # proto message.
      #
      # Examples:
      #   transform_column :public_key, :extract_public_key_from_proto
      #   transform_column :status, lambda { |proto_field| ... }
      #
      def transform_column(field, transformer = nil, &blk)
        transformer ||= blk

        if transformer.is_a?(Symbol)
          callable = lambda { |value| self.__send__(transformer, value) }
        else
          callable = transformer
        end

        unless callable.respond_to?(:call)
          raise ColumnTransformerError, 'Protoable casting needs a callable or block!'
        end

        _protobuf_column_transformers[field.to_sym] = callable
      end
    end
  end
end

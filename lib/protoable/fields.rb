require 'protoable/convert'
require 'protoable/inheritable_class_instance_variables'

module Protoable
  module Fields
    def self.extended(klass)
      klass.extend Protoable::Fields::ClassMethods
      klass.__send__(:include, Protoable::Convert)
      klass.__send__(:include, Protoable::InheritableClassInstanceVariables)

      klass.class_eval do
        class << self
          attr_accessor :_protobuf_columns, :_protobuf_column_types, :_protobuf_column_converters
        end

        @_protobuf_columns = {}
        @_protobuf_column_types = Hash.new { |h,k| h[k] = [] }
        @_protobuf_column_converters = {}

        # NOTE: Make sure each inherited object has the database layout
        inheritable_attributes :_protobuf_columns, :_protobuf_column_types, :_protobuf_column_converters
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
      # Define a column conversion from protobuf to db. Accepts a callable,
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
      #   proto_column_convert :created_at, :int64
      #   proto_column_convert :public_key, method(:extract_public_key_from_proto)
      #   proto_column_convert :public_key, :extract_public_key_from_proto
      #   proto_column_convert :status, lambda { |proto_field| ... }
      #   proto_column_convert :symmetric_key, :base64
      #   proto_column_convert :symmetric_key, :from => :base64, :to => :encoded_string
      #   proto_column_convert :symmetric_key, :from => :base64, :to => :raw_string
      #
      def self.proto_column_convert(field, callable = nil, &blk)
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

        raise 'Protobuf activerecord casting needs a callable or block!' if callable.nil?
        raise 'Protobuf activerecord casting callable must respond to :call!' if !callable.respond_to?(:call)

        _protobuf_column_converters[field.to_sym] = callable
      end
    end
  end
end

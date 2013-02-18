require 'heredity/inheritable_class_instance_variables'

module Protoable
  module Columns
    def self.included(klass)
      klass.extend Protoable::Columns::ClassMethods
      klass.__send__(:include, ::Heredity::InheritableClassInstanceVariables)

      klass.class_eval do
        class << self
          attr_accessor :_protobuf_columns, :_protobuf_column_types
        end

        @_protobuf_columns = {}
        @_protobuf_column_types = Hash.new { |h,k| h[k] = [] }

        # NOTE: Make sure each inherited object has the database layout
        inheritable_attributes :_protobuf_columns, :_protobuf_column_types
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
      # :nodoc:
      def _protobuf_date_column?(key)
        _protobuf_column_types.fetch(:date, false) && _protobuf_column_types[:date].include?(key)
      end

      # :nodoc:
      def _protobuf_datetime_column?(key)
        _protobuf_column_types.fetch(:datetime, false) && _protobuf_column_types[:datetime].include?(key)
      end

      # :nodoc:
      def _protobuf_time_column?(key)
        _protobuf_column_types.fetch(:time, false) && _protobuf_column_types[:time].include?(key)
      end

      # :nodoc:
      def _protobuf_timestamp_column?(key)
        _protobuf_column_types.fetch(:timestamp, false) && _protobuf_column_types[:timestamp].include?(key)
      end
    end
  end
end

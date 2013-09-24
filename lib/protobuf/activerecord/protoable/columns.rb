require 'active_support/concern'

module Protoable
  module Columns
    extend ::ActiveSupport::Concern

    included do
      include ::Heredity

      attr_accessor :_protobuf_columns,
                    :_protobuf_column_types,
                    :_protobuf_mapped_columns

      inheritable_attributes :_protobuf_columns,
                             :_protobuf_column_types,
                             :_protobuf_mapped_columns
    end

    module ClassMethods
      def _protobuf_columns
        _protobuf_map_columns unless _protobuf_mapped_columns?

        @_protobuf_columns
      end

      def _protobuf_column_types
        _protobuf_map_columns unless _protobuf_mapped_columns?

        @_protobuf_column_types
      end

      # :nodoc:
      def _protobuf_date_column?(key)
        _protobuf_column_types.fetch(:date, false) && _protobuf_column_types[:date].include?(key)
      end

      # :nodoc:
      def _protobuf_datetime_column?(key)
        _protobuf_column_types.fetch(:datetime, false) && _protobuf_column_types[:datetime].include?(key)
      end

      # Map out the columns for future reference on type conversion
      # :nodoc:
      def _protobuf_map_columns
        return unless table_exists?

        protobuf_columns = {}
        protobuf_column_types = Hash.new { |h,k| h[k] = [] }

        columns.map do |column|
          protobuf_columns[column.name.to_sym] = column
          protobuf_column_types[column.type.to_sym] << column.name.to_sym
        end

        self._protobuf_columns = protobuf_columns
        self._protobuf_column_types = protobuf_column_types

        self._protobuf_mapped_columns = true
      end

      def _protobuf_mapped_columns?
        _protobuf_mapped_columns
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

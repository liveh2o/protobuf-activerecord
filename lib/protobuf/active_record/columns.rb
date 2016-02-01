require 'set'
require 'active_support/concern'
require 'thread'

module Protobuf
  module ActiveRecord
    module Columns
      extend ::ActiveSupport::Concern

      COLUMN_TYPE_MAP_MUTEX = ::Mutex.new
      DATE_OR_TIME_TYPES = ::Set.new([:date, :datetime, :time, :timestamp])

      included do
        include ::Heredity

        inheritable_attributes :_protobuf_columns,
                               :_protobuf_column_types,
                               :_protobuf_date_datetime_time_or_timestamp_column,
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

        def _protobuf_date_datetime_time_or_timestamp_column
          _protobuf_map_columns unless _protobuf_mapped_columns?

          @_protobuf_date_datetime_time_or_timestamp_column
        end

        # :nodoc:
        def _protobuf_date_column?(key)
          _protobuf_column_types[:date].include?(key)
        end

        # :nodoc:
        def _protobuf_date_datetime_time_or_timestamp_column?(key)
          _protobuf_date_datetime_time_or_timestamp_column.include?(key)
        end

        # :nodoc:
        def _protobuf_datetime_column?(key)
          _protobuf_column_types[:datetime].include?(key)
        end

        # Map out the columns for future reference on type conversion
        # :nodoc:
        def _protobuf_map_columns(force = false)
          COLUMN_TYPE_MAP_MUTEX.synchronize do
            @_protobuf_mapped_columns = false if force

            return unless table_exists?
            return if _protobuf_mapped_columns?

            @_protobuf_columns = {}
            @_protobuf_column_types = ::Hash.new { |h,k| h[k] = ::Set.new }
            @_protobuf_date_datetime_time_or_timestamp_column = ::Set.new

            columns.map do |column|
              column_name_symbol = column.name.to_sym
              column_type_symbol = column.type.to_sym
              @_protobuf_columns[column_name_symbol] = column
              @_protobuf_column_types[column_type_symbol] << column_name_symbol

              if DATE_OR_TIME_TYPES.include?(column_type_symbol)
                @_protobuf_date_datetime_time_or_timestamp_column << column_name_symbol
              end
            end

            @_protobuf_mapped_columns = true
          end
        end

        def _protobuf_mapped_columns?
          @_protobuf_mapped_columns
        end

        # :nodoc:
        def _protobuf_time_column?(key)
          _protobuf_column_types[:time].include?(key)
        end

        # :nodoc:
        def _protobuf_timestamp_column?(key)
          _protobuf_column_types[:timestamp].include?(key)
        end
      end
    end
  end
end

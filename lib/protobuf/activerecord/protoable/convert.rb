module Protoable
  module Convert
    def self.included(klass)
      klass.extend Protoable::Convert::ClassMethods
    end

    module ClassMethods
      def convert_int64_to_time(int64)
        Time.at(int64.to_i)
      end

      def convert_int64_to_date(int64)
        convert_int64_to_time(int64).utc.to_date
      end

      def convert_int64_to_datetime(int64)
        convert_int64_to_time(int64).to_datetime
      end

      def _protobuf_convert_attributes_to_fields(key, value)
        return value if value.nil?

        value = case
                when _protobuf_date_column?(key) then
                  value.to_time.to_i
                when _protobuf_datetime_column?(key) then
                  value.to_i
                when _protobuf_time_column?(key) then
                  value.to_i
                when _protobuf_timestamp_column?(key) then
                  value.to_i
                else
                  value
                end

        return value
      end

      def _protobuf_convert_fields_to_columns(key, value)
        return value if value.nil?

        value = case
                when _protobuf_field_converters.has_key?(key.to_sym) then
                  _protobuf_field_converters[key.to_sym].call(value)
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

      def _protobuf_date_column?(key)
        _protobuf_column_types.fetch(:date, false) && _protobuf_column_types[:date].include?(key)
      end

      def _protobuf_datetime_column?(key)
        _protobuf_column_types.fetch(:datetime, false) && _protobuf_column_types[:datetime].include?(key)
      end

      def _protobuf_time_column?(key)
        _protobuf_column_types.fetch(:time, false) && _protobuf_column_types[:time].include?(key)
      end

      def _protobuf_timestamp_column?(key)
        _protobuf_column_types.fetch(:timestamp, false) && _protobuf_column_types[:timestamp].include?(key)
      end
    end
  end
end

require 'base64'

module Protoable
  module Convert
    def self.included(klass)
      klass.extend Protoable::Convert::ClassMethods
    end

    module ClassMethods
      def _convert_int64_to_datetime(protobuf_value)
        return protobuf_value.respond_to?(:to_i) ? Time.at(protobuf_value.to_i) : protobuf_value
      end

      def _convert_datetime_to_int64(value)
        return value.respond_to?(:to_i) ? value.to_i : value
      end

      def _protobuf_date_column?(key)
        _protobuf_column_types[:date] && _protobuf_column_types[:date].include?(key)
      end

      def _protobuf_datetime_column?(key)
        _protobuf_column_types[:datetime] && _protobuf_column_types[:datetime].include?(key)
      end
      
      def _protobuf_convert_columns(key, value)
        value = case
                when _protobuf_datetime_column?(key) then
                  _convert_datetime_to_int64(value)
                when _protobuf_timestamp_column?(key) then
                  _convert_datetime_to_int64(value)
                when _protobuf_time_column?(key) then
                  _convert_datetime_to_int64(value)
                when _protobuf_date_column?(key) then
                  _convert_datetime_to_int64(value)
                when _protobuf_field_converters.has_key?(key.to_sym) then
                  _protobuf_field_converters[key.to_sym].call(value)
                else
                  value
                end

        return value
      end

      def _protobuf_convert_fields(key, value)
        value = case
                when _protobuf_datetime_column?(key) then
                  _convert_int64_to_datetime(value)
                when _protobuf_timestamp_column?(key) then
                  _convert_int64_to_datetime(value)
                when _protobuf_time_column?(key) then
                  _convert_int64_to_datetime(value)
                when _protobuf_date_column?(key) then
                  _convert_int64_to_datetime(value)
                when _protobuf_column_converters.has_key?(key.to_sym) then
                  _protobuf_column_converters[key.to_sym].call(value)
                else
                  value
                end

        return value
      end

      def _protobuf_timestamp_column?(key)
        _protobuf_column_types[:timestamp] && _protobuf_column_types[:timestamp].include?(key)
      end

      def _protobuf_time_column?(key)
        _protobuf_column_types[:time] && _protobuf_column_types[:time].include?(key)
      end
    end
  end
end

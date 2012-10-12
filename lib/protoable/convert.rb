require 'base64'

module Protoable
  module Convert
    def self.included(klass)
      klass.extend Protoable::Convert::ClassMethods
    end

    module ClassMethods
      def _base64_to_bytes(encoded)
        Base64.strict_decode64(encoded)
      end

      def _bytes_to_base64(bytes)
        Base64.strict_encode64(bytes)
      end

      def _convert_base64_to_encoded_string(field)
        if field.key?(:encoded)
          field[:encoded]
        elsif field.key?(:raw)
          _bytes_to_base64(field[:raw])
        end
      end
      alias_method :convert_base64_to_string, :_convert_base64_to_encoded_string

      def _convert_base64_to_raw_string(field)
        if field.key?(:raw)
          field[:raw]
        elsif field.key?(:encoded)
          _base64_to_bytes(field[:encoded])
        end
      end

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
      
      def _protobuf_filter_and_convert_columns(key, value)
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

      def _protobuf_filter_and_convert_fields(key, value)
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

    def base64_encoded_value_for_protobuf(attr_key)
      value = read_attribute(attr_key)
      if value.present?
        return {
          :encoded => value,
          :raw => self.class._base64_to_bytes(value)
        }
      end
    end
  end
end

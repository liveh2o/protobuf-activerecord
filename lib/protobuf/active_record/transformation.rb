require "active_support/concern"
require "heredity/inheritable_class_instance_variables"
require "protobuf/active_record/transformer"

module Protobuf
  module ActiveRecord
    module Transformation
      extend ::ActiveSupport::Concern

      included do
        include ::Heredity::InheritableClassInstanceVariables

        class << self
          attr_accessor :_protobuf_attribute_transformers
        end

        @_protobuf_attribute_transformers = {}

        inheritable_attributes :_protobuf_attribute_transformers
      end

      module ClassMethods
        # Filters accessible attributes that exist in the given protobuf message's
        # fields or have attribute transformers defined for them.
        #
        # Returns a hash of attribute fields with their respective values.
        #
        # :nodoc:
        def _filter_attribute_fields(proto)
          fields = proto.to_hash
          fields.select! do |key, _value|
            field = proto.class.get_field(key, true)
            proto.field?(key) && !field.repeated?
          end

          filtered_attributes = _filtered_attributes + _protobuf_attribute_transformers.keys

          attribute_fields = filtered_attributes.each_with_object({}) do |column_name, hash|
            symbolized_column = column_name.to_sym

            if fields.key?(symbolized_column) || _protobuf_attribute_transformers.key?(symbolized_column)
              hash[symbolized_column] = fields[symbolized_column]
            end
          end

          _protobuf_nested_attributes.each do |attribute_name|
            nested_attribute_name = :"#{attribute_name}_attributes"
            value = if proto.field?(nested_attribute_name)
              proto.__send__(nested_attribute_name)
            elsif proto.field?(attribute_name)
              proto.__send__(attribute_name)
            end

            next unless value
            attribute_fields[nested_attribute_name] = value
          end

          attribute_fields
        end

        # Overidden by mass assignment security when protected attributes is loaded.
        #
        # :nodoc:
        def _filtered_attributes
          attribute_names
        end

        # :nodoc:
        def _protobuf_convert_fields_to_attributes(key, value)
          return nil if value.nil?
          return value unless _protobuf_date_datetime_time_or_timestamp_column?(key)

          if _protobuf_datetime_column?(key)

            convert_int64_to_datetime(value)
          elsif _protobuf_timestamp_column?(key)

            convert_int64_to_time(value)
          elsif _protobuf_time_column?(key)

            convert_int64_to_time(value)
          elsif _protobuf_date_column?(key)

            convert_int64_to_date(value)
          end
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
        #   attribute_from_proto :status, lambda { |proto| # Do some stuff... }
        #   attribute_from_proto :status do |proto|
        #     # Do some blocky stuff...
        #   end
        #
        #   attribute_from_proto :status, lambda { |proto| nil }, :nullify_on => :status
        #   attribute_from_proto :status, :nullify_on => :status do |proto|
        #     nil
        #   end
        #
        def attribute_from_proto(attribute, *args, &block)
          options = args.extract_options!
          symbol_or_block = args.first || block

          if symbol_or_block.is_a?(Symbol)
            callable = lambda { |value| __send__(symbol_or_block, value) }
          else
            raise AttributeTransformerError unless symbol_or_block.respond_to?(:call)
            callable = symbol_or_block
          end

          if options[:nullify_on]
            field = protobuf_message.get_field(:nullify)
            unless field&.is_a?(::Protobuf::Field::StringField) && field&.repeated?
              ::Protobuf::Logging.logger.warn "Message: #{protobuf_message} is not compatible with :nullify_on option"
            end
          end

          transformer = ::Protobuf::ActiveRecord::Transformer.new(callable, options)
          _protobuf_attribute_transformers[attribute.to_sym] = transformer
        end

        # Creates a hash of attributes from a given protobuf message.
        #
        # It converts and transforms field values using the field converters and
        # attribute transformers, ignoring repeated and nil fields.
        #
        def attributes_from_proto(proto)
          attribute_fields = _filter_attribute_fields(proto)

          attributes = attribute_fields.each_with_object({}) do |(key, value), hash|
            if _protobuf_attribute_transformers.key?(key)
              transformer = _protobuf_attribute_transformers[key]
              attribute = transformer.call(proto)
              hash[key] = attribute unless attribute.nil?
              hash[key] = nil if transformer.nullify?(proto)
            else
              hash[key] = _protobuf_convert_fields_to_attributes(key, value)
            end
          end

          return attributes unless proto.field?(:nullify) && proto.nullify.is_a?(Array)

          proto.nullify.each do |attribute_name|
            attributes[attribute_name.to_sym] = nil if attribute_names.include?(attribute_name.to_s)
          end

          attributes
        end

        # :nodoc:
        def convert_int64_to_time(int64)
          Time.at(int64.to_i)
        end

        # :nodoc:
        def convert_int64_to_date(int64)
          convert_int64_to_time(int64).utc.to_date
        end

        # :nodoc:
        def convert_int64_to_datetime(int64)
          convert_int64_to_time(int64).to_datetime
        end
      end

      # Calls up to the class version of the method.
      #
      def attributes_from_proto(proto)
        self.class.attributes_from_proto(proto)
      end
    end
  end
end

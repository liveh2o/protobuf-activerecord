module Protoable
  module Persistence
    def self.included(klass)
      klass.extend Protoable::Persistence::ClassMethods

      klass.class_eval do
        class << self
          alias_method :create_hash, :attributes_from_proto
          alias_method :protobuf_create_hash, :attributes_from_proto
        end
      end
    end

    module ClassMethods
      # Filters accessible attributes that exist in the given protobuf message's
      # fields or have column transformers defined for them.
      #
      # Returns a hash of attribute fields with their respective values.
      #
      def _filter_attribute_fields(proto)
        fields = proto.to_hash
        fields.select! { |key, value| proto.has_field?(key) && !proto.get_field(key).repeated? }

        attribute_fields = accessible_attributes.inject({}) do |hash, column_name|
          symbolized_column = column_name.to_sym

          if fields.include?(symbolized_column) ||
            _protobuf_column_transformers.has_key?(symbolized_column)
            hash[symbolized_column] = fields[symbolized_column]
          end

          hash
        end

        attribute_fields
      end

      # Creates a hash of attributes from a given protobuf message.
      #
      # It converts and transforms field values using the column converters and
      # column transformers, ignoring repeated and nil fields.
      #
      def attributes_from_proto(proto)
        attribute_fields = _filter_attribute_fields(proto)

        attributes = attribute_fields.inject({}) do |hash, (key, value)|
          if _protobuf_column_transformers.has_key?(key)
            hash[key] = _protobuf_column_transformers[key].call(proto)
          else
            hash[key] = _protobuf_convert_fields(key, value)
          end

          hash
        end

        attributes
      end

      # Creates an object from the given protobuf message, if it's valid. The
      # newly created object is returned if it was successfully saved or not.
      #
      def create_from_proto(proto)
        attributes = attributes_from_proto(proto)

        yield(attributes) if block_given?

        record = self.new(attributes)

        record.save! if record.valid?
        return record
      end
    end

    # Calls up to the class version of the method.
    #
    def attributes_from_proto(proto)
      self.class.attributes_from_proto(proto)
    end
    alias_method :update_hash, :attributes_from_proto
    alias_method :protobuf_update_hash, :attributes_from_proto

    # Destroys the record. Mainly wrapped to provide a consistent API and
    # a convient way to override protobuf-specific destroy behavior.
    #
    def destroy_from_proto
      destroy
    end

    # Update a record from a proto message. Accepts an optional block.
    # If block is given, yields the attributes that would be updated.
    #
    def update_from_proto(proto)
      attributes = attributes_from_proto(proto)

      yield(attributes) if block_given?

      assign_attributes(attributes)
      return valid? ? save! : false
    end
  end
end

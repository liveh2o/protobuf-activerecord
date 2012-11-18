module Protoable
  module Persistence
    def self.included(klass)
      klass.extend Protoable::Persistence::ClassMethods

      klass.class_eval do
        # Override Active Record's initialize method so it can accept a protobuf
        # message as it's attributes. Need to do it in class_eval block since initialize
        # is defined in ActiveRecord::Base.
        # :noapi:
        def initialize(*args)
          args.first = attributes_from_proto(args.first) if args.first.is_a?(::Protobuf::Message)

          super(*args)
        end
      end
    end

    module ClassMethods
      # Filters accessible attributes that exist in the given protobuf message's
      # fields or have attribute transformers defined for them.
      #
      # Returns a hash of attribute fields with their respective values.
      #
      def _filter_attribute_fields(proto)
        fields = proto.to_hash
        fields.select! { |key, value| proto.has_field?(key) && !proto.get_field_by_name(key).repeated? }

        attributes = self.new.attributes.keys - protected_attributes.to_a

        attribute_fields = attributes.inject({}) do |hash, column_name|
          symbolized_column = column_name.to_sym

          if fields.has_key?(symbolized_column) ||
            _protobuf_attribute_transformers.has_key?(symbolized_column)
            hash[symbolized_column] = fields[symbolized_column]
          end

          hash
        end

        attribute_fields
      end

      # Creates a hash of attributes from a given protobuf message.
      #
      # It converts and transforms field values using the field converters and
      # attribute transformers, ignoring repeated and nil fields.
      #
      def attributes_from_proto(proto)
        attribute_fields = _filter_attribute_fields(proto)

        attributes = attribute_fields.inject({}) do |hash, (key, value)|
          if _protobuf_attribute_transformers.has_key?(key)
            hash[key] = _protobuf_attribute_transformers[key].call(proto)
          else
            hash[key] = _protobuf_convert_fields_to_columns(key, value)
          end

          hash
        end

        attributes
      end

      # :nodoc:
      def create(attributes, options = {}, &block)
        attributes = attributes_from_proto(attributes) if attributes.is_a?(::Protobuf::Message)

        super(attributes, options)
      end

      # :nodoc:
      def create!(attributes, options = {}, &block)
        attributes = attributes_from_proto(attributes) if attributes.is_a?(::Protobuf::Message)

        super(attributes, options)
      end

      # Creates an object from the given protobuf message, if it's valid. The
      # newly created object is returned if it was successfully saved or not.
      #
      def create_from_proto(proto, options = {})
        attributes = attributes_from_proto(proto)

        yield(attributes) if block_given?

        self.create(attributes, options)
      end
    end

    # :nodoc:
    def assign_attributes(attributes, options = {})
      attributes = attributes_from_proto(proto) if attributes.is_a?(::Protobuf::Message)

      super(attributes, options)
    end

    # Calls up to the class version of the method.
    #
    def attributes_from_proto(proto)
      self.class.attributes_from_proto(proto)
    end

    # Destroys the record. Mainly wrapped to provide a consistent API and
    # a convient way to override protobuf-specific destroy behavior.
    #
    def destroy_from_proto
      destroy
    end

    # :nodoc:
    def update_attributes(attributes, options = {})
      attributes = attributes_from_proto(attributes) if attributes.is_a?(::Protobuf::Message)

      super(attributes, options)
    end

    # :nodoc:
    def update_attributes!(attributes, options = {})
      attributes = attributes_from_proto(attributes) if attributes.is_a?(::Protobuf::Message)

      super(attributes, options)
    end

    # Update a record from a proto message. Accepts an optional block.
    # If block is given, yields the attributes that would be updated.
    #
    def update_from_proto(proto, options = {})
      attributes = attributes_from_proto(proto)

      yield(attributes) if block_given?

      update_attributes(attributes, options)
    end
  end
end

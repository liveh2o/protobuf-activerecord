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
          args[0] = attributes_from_proto(args.first) if args.first.is_a?(::Protobuf::Message)

          super(*args)
        end
      end
    end

    module ClassMethods
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

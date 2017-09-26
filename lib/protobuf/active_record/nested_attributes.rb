module Protobuf
  module ActiveRecord
    module NestedAttributes
      extend ::ActiveSupport::Concern

      included do
        include ::Heredity::InheritableClassInstanceVariables

        class << self
          attr_accessor :_protobuf_nested_attributes
        end

        @_protobuf_nested_attributes = []

        inheritable_attributes :_protobuf_nested_attributes
      end

      module ClassMethods
        # :nodoc:
        def accepts_nested_attributes_for(*attr_names)
          attribute_names = attr_names.dup
          attribute_names.extract_options!
          attribute_names.map!(&:to_s)

          super

          self._protobuf_nested_attributes += attribute_names
        end
      end

      # :nodoc:
      def assign_nested_attributes_for_collection_association(association_name, attributes_collection)
        if attributes_collection.first.is_a?(::Protobuf::Message)
          reflection = self.class._reflect_on_association(association_name)
          attributes_collection = attributes_collection.map do |attributes|
            reflection.klass.attributes_from_proto(attributes)
          end
        end

        super(association_name, attributes_collection)
      end

      # :nodoc:
      def assign_nested_attributes_for_one_to_one_association(association_name, attributes)
        if attributes.is_a?(::Protobuf::Message)
          reflection = self.class._reflect_on_association(association_name)
          attributes = reflection.klass.attributes_from_proto(attributes)
        end

        super(association_name, attributes)
      end
    end
  end
end

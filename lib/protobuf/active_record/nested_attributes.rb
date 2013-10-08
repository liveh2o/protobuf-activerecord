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
        # :nodoc
        def accepts_nested_attributes_for(*attr_names)
          attribute_names = attr_names.dup
          attribute_names.extract_options!

          super

          self._protobuf_nested_attributes += attribute_names.map { |name| "#{name}_attributes" }
        end
      end
    end
  end
end

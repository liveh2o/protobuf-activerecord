require "active_support/concern"

module Protobuf
  module ActiveRecord
    module Validations
      extend ::ActiveSupport::Concern

      module ClassMethods
        # Validates whether the value of the specified attribute is available in
        # the given Protobuf Enum. The enumeration should be passed as a class
        # that defines the enumeration:
        #
        # ```
        # class User < ActiveRecord::Base
        #   include ::Protoable
        #
        #   validates_enumeration_of :role_type, :with => RoleType, :allow_nil => true
        # end
        # ```
        #
        # In this example, RoleType is a defined as a protobuf enum.
        #
        # It accepts the same options as `validates_inclusion_of` (the :in option
        # is automatically set and will be overwritten).
        #
        def validates_enumeration_of(*args)
          options = args.extract_options!
          enumerable = options.delete(:with)

          raise ArgumentError, ":with must be specified" if enumerable.nil?

          if enumerable < ::Protobuf::Enum
            options[:in] = enumerable.all_tags
          end

          args << options

          validates_inclusion_of(*args)
        end
      end
    end
  end
end

require "active_support/concern"

module Protobuf
  module ActiveRecord
    module MassAssignmentSecurity
      module Transformation
        extend ::ActiveSupport::Concern

        module ClassMethods
          # Filters protected attributes from the available attributes list. When
          # set through accessible attributes, returns the accessible attributes.
          # When set through protected attributes, returns the attributes minus any
          # protected attributes.
          #
          # :nodoc:
          def _filtered_attributes
            if accessible_attributes.present?
              accessible_attributes.to_a
            else
              self.attribute_names - protected_attributes.to_a
            end
          end
        end
      end
    end
  end
end

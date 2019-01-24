require "protobuf/active_record/attribute_methods"
require "protobuf/active_record/columns"
require "protobuf/active_record/errors"
require "protobuf/active_record/mass_assignment_security"
require "protobuf/active_record/nested_attributes"
require "protobuf/active_record/persistence"
require "protobuf/active_record/scope"
require "protobuf/active_record/serialization"
require "protobuf/active_record/transformation"
require "protobuf/active_record/validations"

module Protobuf
  module ActiveRecord
    module Model
      extend ::ActiveSupport::Concern

      included do
        include Protobuf::ActiveRecord::AttributeMethods
        include Protobuf::ActiveRecord::Columns
        include Protobuf::ActiveRecord::NestedAttributes
        include Protobuf::ActiveRecord::Serialization
        include Protobuf::ActiveRecord::Scope
        include Protobuf::ActiveRecord::Transformation
        include Protobuf::ActiveRecord::Validations

        if defined?(::ActiveModel::MassAssignmentSecurity)
          include Protobuf::ActiveRecord::MassAssignmentSecurity
        else
          include Protobuf::ActiveRecord::Persistence
        end
      end
    end
  end
end

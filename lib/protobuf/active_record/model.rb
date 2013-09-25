require 'protobuf/active_record/columns'
require 'protobuf/active_record/errors'
require 'protobuf/active_record/mass_assignment_security'
require 'protobuf/active_record/persistence'
require 'protobuf/active_record/scope'
require 'protobuf/active_record/serialization'
require 'protobuf/active_record/transformation'
require 'protobuf/active_record/validations'

module Protobuf
  module ActiveRecord
    module Model
      extend ::ActiveSupport::Concern

      included do
        include Protobuf::ActiveRecord::Columns
        include Protobuf::ActiveRecord::Serialization
        include Protobuf::ActiveRecord::Persistence
        include Protobuf::ActiveRecord::Scope
        include Protobuf::ActiveRecord::Transformation
        include Protobuf::ActiveRecord::Validations

        if defined?(::ActiveRecord::MassAssignmentSecurity)
          include Protobuf::ActiveRecord::MassAssignmentSecurity
        end
      end
    end
  end
end

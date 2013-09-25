require 'active_support/concern'
require 'protobuf/active_record/mass_assignment_security/persistence'
require 'protobuf/active_record/mass_assignment_security/transformation'

module Protobuf
  module ActiveRecord
    module MassAssignmentSecurity
      extend ::ActiveSupport::Concern

      included do
        include Protobuf::ActiveRecord::MassAssignmentSecurity::Persistence
        include Protobuf::ActiveRecord::MassAssignmentSecurity::Transformation
      end
    end
  end
end

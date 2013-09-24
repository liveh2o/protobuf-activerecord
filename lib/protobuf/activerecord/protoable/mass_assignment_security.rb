require 'active_support/concern'
require 'protobuf/activerecord/protoable/mass_assignment_security/persistence'
require 'protobuf/activerecord/protoable/mass_assignment_security/transformation'

module Protoable
  module MassAssignmentSecurity
    extend ::ActiveSupport::Concern

    included do
      include Protoable::MassAssignmentSecurity::Persistence
      include Protoable::MassAssignmentSecurity::Transformation
    end
  end
end

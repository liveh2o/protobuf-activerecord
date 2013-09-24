require 'protobuf/activerecord/protoable/columns'
require 'protobuf/activerecord/protoable/errors'
require 'protobuf/activerecord/protoable/mass_assignment_security'
require 'protobuf/activerecord/protoable/persistence'
require 'protobuf/activerecord/protoable/scope'
require 'protobuf/activerecord/protoable/serialization'
require 'protobuf/activerecord/protoable/transformation'
require 'protobuf/activerecord/protoable/validations'

module Protoable
  extend ::ActiveSupport::Concern

  included do
    extend Protoable::Scope

    include Protoable::Columns
    include Protoable::Serialization
    include Protoable::Persistence
    include Protoable::Transformation
    include Protoable::Validations

    if defined?(ActiveRecord::MassAssignmentSecurity)
      include Protoable::MassAssignmentSecurity
    end
  end
end

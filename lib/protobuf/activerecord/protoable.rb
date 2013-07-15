require 'protobuf/activerecord/protoable/columns'
require 'protobuf/activerecord/protoable/errors'
require 'protobuf/activerecord/protoable/persistence'
require 'protobuf/activerecord/protoable/scope'
require 'protobuf/activerecord/protoable/serialization'
require 'protobuf/activerecord/protoable/transformation'
require 'protobuf/activerecord/protoable/validations'

module Protoable
  def self.included(klass)
    klass.extend Protoable::Scope

    klass.__send__(:include, Protoable::Columns)
    klass.__send__(:include, Protoable::Persistence)
    klass.__send__(:include, Protoable::Serialization)
    klass.__send__(:include, Protoable::Transformation)
    klass.__send__(:include, Protoable::Validations)
  end
end

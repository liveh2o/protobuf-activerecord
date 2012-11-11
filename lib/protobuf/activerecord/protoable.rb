require 'protobuf/activerecord/protoable/convert'
require 'protobuf/activerecord/protoable/errors'
require 'protobuf/activerecord/protoable/fields'
require 'protobuf/activerecord/protoable/persistence'
require 'protobuf/activerecord/protoable/scope'
require 'protobuf/activerecord/protoable/serialization'

module Protoable
  def self.included(klass)
    klass.extend Protoable::Fields
    klass.extend Protoable::Scope

    klass.__send__(:include, Protoable::Convert)
    klass.__send__(:include, Protoable::Persistence)
    klass.__send__(:include, Protoable::Serialization)
  end
end

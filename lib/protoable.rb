require 'protoable/convert'
require 'protoable/errors'
require 'protoable/fields'
require 'protoable/persistence'
require 'protoable/scope'
require 'protoable/serialization'

module Protoable
  def self.included(klass)
    klass.extend Protoable::Fields
    klass.extend Protoable::Scope

    klass.__send__(:include, Protoable::Convert)
    klass.__send__(:include, Protoable::Persistence)
    klass.__send__(:include, Protoable::Serialization)
  end
end

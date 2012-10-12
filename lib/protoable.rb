require 'protoable/errors'
require 'protoable/fields'
require 'protoable/persistence'
require 'protoable/processor'
require 'protoable/scope'
require 'protoable/serialization'

module Protoable
  def self.included(klass)
    klass.extend Protoable::ClassMethods
    klass.extend Protoable::Fields

    klass.__send__(:include, Protoable::Errors)
    klass.__send__(:include, Protoable::Persistence)
    klass.__send__(:include, Protoable::Processor)
    klass.__send__(:include, Protoable::Scope)
    klass.__send__(:include, Protoable::Serialization)
  end

  module ClassMethods
    def _protobuf_base_model
      self
    end
  end

  def _protobuf_base_model
    self.class._protobuf_base_model
  end
end

require 'active_record'
require 'active_support/concern'
require 'heredity'
require 'protobuf'

require 'protobuf/activerecord/protoable'
require 'protobuf/activerecord/version'

require 'protobuf/activerecord/railtie' if defined?(Rails)

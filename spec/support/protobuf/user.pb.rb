require 'protobuf/message'

module Proto
  class User < ::Protobuf::Message
    optional ::Protobuf::Field::StringField, :name, 1
    optional ::Protobuf::Field::StringField, :email, 2
    repeated ::Protobuf::Field::StringField, :tags, 3
  end
end

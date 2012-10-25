require 'protobuf/message'

module Proto
  class User < ::Protobuf::Message
    optional ::Protobuf::Field::StringField, :name, 1
    optional ::Protobuf::Field::StringField, :email, 2
    optional ::Protobuf::Field::BytesField, :public_key, 3
    optional ::Protobuf::Field::Int64Field, :birthday, 4
    optional ::Protobuf::Field::Int64Field, :notify_me_at, 5
  end
end

##
# This file is auto-generated. DO NOT EDIT!
#
require 'protobuf/message'


##
# Message Classes
#
class UserMessage < ::Protobuf::Message; end
class UserSearchMessage < ::Protobuf::Message; end


##
# Message Fields
#
class UserMessage
  optional ::Protobuf::Field::StringField, :guid, 1
  optional ::Protobuf::Field::StringField, :name, 2
  optional ::Protobuf::Field::StringField, :email, 3
  optional ::Protobuf::Field::StringField, :email_domain, 4, :deprecated => true
  optional ::Protobuf::Field::StringField, :password, 5
end

class UserSearchMessage
  repeated ::Protobuf::Field::StringField, :guid, 1
  repeated ::Protobuf::Field::StringField, :email, 2
end


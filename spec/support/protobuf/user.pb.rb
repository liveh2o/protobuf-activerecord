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
  optional :string, :guid, 1
  optional :string, :name, 2
  optional :string, :email, 3
  optional :string, :email_domain, 4, :deprecated => true
  optional :string, :password, 5
end

class UserSearchMessage
  repeated :string, :guid, 1
  repeated :string, :email, 2
end


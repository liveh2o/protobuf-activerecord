##
# This file is auto-generated. DO NOT EDIT!
#
require "protobuf"

##
# Message Classes
#
class PhotoMessage < ::Protobuf::Message; end

class UserMessage < ::Protobuf::Message; end

class UserSearchMessage < ::Protobuf::Message; end

##
# Message Fields
#
class PhotoMessage
  optional :string, :url, 1
  optional :int64, :user_guid, 2
end

class UserMessage
  optional :string, :guid, 1
  optional :string, :name, 2
  optional :string, :email, 3
  optional :string, :email_domain, 4, deprecated: true
  optional :string, :password, 5
  repeated :string, :nullify, 6
  repeated ::PhotoMessage, :photos, 7
  optional :int64, :created_at, 8
  optional :int64, :updated_at, 9
end

class UserSearchMessage
  repeated :string, :guid, 1
  repeated :string, :email, 2
end

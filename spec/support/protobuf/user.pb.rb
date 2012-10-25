require 'protobuf/message/message'
require 'protobuf/message/enum'
require 'protobuf/message/extend'

module Proto
  class User < ::Protobuf::Message
    optional :string, :name, 1
    optional :string, :email, 2
    optional :base64, :public_key, 3
    optional :int64, :birthday, 4
    optional :int64, :notify_me_at, 5
  end
end

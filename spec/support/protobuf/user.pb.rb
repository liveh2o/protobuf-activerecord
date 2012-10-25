require 'protobuf/message/message'
require 'protobuf/message/enum'
require 'protobuf/message/extend'

module Proto
  class User < ::Protobuf::Message
    optional :string, :name, 1
    optional :int64, :birthday, 2
    optional :int64, :notify_me_at, 3
  end
end

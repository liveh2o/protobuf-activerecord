module Protobuf
  module ActiveRecord
    class Railtie < Rails::Railtie
      config.protobuf_activerecord = Protobuf::ActiveRecord.config

      ActiveSupport.on_load(:active_record) do
        extend Protobuf::ActiveRecord::LoadHooks if Protobuf::ActiveRecord.config.autoload
      end
    end
  end
end

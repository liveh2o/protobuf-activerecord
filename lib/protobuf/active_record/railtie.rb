module Protobuf
  module ActiveRecord
    class Railtie < Rails::Railtie
      config.protobuf_active_record = Protobuf::ActiveRecord.config

      ActiveSupport.on_load(:active_record) do
        extend Protobuf::ActiveRecord::LoadHooks if Protobuf::ActiveRecord.config.autoload
      end
    end
  end
end

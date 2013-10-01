module Protobuf
  module ActiveRecord
    class Railtie < Rails::Railtie
      config.protobuf_active_record = Protobuf::ActiveRecord.config

      ActiveSupport.on_load(:active_record) do
        if Protobuf::ActiveRecord.config.autoload
          on_inherit do
            include Protobuf::ActiveRecord::Model
          end
        end
      end
    end
  end
end

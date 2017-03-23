module Protobuf
  module ActiveRecord
    class Railtie < Rails::Railtie
      config.protobuf_active_record = Protobuf::ActiveRecord.config

      ActiveSupport.on_load(:active_record) do
        on_inherit do
          include Protobuf::ActiveRecord::Model if Protobuf::ActiveRecord.config.autoload
        end
      end

      ActiveSupport.on_load(:protobuf_rpc_service) do
        Protobuf::Rpc.middleware.insert_after Protobuf::Rpc::Middleware::Logger, Middleware::ConnectionManagement
        Protobuf::Rpc.middleware.insert_after Middleware::ConnectionManagementAsync, Middleware::QueryCache
      end
    end
  end
end

module Buttress
  class Railtie < ::Rails::Railtie
    ::ActiveSupport.on_load(:active_record) do
      extend ::Protobuf::ActiveRecord::ActiveRecordLoadHooks
    end
  end
end

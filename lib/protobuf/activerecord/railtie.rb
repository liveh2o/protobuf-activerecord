module Buttress
  class Railtie < ::Rails::Railtie
    ::ActiveSupport.on_load(:active_record) do
      extend ::Protoable::ActiveRecordLoadHooks
    end
  end
end

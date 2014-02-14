module Protobuf
  module ActiveRecord
    module Middleware
      module ConnectionManagement
        def initialize(app)
          @app = app
        end

        def call(env)
          env = @app.call(env)
          ActiveRecord::Base.clear_active_connections!

          env
        rescue
          ActiveRecord::Base.clear_active_connections!
          raise
        end
      end
    end
  end
end

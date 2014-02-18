module Protobuf
  module ActiveRecord
    module Middleware
      class QueryCache
        def initialize(app)
          @app = app
        end

        def call(env)
          enabled = ActiveRecord::Base.connection.query_cache_enabled
          connection_id = ActiveRecord::Base.connection_id
          ActiveRecord::Base.connection.enable_query_cache!

          @app.call(env)
        ensure
          restore_query_cache_settings(connection_id, enabled)
        end

      private

        def restore_query_cache_settings(connection_id, enabled)
          ActiveRecord::Base.connection_id = connection_id
          ActiveRecord::Base.connection.clear_query_cache
          ActiveRecord::Base.connection.disable_query_cache! unless enabled
        end
      end
    end
  end
end

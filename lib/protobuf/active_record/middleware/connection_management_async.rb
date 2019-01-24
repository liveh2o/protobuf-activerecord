require "concurrent"
require "thread"

module Protobuf
  module ActiveRecord
    module Middleware
      class ConnectionManagementAsync
        START_MUTEX = ::Mutex.new

        def self.start_timed_task!
          if timed_task_started.false?
            START_MUTEX.synchronize do
              return if timed_task_started.true?

              args = {
                :execution_interval => ::Protobuf::ActiveRecord.config.connection_reaping_interval,
                :timeout_interval => ::Protobuf::ActiveRecord.config.connection_reaping_timeout_interval
              }
              timed_task = ::Concurrent::TimerTask.new(args) do
                ::ActiveRecord::Base.clear_active_connections!
              end

              timed_task.execute
              timed_task_started.make_true
            end
          end
        end

        def self.timed_task_started
          if @timed_task_started.nil?
            @timed_task_started = ::Concurrent::AtomicBoolean.new(false)
          end

          @timed_task_started
        end

        def initialize(app)
          @app = app
        end

        # rubocop:disable Lint/DuplicateMethods
        # rubocop:disable Lint/NestedMethodDefinition
        def call(env)
          def call(env)
            ::ActiveRecord::Base.connection_pool.with_connection do
              @app.call(env)
            end
          end

          self.class.start_timed_task!
          call(env)
        end
        # rubocop:enable Lint/NestedMethodDefinition
        # rubocop:enable Lint/DuplicateMethods

        timed_task_started
      end
    end
  end
end

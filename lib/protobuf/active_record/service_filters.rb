module Protobuf
  module ActiveRecord
    module ServiceFilters
      extend ::ActiveSupport::Concern

      included do
        around_filter :_protobuf_active_record_with_connection
      end

      def _protobuf_active_record_with_connection
        ::ActiveRecord::Base.connection_pool.with_connection do
          yield
        end
      end
    end
  end
end

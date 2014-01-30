module Protobuf
  module ActiveRecord
    module ServiceFilters
      extend ::ActiveSupport::Concern

      included do
        after_filter :_protobuf_active_record_clear_active_connections
      end

      def _protobuf_active_record_clear_active_connections
        ::ActiveRecord::Base.clear_active_connections!
      end
    end
  end
end

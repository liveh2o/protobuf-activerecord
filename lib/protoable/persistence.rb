require 'protoable/convert'
require 'protoable/processor'

module Protoable
  module Persistence
    def self.included(klass)
      klass.extend Protoable::Persistence::ClassMethods
      klass.__send__ :include, Protoable::Convert
      klass.__send__ :include, Protoable::Processor
    end

    module ClassMethods
      def create_all_from_protos(*protos)
        protos.flatten!

        process_protos(protos) do |proto|
          _protobuf_base_model.create_from_proto(proto)
        end
      end

      def create_from_proto(proto)
        create_attributes = protobuf_create_hash(proto)
        yield(create_attributes) if block_given?
        record = _protobuf_base_model.new(create_attributes)

        record.save! if record.valid?
        return record
      end

      def delete_all_from_protos(*protos)
        protos.flatten!

        find_and_process_protos(protos) do |record, proto|
          record.delete_from_proto
        end
      end

      def destroy_all_from_protos(*protos)
        protos.flatten!

        find_and_process_protos(protos) do |record, proto|
          record.destroy_from_proto
        end
      end

      def update_all_from_protos(*protos)
        protos.flatten!

        find_and_process_protos(protos) do |record, proto|
          record.update_from_proto(proto)
        end
      end
    end

    def attributes_hash(protobuf_object)
      updateable_hash = protobuf_object.to_hash.dup

      updateable_hash.select! do |key, value|
        respond_to_and_has?(protobuf_object, key) && !protobuf_object.get_field(key).repeated?
      end

      updateable_hash.select! do |key, value|
        _protobuf_base_model.column_names.include?(key.to_s)
      end

      updateable_hash.dup.each do |key, value|
        updateable_hash[key] = _protobuf_base_model._protobuf_filter_and_convert_fields(key, value)
      end

      return updateable_hash
    end

    # Attempt to soft-delete the record by setting is_deleted/deleted_at
    # or status. If none of those fields exist, destroy the record.
    def delete_from_proto
      if respond_to?("is_deleted=")
        attrs = { :is_deleted => true }
        attrs[:deleted_at] = Time.now.utc if respond_to?("deleted_at=")
        update_attributes(attrs)
      elsif respond_to?("status=")
        # TODO remove the status check once statuses are gone-zo.
        #  and make brandon do it.
        update_attribute(:status, ::Atlas::StatusType::DELETED.value)
      else
        destroy_from_proto
      end
    end

    def destroy_from_proto
      destroy
    end

    def update_from_proto(proto)
      updated_attributes = attributes_hash(proto)
      yield(updated_attributes) if block_given?

      assign_attributes(updated_attributes)
      return valid? ? save! : false
    end

    ##
    # Instance Aliases
    #
    alias_method :create_hash, :attributes_hash
    alias_method :update_hash, :attributes_hash
    alias_method :protobuf_create_hash, :update_hash
    alias_method :protobuf_update_hash, :update_hash
  end
end
module Protoable
  module Persistence
    def self.included(klass)
      klass.extend Protoable::Persistence::ClassMethods
    end

    module ClassMethods
      def create_from_proto(proto)
        create_attributes = protobuf_create_hash(proto)
        yield(create_attributes) if block_given?
        record = _protobuf_base_model.new(create_attributes)

        record.save! if record.valid?
        return record
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
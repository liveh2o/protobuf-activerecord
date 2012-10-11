module Protoable
  module Processor
    def self.included(klass)
      klass.extend Protoable::Processor::ClassMethods
    end

    module ClassMethods
      def find_and_process_protos(*protos)
        protos = protos.flatten.compact.uniq
        hashed_records = _protobuf_base_model.records_hashed_by_guid_from_protos(protos)

        process_protos(protos) do |proto|
          if record = hashed_records[proto.guid]
            yield(record, proto)
          else
            # TODO: make this optional/check responds_to?...
            proto.status_code = 404
          end

          record || proto # can't use an explicit return in a block
        end
      end

      # TODO: Docs!
      def guid_scope(value = nil)
        @guid_scope = value if value
        @guid_scope ||= :by_guid
        return @guid_scope
      end

      def process_protos(protos)
        protos = protos.flatten.compact.uniq
        processed_protos = []

        protos.each do |proto|
          begin
            new_record_hash = proto.to_hash
            record_or_proto = yield(proto)
            record_hash = record_or_proto_to_hash(record_or_proto)
            new_record_hash.merge!(record_hash)
          rescue => e
            new_record_hash[:status_code] = 500
            failed(e, binding, new_record_hash)
          ensure
            processed_protos << proto.class.new(new_record_hash)
          end
        end

        processed_protos
      end

      def records_hashed_by_guid_from_protos(protos)
        guids = protos.map(&:guid).uniq.compact
        records_hashed_by_guid = {}

        _protobuf_base_model.__send__(guid_scope, guids).find_each do |record|
          records_hashed_by_guid.merge!({ record.guid => record })
        end

        return records_hashed_by_guid
      end

      def record_or_proto_to_hash(record_or_proto)
        record_or_proto.respond_to?(:to_proto_hash) ? record_or_proto.to_proto_hash : record_or_proto.to_hash
      end
    end
  end
end

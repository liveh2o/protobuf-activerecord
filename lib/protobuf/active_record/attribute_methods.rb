require "active_support/concern"

module Protobuf
  module ActiveRecord
    module AttributeMethods
      extend ActiveSupport::Concern

      module ClassMethods
        def alias_field(field_alias, attribute)
          alias_attribute field_alias, attribute

          attribute_from_proto attribute, fetch_attribute_alias_from_proto(attribute, field_alias)
          field_from_record field_alias, fetch_field_alias_from_record(attribute, field_alias)
        end

        def fetch_attribute_alias_from_proto(attribute, field_alias)
          lambda do |proto|
            value = proto.__send__(:"#{field_alias}!")
            value ||= proto.__send__(:"#{attribute}!") if proto.respond_to?(attribute)

            _protobuf_convert_fields_to_attributes(attribute, value)
          end
        end

        def fetch_field_alias_from_record(attribute, _field_aliasd)
          lambda do |record|
            value = record.__send__(field_alias)

            _protobuf_convert_attributes_to_fields(attribute, value)
          end
        end
      end
    end
  end
end

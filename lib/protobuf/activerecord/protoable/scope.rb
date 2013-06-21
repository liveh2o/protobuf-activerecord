module Protoable
  module Scope
    def self.extended(klass)
      klass.class_eval do
        class << self
          alias_method :by_fields, :search_scope
          alias_method :scope_from_proto, :search_scope
        end
      end
    end

    # Define fields that should be searchable via `search_scope`. Accepts a
    # protobuf field and an already defined scope.
    #
    # Optionally, a parser can be provided that will be called, passing the
    # field value as an argument. This allows custom data parsers to be used
    # so that they don't have to be handled by scopes. Parsers must respond
    # to `call` and accept a single parameter.
    #
    # Examples:
    #
    #   class User < ActiveRecord::Base
    #     scope :by_guid, lambda { |*guids| where(:guid => guids) }
    #
    #     field_scope :guid, :by_guid
    #
    #     # Custom parser that converts the value to an integer
    #     field_scope :guid, :by_guid, lambda { |value| value.to_i }
    #   end
    #
    def field_scope(field, scope_name, parser = nil)
      searchable_fields[field] = scope_name

      # When no parser is defined, define one that simply returns the value
      searchable_field_parsers[field] = parser || proc { |value| value }
    end

    # :noapi:
    def parse_search_values(proto, field)
      value = proto.__send__(field)
      value = searchable_field_parsers[field].call(value)

      values = [ value ].flatten
      values.map!(&:to_i) if proto.get_field_by_name(field).enum?
      values
    end

    # Builds and returns a Arel relation based on the fields that are present
    # in the given protobuf message using the searchable fields to determine
    # what scopes to use. Provides several aliases for variety.
    #
    # Examples:
    #
    #   # Search starting with the default scope and searchable fields
    #   User.search_scope(request)
    #   User.by_fields(request)
    #   User.scope_from_proto(request)
    #
    def search_scope(proto)
      relation = scoped # Get an ARel relation to build off of

      searchable_fields.each do |field, scope_name|
        next unless proto.respond_to_and_has_and_present?(field)

        unless self.respond_to?(scope_name)
          raise Protoable::SearchScopeError, "Undefined scope :#{scope_name}."
        end

        search_values = parse_search_values(proto, field)
        relation = relation.__send__(scope_name, *search_values)
      end

      return relation
    end

    # :noapi:
    def searchable_fields
      @_searchable_fields ||= {}
    end

    # :noapi:
    def searchable_field_parsers
      @_searchable_field_parsers ||= {}
    end
  end
end

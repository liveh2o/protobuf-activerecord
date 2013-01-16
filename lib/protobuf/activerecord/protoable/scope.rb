module Protoable
  module Scope
    def self.extended(klass)
      klass.class_eval do
        class << self
          alias_method :by_fields, :search_scope
          alias_method :from_proto, :search_scope
          alias_method :scope_from_proto, :search_scope
        end
      end
    end

    # Define fields that should be searchable via `search_scope`. Accepts a
    # protobuf field and an already defined scope.
    #
    # Examples:
    #
    #   class User < ActiveRecord::Base
    #     scope :by_guid, lambda { |*guids| where(:guid => guids) }
    #
    #     field_scope :guid, :by_guid
    #   end
    #
    def field_scope(field, scope_name)
      searchable_fields[field] = scope_name
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
    #   User.from_proto(request)
    #   User.scope_from_proto(request)
    #
    def search_scope(proto)
      relation = scoped # Get an ARel relation to build off of

      searchable_fields.each do |field, scope_name|
        next unless proto.respond_to_and_has_and_present?(field)

        unless self.respond_to?(scope_name)
          raise Protoable::SearchScopeError, "Undefined scope :#{scope_name}."
        end

        values = [ proto.__send__(field) ].flatten
        values.map!(&:to_i) if proto.get_field_by_name(field).enum?

        relation = relation.__send__(scope_name, *values)
      end

      return relation
    end

    # :noapi:
    def searchable_fields
      @_searchable_fields ||= {}
    end
  end
end

require 'active_support/concern'

module Protobuf
  module ActiveRecord
    module Scope
      extend ::ActiveSupport::Concern

      included do
        class << self
          alias_method :by_fields, :search_scope
          alias_method :scope_from_proto, :search_scope
        end
      end

      module ClassMethods
        # Define fields that should be searchable via `search_scope`. Accepts a
        # protobuf field and an already defined scope. If no scope is specified,
        # the scope will be the field name, prefixed with `by_` (e.g. when the
        # field is :guid, the scope will be :by_guid).
        #
        # Optionally, a parser can be provided that will be called, passing the
        # field value as an argument. This allows custom data parsers to be used
        # so that they don't have to be handled by scopes. Parsers can be procs,
        # lambdas, or symbolized method names and must accept the value of the
        # field as a parameter.
        #
        # Examples:
        #
        #   class User < ActiveRecord::Base
        #     scope :by_guid, lambda { |*guids| where(:guid => guids) }
        #     scope :custom_guid_scope, lambda { |*guids| where(:guid => guids) }
        #
        #     # Equivalent to `field_scope :guid, :by_guid`
        #     field_scope :guid
        #
        #     # With a custom scope
        #     field_scope :guid, :scope => :custom_guid_scope
        #
        #     # With a custom parser that converts the value to an integer
        #     field_scope :guid, :scope => :custom_guid_scope, :parser => lambda { |value| value.to_i }
        #   end
        #
        def field_scope(field, options = {})
          scope_name = if options.include?(:scope)
                         options[:scope]
                       else
                         # When no scope is defined, assume the scope is the field, prefixed with `by_`
                         :"by_#{field}"
                       end
          searchable_fields[field] = scope_name

          searchable_field_parsers[field] = options[:parser] if options[:parser]
        end

        # Get an ARel relation to build off of. If we're in Rails 4 we need to
        # use `all` instead of `scoped`.
        # :noapi:
        def model_scope
          ::ActiveRecord::VERSION::MAJOR >= 4 ? all : scoped
        end

        # :noapi:
        def parse_search_values(proto, field)
          value = proto.__send__(field)

          if searchable_field_parsers[field]
            parser = searchable_field_parsers[field]

            if parser.respond_to?(:to_sym)
              value = self.__send__(parser.to_sym, value)
            else
              value = parser.call(value)
            end
          end

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
          search_relation = model_scope

          searchable_fields.each do |field, scope_name|
            next unless proto.respond_to_and_has_and_present?(field)

            unless self.respond_to?(scope_name)
              raise Protobuf::ActiveRecord::SearchScopeError, "Undefined scope :#{scope_name}."
            end

            search_values = parse_search_values(proto, field)
            search_relation = search_relation.__send__(scope_name, *search_values)
          end

          return search_relation
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
  end
end

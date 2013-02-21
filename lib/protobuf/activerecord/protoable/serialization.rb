require 'heredity/inheritable_class_instance_variables'

module Protoable
  module Serialization
    def self.included(klass)
      klass.extend Protoable::Serialization::ClassMethods
      klass.__send__(:include, ::Heredity::InheritableClassInstanceVariables)

      klass.class_eval do
        class << self
          attr_accessor :_protobuf_field_transformers, :_protobuf_field_options
        end

        @_protobuf_field_transformers = {}
        @_protobuf_field_options = {}

        inheritable_attributes :_protobuf_field_transformers, :_protobuf_field_options,
          :protobuf_message
      end
    end

    module ClassMethods
      # :nodoc:
      def _protobuf_convert_attributes_to_fields(key, value)
        return value if value.nil?

        value = case
                when _protobuf_date_column?(key) then
                  value.to_time.to_i
                when _protobuf_datetime_column?(key) then
                  value.to_i
                when _protobuf_time_column?(key) then
                  value.to_i
                when _protobuf_timestamp_column?(key) then
                  value.to_i
                else
                  value
                end

        return value
      end

      # Define a field transformation from a record. Accepts a Symbol,
      # callable, or block that is called with the record being serialized.
      #
      # When given a callable or block, it is directly used to convert the field.
      #
      # When a symbol is given, it extracts the method with the same name.
      #
      # The callable or method must accept a single parameter, which is the
      # proto message.
      #
      # Examples:
      #   field_from_record :public_key, :convert_public_key_to_proto
      #   field_from_record :status, lambda { |record| # Do some stuff... }
      #   field_from_record :status do |record|
      #     # Do some blocky stuff...
      #   end
      #
      def field_from_record(field, transformer = nil, &block)
        transformer ||= block

        if transformer.is_a?(Symbol)
          callable = lambda { |value| self.__send__(transformer, value) }
        else
          callable = transformer
        end

        unless callable.respond_to?(:call)
          raise FieldTransformerError, 'Attribute transformers need a callable or block!'
        end

        _protobuf_field_transformers[field.to_sym] = callable
      end

      # Define the protobuf message class that should be used to serialize the
      # object to protobuf. Accepts a string or symbol and an options hash.
      #
      # When protobuf_message is declared, Protoable automatically extracts the
      # fields from the message and automatically adds a to_proto method that
      # serializes the object to protobuf.
      #
      # The fields that will be automatically serialized can be configured by
      # passing :only or :except in the options hash. If :only is specified, only
      # the specified fields will be serialized. If :except is specified, all
      # field except the specified fields will be serialized.
      #
      # By default, deprecated fields will be serialized. To exclude deprecated
      # fields, pass :deprecated => false in the options hash.
      #
      # Examples:
      #   protobuf_message :user_message
      #   protobuf_message "UserMessage"
      #   protobuf_message "Namespaced::UserMessage"
      #   protobuf_message :user_message, :only => [ :guid, :name ]
      #   protobuf_message :user_message, :except => :email_domain
      #   protobuf_message :user_message, :except => :email_domain, :deprecated => false
      #
      def protobuf_message(message = nil, options = {})
        unless message.nil?
          @protobuf_message = message.to_s.classify.constantize

          self._protobuf_field_options = options

          define_method(:to_proto) do |options = {}|
            self.class.protobuf_message.new(self.fields_from_record(options))
          end
        end

        @protobuf_message
      end
    end

    # :nodoc:
    def _filter_field_attributes(options = {})
      options = _normalize_options(options)

      fields = _filtered_fields(options)
      fields &= [ options[:only] ].flatten if options[:only].present?
      fields -= [ options[:except] ].flatten if options[:except].present?

      fields
    end

    # :nodoc:
    def _filtered_fields(options = {})
      exclude_deprecated = ! options.fetch(:deprecated, true)

      fields = self.class.protobuf_message.fields.map do |field|
        next if field.nil?
        next if exclude_deprecated && field.deprecated?
        field.name.to_sym
      end
      fields.compact!

      fields
    end

    # :nodoc:
    def _normalize_options(options)
      options ||= {}
      options[:only] ||= [] if options.fetch(:except, false)
      options[:except] ||= [] if options.fetch(:only, false)

      self.class._protobuf_field_options.merge(options)
    end

    # Extracts attributes that correspond to fields on the specified protobuf
    # message, performing any necessary column conversions on them. Accepts a
    # hash of options for specifying which fields should be serialized.
    #
    # Examples:
    #   fields_from_record(:only => [ :guid, :name ])
    #   fields_from_record(:except => :email_domain)
    #   fields_from_record(:include => :email_domain)
    #   fields_from_record(:except => :email_domain, :deprecated => false)
    #
    def fields_from_record(options = {})
      field_attributes = _filter_field_attributes(options)
      field_attributes += [ options.fetch(:include, []) ]
      field_attributes.flatten!
      field_attributes.compact
      field_attributes.uniq!

      field_attributes = field_attributes.inject({}) do |hash, field|
        if _protobuf_field_transformers.has_key?(field)
          hash[field] = _protobuf_field_transformers[field].call(self)
        else
          value = respond_to?(field) ? __send__(field) : nil
          hash[field] = _protobuf_convert_attributes_to_fields(field, value)
        end
        hash
      end

      field_attributes
    end

  private

    def _protobuf_convert_attributes_to_fields(field, value)
      self.class._protobuf_convert_attributes_to_fields(field, value)
    end

    def _protobuf_field_transformers
      self.class._protobuf_field_transformers
    end
  end
end

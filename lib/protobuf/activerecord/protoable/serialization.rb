require 'heredity/inheritable_class_instance_variables'

module Protoable
  module Serialization
    def self.included(klass)
      klass.extend Protoable::Serialization::ClassMethods
      klass.__send__(:include, ::Heredity::InheritableClassInstanceVariables)

      klass.class_eval do
        class << self
          attr_accessor :_protobuf_attribute_converters,
            :_protobuf_field_transformers, :protobuf_fields
        end

        @_protobuf_attribute_converters = {}
        @_protobuf_field_transformers = {}
        @protobuf_fields = []

        inheritable_attributes :_protobuf_attribute_converters,
          :_protobuf_field_transformers, :protobuf_fields, :protobuf_message
      end
    end

    module ClassMethods
      # :nodoc:
      def _initialize_protobuf_fields(options = {})
        options ||= {}

        exclude_deprecated = ! options.fetch(:deprecated, true)

        fields = @protobuf_message.fields.map do |field|
          next if field.nil?
          next if exclude_deprecated && field.deprecated?
          field.name.to_sym
        end
        fields.compact!

        fields &= [ options[:only] ].flatten if options.has_key?(:only)
        fields -= [ options[:except] ].flatten if options.has_key?(:except)

        self.protobuf_fields = fields
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
      # fields from the message and automatically adds to_proto and to_proto_hash
      # methods that serialize the object to protobuf.
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
      #   protobuf_message :user_message, :only => :guid, :name
      #   protobuf_message :user_message, :except => :email_domain
      #   protobuf_message :user_message, :except => :email_domain, :deprecated => false
      #
      def protobuf_message(message = nil, options = {})
        unless message.nil?
          @protobuf_message = message.to_s.classify.constantize

          _initialize_protobuf_fields(options)

          define_method(:to_proto) do
            self.class.protobuf_message.new(self.to_proto_hash)
          end

          define_method(:to_proto_hash) do
            fields_from_record
          end
        end

        @protobuf_message
      end
    end

    # Extracts attributes that correspond to fields on the specified protobuf
    # message, performing any necessary column conversions on them.
    #
    def fields_from_record
      field_attributes = protobuf_fields.inject({}) do |hash, field|
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

    def protobuf_fields
      self.class.protobuf_fields
    end
  end
end

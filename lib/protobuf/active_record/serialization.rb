require "set"
require "active_support/concern"

module Protobuf
  module ActiveRecord
    module Serialization
      extend ::ActiveSupport::Concern

      included do
        class << self
          attr_writer :_protobuf_field_symbol_transformers,
                      :_protobuf_field_transformers,
                      :_protobuf_field_options,
                      :protobuf_message
        end
      end

      module ClassMethods
        def _protobuf_field_objects
          @_protobuf_field_objects ||= {}
        end

        def _protobuf_field_options
          @_protobuf_field_options ||= {}
        end

        def _protobuf_field_symbol_transformers
          @_protobuf_field_symbol_transformers ||= {}
        end

        def _protobuf_field_transformers
          @_protobuf_field_transformers ||= {}
        end

        def _protobuf_message_deprecated_fields
          @_protobuf_message_deprecated_fields ||= begin
            self.protobuf_message.all_fields.map do |field|
              next if field.nil?
              next unless field.deprecated?

              field.name.to_sym
            end
          end
        end

        def _protobuf_message_non_deprecated_fields
          @_protobuf_message_non_deprecated_fields ||= begin
            self.protobuf_message.all_fields.map do |field|
              next if field.nil?
              next if field.deprecated?

              field.name.to_sym
            end
          end
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
          if transformer.is_a?(Symbol)
            _protobuf_field_symbol_transformers[field] = transformer
            return
          end

          transformer ||= block
          callable = transformer
          unless callable.respond_to?(:call)
            raise FieldTransformerError
          end

          _protobuf_field_transformers[field.to_sym] = callable
        end

        # Define the protobuf fields that will be automatically serialized (by default,
        # all fields will be serialized). Accepts any number of field names and is
        # equivalent to passing the :only option to `protobuf_message`.
        #
        # If :except is specified, all fields except the specified fields will be serialized.
        #
        # By default, deprecated fields will be serialized. To exclude deprecated
        # fields, pass :deprecated => false in the options hash.
        #
        # Examples:
        #   protobuf_fields :guid, :name
        #   protobuf_fields :except => :email_domain
        #   protobuf_fields :except => :email_domain, :deprecated => false
        #
        def protobuf_fields(*fields)
          options = fields.extract_options!
          options[:only] = fields if fields.present?

          self._protobuf_field_options = options
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
          end

          @protobuf_message
        end

        class CollectionAssociationCaller
          def initialize(method_name)
            @method_name = method_name
          end

          def call(selph)
            selph.__send__(@method_name).to_a
          rescue NameError # Has happened when field is not on model or ignored from db
            return nil
          end
        end

        def _protobuf_collection_association_object(field)
          CollectionAssociationCaller.new(field)
        end

        class DateCaller
          def initialize(field)
            @field = field
          end

          def call(selph)
            value = selph.__send__(@field)

            if value
              value.to_time(:utc).to_i
            end
          rescue NameError # Has happened when field is not on model or ignored from db
            return nil
          end
        end

        class DateTimeCaller
          def initialize(field)
            @field = field
          end

          def call(selph)
            value = selph.__send__(@field)

            value&.to_i
          rescue NameError # Has happened when field is not on model or ignored from db
            return nil
          end
        end

        class NoConversionCaller
          def initialize(field)
            @field = field
          end

          def call(selph)
            selph.__send__(@field)
          rescue NameError # Has happened when field is not on model or ignored from db
            return nil
          end
        end

        def _protobuf_convert_to_fields_object(field)
          is_datetime_time_or_timestamp_column = _protobuf_date_datetime_time_or_timestamp_column?(field)
          is_date_column = _protobuf_date_column?(field)

          if is_datetime_time_or_timestamp_column
            if is_date_column
              DateCaller.new(field)
            else
              DateTimeCaller.new(field)
            end
          else
            NoConversionCaller.new(field)
          end
        end

        def _protobuf_field_transformer_object(field)
          _protobuf_field_transformers[field]
        end

        class NilMethodCaller
          def initialize
          end

          def call(_selph)
            nil
          end
        end

        class NilRepeatedMethodCaller
          def initialize
          end

          def call(_selph)
            []
          end
        end

        def _protobuf_nil_object(field)
          if field == :nullify
            NilRepeatedMethodCaller.new
          else
            NilMethodCaller.new
          end
        end

        class FieldSymbolTransformerCaller
          def initialize(instance_class, method_name)
            @instance_class = instance_class
            @method_name = method_name
          end

          def call(selph)
            @instance_class.__send__(@method_name, selph)
          end
        end

        def _protobuf_symbol_transformer_object(field)
          FieldSymbolTransformerCaller.new(self, _protobuf_field_symbol_transformers[field])
        end
      end

      # :nodoc:
      def _filter_field_attributes(options = {})
        options = _normalize_options(options)

        fields = _filtered_fields(options)
        fields &= [options[:only]].flatten if options[:only].present?
        fields -= [options[:except]].flatten if options[:except].present?

        fields
      end

      # :nodoc:
      def _filtered_fields(options = {})
        include_deprecated = options.fetch(:deprecated, true)

        fields = []
        fields.concat(self.class._protobuf_message_non_deprecated_fields)
        fields.concat(self.class._protobuf_message_deprecated_fields) if include_deprecated
        fields.concat([options[:include]].flatten) if options[:include].present?
        fields.compact!
        fields.uniq!

        fields
      end

      # :nodoc:
      def _is_collection_association?(field)
        reflection = self.class.reflect_on_association(field)
        return false unless reflection

        reflection.macro == :has_many
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
        hash = {}
        field_attributes = _filter_field_attributes(options)

        # Already flattened / compacted / uniqued ... unless we must include
        if options[:include].present?
          field_attributes.concat([options[:include]].flatten)
          field_attributes.compact!
          field_attributes.uniq!
        end

        attribute_number = 0
        limit = field_attributes.size

        # One of the very few places the diff between each/while can make a difference
        # in terms of optimization (`while` is slightly faster as no block carried through)
        while attribute_number < limit
          field = field_attributes[attribute_number]
          field_object = _protobuf_field_objects(field)
          hash[field] = field_object.call(self)
          attribute_number += 1
        end

        hash
      end

      # :nodoc:
      def _protobuf_field_objects(field)
        self.class._protobuf_field_objects[field] ||= begin
          case
          when _protobuf_field_symbol_transformers.key?(field) then
            self.class._protobuf_symbol_transformer_object(field)
          when _protobuf_field_transformers.key?(field) then
            self.class._protobuf_field_transformer_object(field)
          when respond_to?(field) then
            if _is_collection_association?(field)
              self.class._protobuf_collection_association_object(field)
            else
              self.class._protobuf_convert_to_fields_object(field)
            end
          else
            self.class._protobuf_nil_object(field)
          end
        end
      end

      # :nodoc:
      def _protobuf_field_symbol_transformers
        self.class._protobuf_field_symbol_transformers
      end

      # :nodoc:
      def _protobuf_field_transformers
        self.class._protobuf_field_transformers
      end

      # :nodoc:
      def _protobuf_message
        self.class.protobuf_message
      end

      # :nodoc:
      def to_proto(options = {})
        raise MessageNotDefined, self.class if _protobuf_message.nil?

        fields = self.fields_from_record(options)
        _protobuf_message.new(fields)
      end
    end
  end
end

'active_support/concerns'

module Protobuf
  module ActiveRecord
    module Serialization
      extend ::ActiveSupport::Concern

      included do
        class << self
          attr_writer :_protobuf_field_transformers,
                      :_protobuf_field_options,
                      :protobuf_message
        end

        private :_protobuf_convert_attributes_to_fields
        private :_protobuf_field_transformers
        private :_protobuf_message
      end

      module ClassMethods

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

        def _protobuf_field_options
          @_protobuf_field_options ||= {}
        end

        def _protobuf_field_transformers
          @_protobuf_field_transformers ||= {}
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

        # :nodoc:
        def _deprecated_fields
          return @_deprecated_fields if @_deprecated_fields
          @_deprecated_fields = protobuf_message.all_fields.map do |field|
            next if field.nil?
            next unless field.deprecated?
            field.name.to_sym
          end
          @_deprecated_fields.flatten!
          @_deprecated_fields.compact!
          @_deprecated_fields.uniq!

          @_deprecated_fields
        end

        # :nodoc:
        def _protobuf_fields
          fields = protobuf_message.all_fields.map do |field|
            next if field.nil?
            field.name.to_sym
          end
          fields.flatten!
          fields.compact!
          fields.uniq!

          fields
        end

        # :nodoc:
        def _mapped_protobuf_fields
          return @_mapped_protobuf_fields if @_mapped_protobuf_fields
          @_mapped_protobuf_fields = _protobuf_fields.select do |field|
            _protobuf_field_transformers.key?(field) || instance_methods.include?(field)
          end
          @_mapped_protobuf_fields
        end
      end

      # :nodoc:
      def _filter_field_attributes(options = {})
        options = _normalize_options(options)

        fields = self.class._mapped_protobuf_fields
        fields &= [ options[:only] ].flatten if options[:only].present?
        fields -= [ options[:except] ].flatten if options[:except].present?
        fields -= self.class._deprecated_fields if options[:deprecated] == false
        fields += [ options[:include] ].flatten if options[:include].present?

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

        field_attributes = field_attributes.inject({}) do |hash, field|
          if _protobuf_field_transformers.key?(field)
            hash[field] = _protobuf_field_transformers[field].call(self)
          else
            value = __send__(field)
            hash[field] = _protobuf_convert_attributes_to_fields(field, value)
          end
          hash
        end

        field_attributes
      end

      # :nodoc:
      def _protobuf_convert_attributes_to_fields(field, value)
        self.class._protobuf_convert_attributes_to_fields(field, value)
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
        raise MessageNotDefined.new(self.class) if _protobuf_message.nil?

        fields = self.fields_from_record(options)
        _protobuf_message.new(fields)
      end
    end
  end
end

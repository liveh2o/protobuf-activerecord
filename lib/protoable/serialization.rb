module Protoable
  module Serialization
    def self.included(klass)
      klass.extend Protoable::Serialization::ClassMethods
      klass.__send__(:include, Protoable::InheritableClassInstanceVariables)

      klass.class_eval do
        class << self
          attr_accessor :_protobuf_column_converters, :protobuf_fields
        end

        @_protobuf_column_converters = {}
        @protobuf_fields = []

        # NOTE: Make sure each inherited object has the database layout
        inheritable_attributes :protobuf_fields, :_protobuf_column_converters
      end
    end

    module ClassMethods
      # Define a column conversion from db to protobuf. Accepts a callable,
      # Symbol, or Hash.
      #
      # When given a callable, it is directly used to convert the field.
      #
      # When a Hash is given, :from and :to keys are expected and expand
      # to extracting a class method in the format of
      # "convert_#{from}_to_#{to}".
      #
      # When a symbol is given, it extracts the method with the same name,
      # if any. When method is not available it is assumed as the "from"
      # data type, and the "to" value is extracted based on the
      # name of the column.
      #
      # Examples:
      #   convert_column :created_at, :int64
      #   convert_column :public_key, :extract_public_key_from_proto
      #   convert_column :public_key, method(:extract_public_key_from_proto)
      #   convert_column :status, lambda { |proto_field| ... }
      #   convert_column :symmetric_key, :from => :base64, :to => :raw_string
      #
      def convert_column(field, callable = nil, &blk)
        callable ||= blk

        if callable.is_a?(Hash)
          callable = :"convert_#{callable[:from]}_to_#{callable[:to]}"
        end

        if callable.is_a?(Symbol)
          unless self.respond_to?(callable)
            column = _protobuf_columns[field.to_sym]
            callable = :"convert_#{callable}_to_#{column.try(:type)}"
          end
          callable = method(callable) if self.respond_to?(callable)
        end

        if callable.nil? || !callable.respond_to?(:call)
          raise ColumnConverterError, 'Column converters must be a callable or block!'
        end

        _protobuf_column_converters[field.to_sym] = callable
      end

      # Define the protobuf message class that should be used to serialize the
      # object to protobuf. Accepts a string or symbol.
      #
      # When protobuf_message is declared, Protoable automatically extracts the
      # fields from the message and automatically adds to_proto and to_proto_hash
      # methods that serialize the object to protobuf.
      #
      # Examples:
      #   protobuf_message :user_message
      #   protobuf_message "UserMessage"
      #   protobuf_message "Namespaced::UserMessage"
      #
      def protobuf_message(message = nil)
        unless message.nil?
          @_protobuf_message = message.to_s.classify.constantize

          self.protobuf_fields = @_protobuf_message.fields.compact.map do |field|
            field.name.to_sym
          end

          define_method(:to_proto) do
            self.class.protobuf_message.new(self.to_proto_hash)
          end

          define_method(:to_proto_hash) do
            protoable_attributes
          end
        end

        @_protobuf_message
      end
    end

    # Extracts attributes that correspond to fields on the specified protobuf
    # message, performing any necessary column conversions on them.
    #
    def protoable_attributes
      protoable_attributes = protobuf_fields.inject({}) do |hash, field|
        value = respond_to?(field) ? __send__(field) : nil
        hash[field] = _protobuf_convert_columns_to_fields(field, value)
        hash
      end

      protoable_attributes
    end

  private

    def _protobuf_convert_columns_to_fields(field, value)
      self.class._protobuf_convert_columns_to_fields(field, value)
    end

    def protobuf_fields
      self.class.protobuf_fields
    end
  end
end

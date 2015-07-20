module Protobuf
  module ActiveRecord
    class Transformer
      attr_accessor :callable, :options

      def initialize(callable, options = {})
        @callable = callable
        @options = options
      end

      def call(proto)
        callable.call(proto)
      end

      def nullify?(proto)
        return false unless options[:nullify_on]
        unless proto.field?(:nullify) && proto.nullify.is_a?(Array)
          ::Protobuf::Logging.logger.warn "Message: #{proto.class} is not compatible with :nullify_on option"
          return false
        end

        proto.nullify.include?(options[:nullify_on].to_s)
      end
    end
  end
end

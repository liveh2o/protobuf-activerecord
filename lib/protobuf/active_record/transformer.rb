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

        proto.field?(:nullify) && proto.nullify.include?(options[:nullify_on].to_s)
      end
    end
  end
end

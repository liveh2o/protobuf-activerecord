module Protobuf
  module ActiveRecord
    class Transformer
      attr_accessor :callable, :options

      def initialize(callable, options = {})
        @callable = callable
        @options = options
      end

      delegate :call, :to => :callable

      def nullify?(proto)
        return false unless options[:nullify_on]
        return false unless proto.field?(:nullify) && proto.nullify.is_a?(Array)
        return false if proto.nullify.empty?

        proto.nullify.include?(options[:nullify_on].to_s)
      end
    end
  end
end

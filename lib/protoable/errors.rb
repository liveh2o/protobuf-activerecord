module Protoable
  module Errors
    def errors_for_protobuf
      return [] if valid?

      errors.messages.map do |field, error_messages|
        {
          :field => field.to_s,
          :messages => error_messages.dup
        }
      end

      # TODO: Move these status codes to a constant
      def status_code_for_protobuf
        return valid? ? 200 : 400
      end
    end
  end
end

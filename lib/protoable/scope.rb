module Protoable
  module Scope
    def self.included(klass)
      klass.extend Protoable::Scope::ClassMethods
    end

    module ClassMethods
      # Method that returns the scope based on the fields that are present
      # in the protobuf.
      #
      # Only works if scopes are named with convention of "by_#{field_name}"
      def scope_from_search_proto(search_scope, proto, *field_symbols)
        field_symbols.flatten.each do |field|
          if responds_to_and_has_and_present?(proto, field)
            search_scope = search_scope.__send__("by_#{field}", proto.__send__(field))
          end
        end

        return search_scope
      end
    end
  end
end

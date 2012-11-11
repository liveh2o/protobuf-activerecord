require 'protobuf'

class Protobuf::Message
  unless method_defined?(:respond_to_and_has?)
    def respond_to_and_has?(key)
      self.respond_to?(key) && self.has_field?(key)
    end
  end

  unless method_defined?(:respond_to_and_has_and_present?)
    def respond_to_and_has_and_present?(key)
      self.respond_to_and_has?(key) &&
        (self.__send__(key).present? || [true, false].include?(self.__send__(key)))
    end
  end
end

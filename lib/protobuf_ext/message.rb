require 'protobuf'

class Protobuf::Message
  def respond_to_and_has?(field)
    self.respond_to?(field) && self.has_field?(field)
  end

  def respond_to_and_has_and_present?(field)
    self.respond_to_and_has?(field) && self.__send__(field).present?
  end
end

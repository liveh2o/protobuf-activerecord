class User < ActiveRecord::Base
  include Protoable

  def self.convert_base64_to_string(value)
    value
  end

  def self.convert_email_to_lowercase(value)
    value
  end

  def self.extract_first_name(proto)
    ""
  end

  def self.extract_last_name(proto)
    ""
  end
  
  def name
    "#{first_name} #{last_name}"
  end
end

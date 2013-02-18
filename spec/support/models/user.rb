class User < ActiveRecord::Base
  include Protoable

  scope :by_guid, lambda { |*guids| where(:guid => guids) }
  scope :by_email, lambda { |*emails| where(:email => emails) }

  attribute_from_proto :first_name, :extract_first_name
  attribute_from_proto :last_name, :extract_last_name

  def self.extract_first_name(proto)
    if proto.has_field?(:name)
      names = proto.name.split(" ")
      first_name = names.first
    end

    first_name
  end

  def self.extract_last_name(proto)
    if proto.has_field?(:name)
      names = proto.name.split(" ")
      names.shift # Drop the first name
      last_name = names.join(" ")
    end

    last_name
  end

  def name
    "#{first_name} #{last_name}"
  end
end

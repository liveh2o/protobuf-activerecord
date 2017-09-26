class User < ActiveRecord::Base
  include Protobuf::ActiveRecord::Model

  attr_accessor :password

  has_many :photos

  accepts_nested_attributes_for :photos

  scope :by_guid, lambda { |*guids| where(:guid => guids) }
  scope :by_email, lambda { |*emails| where(:email => emails) }

  protobuf_fields :except => :photos

  attribute_from_proto :first_name, :extract_first_name
  attribute_from_proto :last_name, :extract_last_name
  attribute_from_proto :password, lambda { |proto| proto.password! }

  field_from_record :email_domain, lambda { |record| record.email.split('@').last }

  def self.extract_first_name(proto)
    if proto.field?(:name)
      names = proto.name.split(" ")
      first_name = names.first
    end

    first_name
  end

  def self.extract_last_name(proto)
    if proto.field?(:name)
      names = proto.name.split(" ")
      names.shift # Drop the first name
      last_name = names.join(" ")
    end

    last_name
  end

  def token
    "key"
  end

  def name
    "#{first_name} #{last_name}"
  end
end

require 'spec_helper'

describe Protobuf::ActiveRecord::Persistence do
  let(:user) { User.new(user_attributes) }
  let(:user_attributes) { { :first_name => 'foo', :last_name => 'bar', :email => 'foo@test.co' } }
  let(:proto_hash) { { :name => 'foo bar', :email => 'foo@test.co' } }
  let(:proto) { UserMessage.new(proto_hash) }

  describe ".create" do
    it "accepts a protobuf message" do
      User.any_instance.should_receive(:save)
      User.create(proto)
    end

    it "accepts a hash" do
      User.any_instance.should_receive(:save)
      User.create(user_attributes)
    end
  end

  describe ".create!" do
    it "accepts a protobuf message" do
      User.any_instance.should_receive(:save!)
      User.create!(proto)
    end

    it "accepts a hash" do
      User.any_instance.should_receive(:save!)
      User.create!(user_attributes)
    end
  end

  describe "#assign_attributes" do
    let(:user) { ::User.new }

    it "accepts a protobuf message" do
      user.assign_attributes(proto)
      user.changed?.should be_true
    end

    it "accepts a hash" do
      user.assign_attributes(user_attributes)
      user.changed?.should be_true
    end
  end

  describe "#update_attributes" do
    it "accepts a protobuf message" do
      User.any_instance.should_receive(:save)
      user.update_attributes(proto)
    end

    it "accepts a hash" do
      User.any_instance.should_receive(:save)
      user.update_attributes(user_attributes)
    end
  end

  describe "#update_attributes!" do
    it "accepts a protobuf message" do
      User.any_instance.should_receive(:save!)
      user.update_attributes!(proto)
    end

    it "accepts a hash" do
      User.any_instance.should_receive(:save!)
      user.update_attributes!(user_attributes)
    end
  end
end

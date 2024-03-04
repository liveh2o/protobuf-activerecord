require "spec_helper"

describe Protobuf::ActiveRecord::Persistence do
  let(:user) { User.new(user_attributes) }
  let(:user_attributes) { {first_name: "foo", last_name: "bar", email: "foo@test.co"} }
  let(:proto_hash) { {name: "foo bar", email: "foo@test.co"} }
  let(:proto) { UserMessage.new(proto_hash) }

  describe ".create" do
    it "accepts a protobuf message" do
      expect_any_instance_of(User).to receive(:save)
      User.create(proto)
    end

    it "accepts a hash" do
      expect_any_instance_of(User).to receive(:save)
      User.create(user_attributes)
    end
  end

  describe ".create!" do
    it "accepts a protobuf message" do
      expect_any_instance_of(User).to receive(:save!)
      User.create!(proto)
    end

    it "accepts a hash" do
      expect_any_instance_of(User).to receive(:save!)
      User.create!(user_attributes)
    end
  end

  describe "#assign_attributes" do
    let(:user) { ::User.new }

    it "accepts a protobuf message" do
      user.assign_attributes(proto)
      expect(user.changed?).to be true
    end

    it "accepts a hash" do
      user.assign_attributes(user_attributes)
      expect(user.changed?).to be true
    end
  end

  describe "#update" do
    it "accepts a protobuf message" do
      expect_any_instance_of(User).to receive(:save)
      user.update(proto)
    end

    it "accepts a hash" do
      expect_any_instance_of(User).to receive(:save)
      user.update(user_attributes)
    end
  end

  describe "#update!" do
    it "accepts a protobuf message" do
      expect_any_instance_of(User).to receive(:save!)
      user.update!(proto)
    end

    it "accepts a hash" do
      expect_any_instance_of(User).to receive(:save!)
      user.update!(user_attributes)
    end
  end
end

require 'spec_helper'

describe Protoable::Persistence do
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

  describe ".create_from_proto" do
    it "initializes a new object with attributes from the given protobuf message" do
      user = User.create_from_proto(proto)
      attributes = user.attributes.slice("first_name", "last_name", "email")
      attributes.should eq user_attributes.stringify_keys
    end

    context "when a block is given" do
      it "yields to the block with attributes from the given protobuf message" do
        yielded = nil

        User.create_from_proto(proto) do |attributes|
          yielded = "boom!"
        end

        yielded.should eq "boom!"
      end
    end

    context "when the object is valid" do
      it "saves the record" do
        user = User.create_from_proto(proto)
        user.persisted?.should be_true
      end

      context "when an error occurs while saving" do
        before { User.any_instance.stub(:create).and_raise(RuntimeError) }

        it "raises an exception" do
          expect { User.create_from_proto(proto) }.to raise_exception
        end
      end
    end

    context "when the object is not valid" do
      before { User.any_instance.stub(:valid?).and_return(false) }

      it "returns the new object, unsaved" do
        user = User.create_from_proto(proto)
        user.persisted?.should be_false
      end
    end
  end

  describe "#destroy_from_proto" do
    it "destroys the object" do
      user.should_receive(:destroy)
      user.destroy_from_proto
    end
  end

  describe ".update_attributes" do
    it "accepts a protobuf message" do
      User.any_instance.should_receive(:save)
      user.update_attributes(proto)
    end

    it "accepts a hash" do
      User.any_instance.should_receive(:save)
      user.update_attributes(user_attributes)
    end
  end

  describe ".update_attributes!" do
    it "accepts a protobuf message" do
      User.any_instance.should_receive(:save!)
      user.update_attributes!(proto)
    end

    it "accepts a hash" do
      User.any_instance.should_receive(:save!)
      user.update_attributes!(user_attributes)
    end
  end

  describe "#update_from_proto" do
    it "updates the object with attributes from the given protobuf message" do
      user.should_receive(:assign_attributes).with(user_attributes, {})
      user.update_from_proto(proto)
    end

    context "when a block is given" do
      it "yields to the block with attributes from the given protobuf message" do
        yielded = nil

        user.update_from_proto(proto) do |attributes|
          yielded = "boom!"
        end

        yielded.should eq "boom!"
      end
    end

    context "when the object is valid" do
      before { user.stub(:valid?).and_return(true) }

      context "when saving is successful" do
        it "returns true" do
          user.stub(:assign_attributes).and_return(true)
          user.update_from_proto(proto).should be_true
        end
      end

      context "when an error occurs while saving" do
        before { user.stub(:assign_attributes).and_raise(RuntimeError) }

        it "raises an exception" do
          expect { user.update_from_proto }.to raise_exception
        end
      end
    end

    context "when the object is invalid" do
      before { user.stub(:valid?).and_return(false) }

      it "returns false" do
        user.update_from_proto(proto).should be_false
      end
    end
  end
end

require 'spec_helper'

describe Protoable::Transformation do
  let(:user) { User.new(user_attributes) }
  let(:user_attributes) { { :first_name => 'foo', :last_name => 'bar', :email => 'foo@test.co' } }
  let(:proto_hash) { { :name => 'foo bar', :email => 'foo@test.co' } }
  let(:proto) { UserMessage.new(proto_hash) }

  describe "._filter_attribute_fields" do
    it "includes fields that have values" do
      attribute_fields = User._filter_attribute_fields(proto)
      attribute_fields[:email].should eq proto_hash[:email]
    end

    it "filters repeated fields" do
      attribute_fields = User._filter_attribute_fields(proto)
      attribute_fields.has_key?(:tags).should be_false
    end

    it "includes attributes that aren't fields, but have attribute transformers" do
      User.stub(:_protobuf_attribute_transformers).and_return({ :account_id => :fetch_account_id })
      attribute_fields = User._filter_attribute_fields(proto)
      attribute_fields.has_key?(:account_id).should be_true
    end
  end

  describe ".attributes_from_proto" do
    context "when a transformer is defined for the attribute" do
      it "transforms the field value" do
        attribute_fields = User.attributes_from_proto(proto)
        attribute_fields[:first_name].should eq user_attributes[:first_name]
      end
    end

    context "when a transformer is a callable that returns nil" do
      before do
        transformers = User._protobuf_attribute_transformers
        User.stub(:_protobuf_attribute_transformers).and_return(
          {:account_id => lambda { |proto| nil }}.merge(transformers)
        )
      end

      it "does not set the attribute" do
        attribute_fields = User.attributes_from_proto(proto)
        attribute_fields.should eq user_attributes
      end
    end

    context "when a transformer is a callable that returns a value" do
      before do
        transformers = User._protobuf_attribute_transformers
        User.stub(:_protobuf_attribute_transformers).and_return(
          {:account_id => lambda { |proto| 1 }}.merge(transformers)
        )
      end

      it "sets the attribute" do
        attribute_fields = User.attributes_from_proto(proto)
        attribute_fields.should eq user_attributes.merge(:account_id => 1)
      end
    end

    context "when a transformer is not defined for the attribute" do
      before {
        User.stub(:_protobuf_convert_fields_to_columns) do |key, value|
          value
        end
      }

      it "converts the field value" do
        attribute_fields = User.attributes_from_proto(proto)
        attribute_fields.should eq user_attributes
      end
    end
  end

  describe ".attribute_from_proto" do
    context "when the given transformer is a symbol" do
      let(:callable) { lambda { |value| User.__send__(:extract_first_name) } }

      before { User.attribute_from_proto :first_name, :extract_first_name }

      it "creates a callable method object from the converter" do
        User.should_receive(:extract_first_name)
        User._protobuf_attribute_transformers[:first_name].call(1)
      end
    end

    context "when the given transformer is not callable" do
      it "raises an exception" do
        expect { User.attribute_from_proto :name, nil }.to raise_exception(Protoable::AttributeTransformerError)
      end
    end

    context "when the given transformer is callable" do
      let(:callable) { lambda { |proto| nil } }

      before {
        User.stub(:_protobuf_attribute_transformers).and_return(Hash.new)
        User.attribute_from_proto :account_id, callable
      }

      it "adds the given converter to the list of protobuf field transformers" do
        User._protobuf_attribute_transformers[:account_id] = callable
      end
    end
  end
  
  describe "#attributes_from_proto" do
    it "gets attributes from the given protobuf message" do
      User.should_receive(:attributes_from_proto).with(proto)
      user.attributes_from_proto(proto)
    end
  end
end
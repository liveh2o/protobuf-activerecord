require 'spec_helper'

describe Protoable::Serialization do
  let(:protobuf_message) { UserMessage }

  describe ".protoable_attribute" do
    context "when the given converter is a hash" do
      let(:method) { lambda { |value| User.__send__(:convert_base64_to_string, value) } }

      before { User.protoable_attribute :public_key, :from => :base64, :to => :string }

      it "determines the method using the hash's :to and :from keys" do
        User.should_receive(:convert_base64_to_string)
        User._protobuf_attribute_converters[:public_key].call(1)
      end
    end

    context "when the given converter is a symbol" do
      let(:callable) { lambda { |value| User.__send__(:convert_email_to_lowercase, value) } }

      before { User.protoable_attribute :email, :convert_email_to_lowercase }

      it "creates a callable method object from the converter" do
        User.should_receive(:convert_email_to_lowercase)
        User._protobuf_attribute_converters[:email].call(1)
      end
    end

    context "when the given converter is not callable" do
      it "raises an exception" do
        expect { User.protoable_attribute :email, nil }.to raise_exception(Protoable::AttributeConverterError)
      end
    end

    context "when the given converter is callable" do
      let(:callable) { lambda { |value| value } }

      before { User.protoable_attribute :email, callable }

      it "adds the given converter to list of attribute converters" do
        User._protobuf_attribute_converters[:email].should eq callable
      end
    end
  end

  describe ".protobuf_message" do
    before { User.protobuf_message(protobuf_message) }

    context "given a value" do
      let(:protobuf_fields) { [ :guid, :name, :email ] }

      it "sets .protobuf_fields" do
        User.protobuf_fields.should =~ protobuf_fields
      end

      it "defines #to_proto" do
        User.allocate.should respond_to :to_proto
      end

      it "defines #to_proto_hash" do
        User.allocate.should respond_to :to_proto_hash
      end
    end

    it "returns the protobuf message for this object" do
      User.protobuf_message.should eq protobuf_message
    end
  end

  context "when protobuf_message is defined" do
    let(:attributes) { Hash.new }
    let(:user) { User.new(attributes) }

    before { User.protobuf_message(protobuf_message) }

    describe "#protoable_attributes" do
      let(:attributes) {
        {
          :guid => "foo",
          :first_name => "bar",
          :last_name => "baz",
          :email => "foo@test.co"
        }
      }
      let(:protoable_attributes) { { :guid => user.guid, :name => user.name, :email => user.email } }

      it "returns a hash of protobuf fields that this object has getters for" do
        user.protoable_attributes.should eq protoable_attributes
      end

      it "converts attributes values for protobuf messages" do
        user.should_receive(:_protobuf_convert_attributes_to_fields).any_number_of_times
        user.protoable_attributes
      end
    end

    describe "#to_proto" do
      let(:proto) { protobuf_message.new(proto_hash) }
      let(:proto_hash) { { :name => "foo" } }

      before { user.stub(:to_proto_hash).and_return(proto_hash) }

      it "intializes a new protobuf message with attributes from #to_proto_hash" do
        user.to_proto.should eq proto
      end
    end

    describe "#to_proto_hash" do
      let(:proto_hash) { { :name => "foo" } }

      before { user.stub(:protoable_attributes).and_return(proto_hash) }

      it "returns #protoable_attributes" do
        user.to_proto_hash.should eq proto_hash
      end
    end
  end
end

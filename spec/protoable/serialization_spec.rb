require 'spec_helper'

describe Protoable::Serialization do
  let(:protobuf_message) { UserMessage }

  describe ".field_from_record" do
    context "when the given converter is a symbol" do
      let(:callable) { lambda { |value| User.__send__(:extract_first_name) } }

      before { User.field_from_record :first_name, :extract_first_name }

      it "creates a callable method object from the converter" do
        User.should_receive(:extract_first_name)
        User._protobuf_field_transformers[:first_name].call(1)
      end
    end

    context "when the given converter is not callable" do
      it "raises an exception" do
        expect { User.field_from_record :name, nil }.to raise_exception(Protoable::FieldTransformerError)
      end
    end

    context "when the given transformer is callable" do
      let(:callable) { lambda { |proto| nil } }

      before {
        User.stub(:_protobuf_field_transformers).and_return(Hash.new)
        User.field_from_record :account_id, callable
      }

      it "adds the given converter to the list of protobuf field transformers" do
        User._protobuf_field_transformers[:account_id] = callable
      end
    end
  end

  describe ".protobuf_message" do
    before { User.protobuf_message(protobuf_message) }

    context "given a value" do
      let(:protobuf_fields) { [ :guid, :name, :email, :email_domain ] }

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

    describe "#fields_from_record" do
      context "when a transformer is defined for the field" do
        let(:attributes) {
          {
            :guid => "foo",
            :first_name => "bar",
            :last_name => "baz",
            :email => "foo@test.co"
          }
        }
        let(:fields_from_record) { { :guid => user.guid, :name => user.name, :email => user.email, :email_domain => 'test.co' } }
        let(:transformer) { { :email_domain => lambda { |record| record.email.split('@').last } } }

        before {
          User.stub(:_protobuf_field_transformers).and_return(transformer)
        }

        it "gets the field from the transformer" do
          user.fields_from_record.should eq fields_from_record
        end
      end

      context "when a transformer is not defined for the field" do
        let(:attributes) {
          {
            :guid => "foo",
            :first_name => "bar",
            :last_name => "baz",
            :email => "foo@test.co"
          }
        }
        let(:fields_from_record) { { :guid => user.guid, :name => user.name, :email => user.email, :email_domain => nil } }

        it "returns a hash of protobuf fields that this object has getters for" do
          user.fields_from_record.should eq fields_from_record
        end

        it "converts attributes values for protobuf messages" do
          user.should_receive(:_protobuf_convert_attributes_to_fields).any_number_of_times
          user.fields_from_record
        end
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

      before { user.stub(:fields_from_record).and_return(proto_hash) }

      it "returns #fields_from_record" do
        user.to_proto_hash.should eq proto_hash
      end
    end
  end
end

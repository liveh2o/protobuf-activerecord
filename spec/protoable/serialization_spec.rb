require 'spec_helper'

describe Protoable::Serialization do
  let(:protobuf_message) { ::Proto::User }

  describe ".convert_column" do
    context "when the given converter is a hash" do
      let(:method) { User.method(:convert_base64_to_string) }

      before { User.convert_column :public_key, :from => :base64, :to => :string }

      it "determines the method using the hash's :to and :from keys" do
        User._protobuf_column_converters[:public_key].should eq method
      end
    end

    context "when the given converter is a symbol" do
      context "when the converter is not a defined method" do
        let(:callable) { User.method(:convert_base64_to_string) }

        before { User.convert_column :email, :base64 }

        it "determines the method using the converter as the 'from' and the column type as the 'to'" do
          User._protobuf_column_converters[:email].should eq callable
        end
      end

      context "when the converter is a defined method" do
        let(:callable) { User.method(:convert_email_to_lowercase) }

        before { User.convert_column :email, :convert_email_to_lowercase }

        it "creates a callable method object from the converter" do
          User._protobuf_column_converters[:email].should eq callable
        end
      end
    end

    context "when the given converter is nil" do
      it "raises an exception" do
        expect { User.convert_column :email, nil }.to raise_exception(Protoable::ColumnConverterError)
      end
    end

    context "when the given converter is not callable" do
      it "raises an exception" do
        expect { User.convert_column :email, :foo }.to raise_exception(Protoable::ColumnConverterError)
      end
    end

    context "when the given converter is callable" do
      let(:callable) { lambda { |value| value } }

      before { User.convert_column :email, callable }

      it "adds the given converter to list of column converters" do
        User._protobuf_column_converters[:email].should eq callable
      end
    end
  end

  describe ".protobuf_message" do
    before { User.protobuf_message(protobuf_message) }

    context "given a value" do
      let(:protobuf_fields) { [ :name, :email ] }

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
          :first_name => "foo",
          :last_name => "bar",
          :email => "foo@test.co"
        }
      }
      let(:protoable_attributes) { { :name => user.name, :email => user.email } }

      it "returns a hash of protobuf fields that this object has getters for" do
        user.protoable_attributes.should eq protoable_attributes
      end

      it "converts attributes values for protobuf messages" do
        user.should_receive(:_protobuf_convert_columns_to_fields).twice
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

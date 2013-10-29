require 'spec_helper'

# Used to test calling #to_proto when no protobuf message is configured.
class UnconfiguredUser
  include Protobuf::ActiveRecord::Model
end

describe Protobuf::ActiveRecord::Serialization do
  let(:protobuf_message) { UserMessage }

  describe "._protobuf_convert_attributes_to_fields" do
    context "when the column type is :date" do
      let(:date) { Date.current }
      let(:integer) { date.to_time.to_i }

      before { User.stub(:_protobuf_date_column?).and_return(true) }

      it "converts the given value to an integer" do
        User._protobuf_convert_attributes_to_fields(:foo_date, date).should eq integer
      end
    end

    context "when the column type is :datetime" do
      let(:datetime) { DateTime.current }
      let(:integer) { datetime.to_time.to_i }

      before { User.stub(:_protobuf_datetime_column?).and_return(true) }

      it "converts the given value to an integer" do
        User._protobuf_convert_attributes_to_fields(:foo_datetime, datetime).should eq integer
      end
    end

    context "when the column type is :time" do
      let(:time) { Time.current }
      let(:integer) { time.to_time.to_i }

      before { User.stub(:_protobuf_time_column?).and_return(true) }

      it "converts the given value to an integer" do
        User._protobuf_convert_attributes_to_fields(:foo_time, time).should eq integer
      end
    end

    context "when the column type is :timestamp" do
      let(:timestamp) { Time.current }
      let(:integer) { timestamp.to_time.to_i }

      before { User.stub(:_protobuf_timestamp_column?).and_return(true) }

      it "converts the given value to an integer" do
        User._protobuf_convert_attributes_to_fields(:foo_timestamp, timestamp).should eq integer
      end
    end

    context "when no conversion is necessary" do
      let(:value) { "Foo" }

      it "returns the given value" do
        User._protobuf_convert_attributes_to_fields(:foo, value).should eq value
      end
    end
  end

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
        expect { User.field_from_record :name, nil }.to raise_exception(Protobuf::ActiveRecord::FieldTransformerError)
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
    let(:options) { { :only => [] } }

    before { User.protobuf_message(protobuf_message, options) }
    after { User.protobuf_message(protobuf_message, {}) }

    context "given a value" do
      it "defines #to_proto" do
        User.allocate.should respond_to :to_proto
      end
    end

    context "given options" do
      it "merges them with protobuf field options" do
        User._protobuf_field_options.should eq options
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

    describe "#_filter_field_attributes" do
      context "when options has :only" do
        it "only returns the given field(s)" do
          fields = user._filter_field_attributes(:only => :name).should
          fields.should eq [ :name ]
        end
      end

      context "when options has :except" do
        it "returns all except the given field(s)" do
          fields = user._filter_field_attributes(:except => :name).should
          fields.should eq [ :guid, :email, :email_domain, :password ]
        end
      end
    end

    describe "#_filtered_fields" do
      it "returns protobuf fields" do
        user._filtered_fields.should eq [ :guid, :name, :email, :email_domain, :password ]
      end

      context "given :deprecated => false" do
        it "filters all deprecated fields" do
          fields = user._filtered_fields(:deprecated => false).should
          fields.should eq [ :guid, :name, :email, :password ]
        end
      end
    end

    describe "#_normalize_options" do
      let(:options) { { :only => [ :name ] } }

      context "given empty options" do
        before { User.protobuf_message(protobuf_message, options) }

        it "returns the class's protobuf field options" do
          User.allocate._normalize_options({}).should eq options
        end
      end

      context "given options" do
        before { User.protobuf_message(protobuf_message, {}) }

        it "merges them with the class's protobuf field options" do
          normalized_options = User.allocate._normalize_options(options)
          normalized_options[:only].should eq options[:only]
        end
      end

      context "given options with :only" do
        before { User.protobuf_message(protobuf_message, {}) }

        it "ensures that :except exists" do
          normalized_options = User.allocate._normalize_options(options)
          normalized_options[:except].should eq []
        end
      end

      context "given options with :except" do
        let(:options) { { :except => [ :name ] } }

        before { User.protobuf_message(protobuf_message, {}) }

        it "ensures that :only exists" do
          normalized_options = User.allocate._normalize_options(options)
          normalized_options[:only].should eq []
        end
      end
    end

    describe "#fields_from_record" do
      let(:attributes) {
        {
          :guid => "foo",
          :first_name => "bar",
          :last_name => "baz",
          :email => "foo@test.co"
        }
      }

      context "when a transformer is defined for the field" do
        let(:fields_from_record) { { :guid => user.guid, :name => user.name, :email => user.email, :email_domain => 'test.co', :password => nil } }
        let(:transformer) { { :email_domain => lambda { |record| record.email.split('@').last } } }

        before {
          User.stub(:_protobuf_field_transformers).and_return(transformer)
        }

        it "gets the field from the transformer" do
          user.fields_from_record.should eq fields_from_record
        end
      end

      context "when a transformer is not defined for the field" do
        let(:fields_from_record) { { :guid => user.guid, :name => user.name, :email => user.email, :email_domain => nil, :password => nil } }

        it "returns a hash of protobuf fields that this object has getters for" do
          user.fields_from_record.should eq fields_from_record
        end

        it "converts attributes values for protobuf messages" do
          user.stub(:_protobuf_convert_attributes_to_fields)
          user.fields_from_record
        end
      end

      context "given options with :include" do
        it "adds the given field to the list of serialized fields" do
          fields = user.fields_from_record(:include => :token)
          fields.include?(:token).should be_true
        end
      end
    end

    describe "#to_proto" do
      context "when a protobuf message is configured" do
        let(:proto) { protobuf_message.new(proto_hash) }
        let(:proto_hash) { { :name => "foo" } }

        before { user.stub(:fields_from_record).and_return(proto_hash) }

        it "intializes a new protobuf message with attributes from #to_proto_hash" do
          user.to_proto.should eq proto
        end
      end

      context "when a protobuf message is not configured" do
        let(:user) { UnconfiguredUser.new }

        it "raises an exception" do
          expect { user.to_proto }.to raise_exception(Protobuf::ActiveRecord::MessageNotDefined)
        end
      end
    end
  end
end

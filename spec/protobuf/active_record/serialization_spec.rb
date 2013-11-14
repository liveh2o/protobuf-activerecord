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

      before { User.stubs(:_protobuf_date_column?).returns(true) }

      it "converts the given value to an integer" do
        User._protobuf_convert_attributes_to_fields(:foo_date, date).must_equal integer
      end
    end

    context "when the column type is :datetime" do
      let(:datetime) { DateTime.current }
      let(:integer) { datetime.to_time.to_i }

      before { User.stubs(:_protobuf_datetime_column?).returns(true) }

      it "converts the given value to an integer" do
        User._protobuf_convert_attributes_to_fields(:foo_datetime, datetime).must_equal integer
      end
    end

    context "when the column type is :time" do
      let(:time) { Time.current }
      let(:integer) { time.to_time.to_i }

      before { User.stubs(:_protobuf_time_column?).returns(true) }

      it "converts the given value to an integer" do
        User._protobuf_convert_attributes_to_fields(:foo_time, time).must_equal integer
      end
    end

    context "when the column type is :timestamp" do
      let(:timestamp) { Time.current }
      let(:integer) { timestamp.to_time.to_i }

      before { User.stubs(:_protobuf_timestamp_column?).returns(true) }

      it "converts the given value to an integer" do
        User._protobuf_convert_attributes_to_fields(:foo_timestamp, timestamp).must_equal integer
      end
    end

    context "when no conversion is necessary" do
      let(:value) { "Foo" }

      it "returns the given value" do
        User._protobuf_convert_attributes_to_fields(:foo, value).must_equal value
      end
    end
  end

  describe ".field_from_record" do
    context "when the given converter is a symbol" do
      let(:callable) { lambda { |value| User.__send__(:extract_first_name) } }

      before { User.field_from_record :first_name, :extract_first_name }

      it "creates a callable method object from the converter" do
        User.expects(:extract_first_name)
        User._protobuf_field_transformers[:first_name].call(1)
      end
    end

    context "when the given converter is not callable" do
      it "raises an exception" do
        proc { User.field_from_record :name, nil }.must_raise(Protobuf::ActiveRecord::FieldTransformerError)
      end
    end

    context "when the given transformer is callable" do
      let(:callable) { lambda { |proto| nil } }

      before {
        User.stubs(:_protobuf_field_transformers).returns(Hash.new)
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
        User.allocate.must_respond_to :to_proto
      end
    end

    context "given options" do
      it "merges them with protobuf field options" do
        User._protobuf_field_options.must_equal options
      end
    end

    it "returns the protobuf message for this object" do
      User.protobuf_message.must_equal protobuf_message
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
          fields.must_equal [ :name ]
        end
      end

      context "when options has :except" do
        it "returns all except the given field(s)" do
          fields = user._filter_field_attributes(:except => :name).should
          fields.must_equal [ :guid, :email, :email_domain, :password ]
        end
      end
    end

    describe "#_filtered_fields" do
      it "returns protobuf fields" do
        user._filtered_fields.must_equal [ :guid, :name, :email, :email_domain, :password ]
      end

      context "given :deprecated => false" do
        it "filters all deprecated fields" do
          fields = user._filtered_fields(:deprecated => false).should
          fields.must_equal [ :guid, :name, :email, :password ]
        end
      end
    end

    describe "#_normalize_options" do
      let(:options) { { :only => [ :name ] } }

      context "given empty options" do
        before { User.protobuf_message(protobuf_message, options) }

        it "returns the class's protobuf field options" do
          User.allocate._normalize_options({}).must_equal options
        end
      end

      context "given options" do
        before { User.protobuf_message(protobuf_message, {}) }

        it "merges them with the class's protobuf field options" do
          normalized_options = User.allocate._normalize_options(options)
          normalized_options[:only].must_equal options[:only]
        end
      end

      context "given options with :only" do
        before { User.protobuf_message(protobuf_message, {}) }

        it "ensures that :except exists" do
          normalized_options = User.allocate._normalize_options(options)
          normalized_options[:except].must_equal []
        end
      end

      context "given options with :except" do
        let(:options) { { :except => [ :name ] } }

        before { User.protobuf_message(protobuf_message, {}) }

        it "ensures that :only exists" do
          normalized_options = User.allocate._normalize_options(options)
          normalized_options[:only].must_equal []
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
          User.stubs(:_protobuf_field_transformers).returns(transformer)
        }

        it "gets the field from the transformer" do
          user.fields_from_record.must_equal fields_from_record
        end
      end

      context "when a transformer is not defined for the field" do
        let(:fields_from_record) { { :guid => user.guid, :name => user.name, :email => user.email, :email_domain => nil, :password => nil } }

        it "returns a hash of protobuf fields that this object has getters for" do
          user.fields_from_record.must_equal fields_from_record
        end

        it "converts attributes values for protobuf messages" do
          user.stubs(:_protobuf_convert_attributes_to_fields)
          user.fields_from_record
        end
      end

      context "given options with :include" do
        it "adds the given field to the list of serialized fields" do
          fields = user.fields_from_record(:include => :token)
          fields.include?(:token).must_equal true
        end
      end
    end

    describe "#to_proto" do
      context "when a protobuf message is configured" do
        let(:proto) { protobuf_message.new(proto_hash) }
        let(:proto_hash) { { :name => "foo" } }

        before { user.stubs(:fields_from_record).returns(proto_hash) }

        it "intializes a new protobuf message with attributes from #to_proto_hash" do
          user.to_proto.must_equal proto
        end
      end

      context "when a protobuf message is not configured" do
        let(:user) { UnconfiguredUser.new }

        it "raises an exception" do
          proc { user.to_proto }.must_raise(Protobuf::ActiveRecord::MessageNotDefined)
        end
      end
    end
  end
end

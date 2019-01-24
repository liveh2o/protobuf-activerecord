require "spec_helper"

describe Protobuf::ActiveRecord::Transformation do
  let(:user) { User.new(user_attributes) }
  let(:user_attributes) { { :first_name => "foo", :last_name => "bar", :email => "foo@test.co" } }
  let(:proto_hash) { { :name => "foo bar", :email => "foo@test.co" } }
  let(:proto) { UserMessage.new(proto_hash) }

  describe "._filter_attribute_fields" do
    it "includes fields that have values" do
      attribute_fields = User._filter_attribute_fields(proto)
      expect(attribute_fields[:email]).to eq proto_hash[:email]
    end

    it "filters repeated fields" do
      attribute_fields = User._filter_attribute_fields(proto)
      expect(attribute_fields.key?(:tags)).to be false
    end

    it "includes attributes that aren't fields, but have attribute transformers" do
      allow(User).to receive(:_protobuf_attribute_transformers).and_return(:account_id => :fetch_account_id)
      attribute_fields = User._filter_attribute_fields(proto)
      expect(attribute_fields.key?(:account_id)).to be true
    end

    it "includes fields that aren't attributes, but have attribute transformers" do
      attribute_fields = User._filter_attribute_fields(proto)
      expect(attribute_fields.key?(:password)).to be true
    end
  end

  describe "._protobuf_convert_fields_to_attributes" do
    context "when the given field's corresponding column type is :date" do
      let(:date) { Date.current }
      let(:value) { date.to_time.to_i }

      before {
        allow(User).to receive(:_protobuf_date_datetime_time_or_timestamp_column?).and_return(true)
        allow(User).to receive(:_protobuf_date_column?).and_return(true)
      }

      it "converts the given value to a Date object" do
        expect(User._protobuf_convert_fields_to_attributes(:foo_date, value)).to eq date
      end
    end

    context "when given field's corresponding the column type is :datetime" do
      let(:datetime) { DateTime.current }
      let(:value) { datetime.to_i }

      before {
        allow(User).to receive(:_protobuf_date_datetime_time_or_timestamp_column?).and_return(true)
        allow(User).to receive(:_protobuf_datetime_column?).and_return(true)
      }

      it "converts the given value to a DateTime object" do
        expect(User._protobuf_convert_fields_to_attributes(:foo_datetime, value)).to be_a(DateTime)
      end

      it "converts the given value to a DateTime object of the same value" do
        expect(User._protobuf_convert_fields_to_attributes(:foo_datetime, value)).to be_within(1).of(datetime)
      end
    end

    context "when given field's corresponding the column type is :time" do
      let(:time) { Time.current }
      let(:value) { time.to_i }

      before {
        allow(User).to receive(:_protobuf_date_datetime_time_or_timestamp_column?).and_return(true)
        allow(User).to receive(:_protobuf_time_column?).and_return(true)
      }

      it "converts the given value to a Time object" do
        expect(User._protobuf_convert_fields_to_attributes(:foo_time, value)).to be_a(Time)
      end

      it "converts the given value to a Time object of the same value" do
        expect(User._protobuf_convert_fields_to_attributes(:foo_time, value)).to be_within(1).of(time)
      end
    end

    context "when given field's corresponding the column type is :timestamp" do
      let(:time) { Time.current }
      let(:value) { time.to_i }

      before {
        allow(User).to receive(:_protobuf_date_datetime_time_or_timestamp_column?).and_return(true)
        allow(User).to receive(:_protobuf_timestamp_column?).and_return(true)
      }

      it "converts the given value to a Time object" do
        expect(User._protobuf_convert_fields_to_attributes(:foo_time, value)).to be_a(Time)
      end

      it "converts the given value to a Time object of the same value" do
        expect(User._protobuf_convert_fields_to_attributes(:foo_timestamp, value)).to be_within(1).of(time)
      end
    end

    context "when no conversion is necessary" do
      let(:value) { "Foo" }

      it "returns the given value" do
        expect(User._protobuf_convert_fields_to_attributes(:foo, value)).to eq value
      end
    end
  end

  describe ".attributes_from_proto" do
    let(:callable) { lambda { |_proto| 1 } }
    let(:transformer) { ::Protobuf::ActiveRecord::Transformer.new(callable) }

    context "when a transformer is defined for the attribute" do
      it "transforms the field value" do
        attribute_fields = User.attributes_from_proto(proto)
        expect(attribute_fields[:first_name]).to eq user_attributes[:first_name]
      end
    end

    context "when a transformer is a callable that returns nil" do
      let(:callable) { lambda { |_proto| nil } }

      before do
        transformers = User._protobuf_attribute_transformers
        allow(User).to receive(:_protobuf_attribute_transformers).and_return(
          { :account_id => transformer }.merge(transformers)
        )
      end

      it "does not set the attribute" do
        attribute_fields = User.attributes_from_proto(proto)
        expect(attribute_fields).to eq user_attributes
      end
    end

    context "when the transformer has a nullify_on option" do
      let(:callable) { lambda { |_proto| nil } }
      let(:transformer) { ::Protobuf::ActiveRecord::Transformer.new(callable, :nullify_on => :account_id) }
      let(:proto_hash) { { :name => "foo bar", :email => "foo@test.co", :nullify => [:account_id] } }

      before do
        transformers = User._protobuf_attribute_transformers
        allow(User).to receive(:_protobuf_attribute_transformers).and_return(
          { :account_id => transformer }.merge(transformers)
        )
      end

      it "does not set the attribute" do
        attribute_fields = User.attributes_from_proto(proto)
        expect(attribute_fields).to include(:account_id => nil)
      end
    end

    context "when a transformer is a callable that returns a value" do
      before do
        transformers = User._protobuf_attribute_transformers
        allow(User).to receive(:_protobuf_attribute_transformers).and_return(
          { :account_id => transformer }.merge(transformers)
        )
      end

      it "sets the attribute" do
        attribute_fields = User.attributes_from_proto(proto)
        expect(attribute_fields).to eq user_attributes.merge(:account_id => 1)
      end
    end

    context "when a transformer is not defined for the attribute" do
      before {
        allow(User).to receive(:_protobuf_convert_fields_to_attributes) do |_key, value|
          value
        end
      }

      it "converts the field value" do
        attribute_fields = User.attributes_from_proto(proto)
        expect(attribute_fields).to eq user_attributes
      end
    end
  end

  describe ".attribute_from_proto" do
    context "when the given transformer is a symbol" do
      let(:callable) { lambda { |_value| User.__send__(:extract_first_name) } }

      before { User.attribute_from_proto :first_name, :extract_first_name }

      it "creates a callable method object from the converter" do
        expect(User).to receive(:extract_first_name)
        User._protobuf_attribute_transformers[:first_name].call(1)
      end
    end

    context "when the given transformer is not callable" do
      it "raises an exception" do
        expect { User.attribute_from_proto :name, nil }.to raise_exception(Protobuf::ActiveRecord::AttributeTransformerError)
      end
    end

    context "when the given transformer is callable" do
      let(:callable) { lambda { |_proto| nil } }

      before { allow(User).to receive(:_protobuf_attribute_transformers).and_return({}) }

      it "adds the given converter to the list of protobuf field transformers" do
        User.attribute_from_proto :account_id, callable
        expect(User._protobuf_attribute_transformers[:account_id].callable).to eq callable
      end
    end
  end

  describe ".convert_int64_to_date" do
    let(:date) { Date.current }
    let(:int64) { date.to_time.to_i }

    it "initializes a new Date object from the value" do
      Timecop.freeze(Date.current) do
        expect(User.convert_int64_to_date(int64)).to eq date
      end
    end
  end

  describe ".convert_int64_to_datetime" do
    let(:datetime) { DateTime.current }
    let(:int64) { datetime.to_i }

    it "initializes a new DateTime object from the value" do
      Timecop.freeze(DateTime.current) do
        expected_datetime = Time.at(datetime.to_i)
        converted_datetime = User.convert_int64_to_datetime(int64)
        expect(converted_datetime).to eq expected_datetime
      end
    end
  end

  describe ".convert_int64_to_time" do
    let(:time) { Time.current }
    let(:int64) { time.to_time.to_i }

    it "initializes a new Time object from the value" do
      Timecop.freeze(Time.current) do
        expect(User.convert_int64_to_time(int64)).to be_within(1).of(time)
      end
    end
  end

  describe "#attributes_from_proto" do
    it "gets attributes from the given protobuf message" do
      expect(User).to receive(:attributes_from_proto).with(proto)
      user.attributes_from_proto(proto)
    end
  end
end

require 'spec_helper'

describe Protoable::Convert do
  describe ".convert_int64_to_date" do
    let(:date) { Date.current }
    let(:int64) { date.to_time.to_i }

    it "initializes a new Date object from the value" do
      Timecop.freeze(Date.current) do
        User.convert_int64_to_date(int64).should eq date
      end
    end
  end

  describe ".convert_int64_to_datetime" do
    let(:datetime) { DateTime.current }
    let(:int64) { datetime.to_time.to_i }

    it "initializes a new DateTime object from the value" do
      Timecop.freeze(DateTime.current) do
        User.convert_int64_to_datetime(int64).should eq datetime
      end
    end
  end

  describe ".convert_int64_to_time" do
    let(:time) { Time.current }
    let(:int64) { time.to_time.to_i }

    it "initializes a new Time object from the value" do
      Timecop.freeze(Time.current) do
        User.convert_int64_to_time(int64).should be_within(1).of(time)
      end
    end
  end

  describe "._protobuf_convert_columns_to_fields" do
    context "when there is a column converter for the field" do
      let(:email_value) { "foo@test.co" }
      let(:email_converter) { User.method(:convert_email_to_lowercase) }

      before { User.stub(:_protobuf_column_converters).and_return({ :email => email_converter }) }

      it "calls the column converter with the given value" do
        email_converter.should_receive(:call).with(email_value)
        User._protobuf_convert_columns_to_fields(:email, email_value)
      end

      context "and it's corresponding column type has a default converter" do
        before { User.stub(:_protobuf_date_column?).and_return(true) }

        it "calls the column converter with the given value" do
          email_converter.should_receive(:call).with(email_value)
          User._protobuf_convert_columns_to_fields(:email, email_value)
        end
      end
    end

    context "when the column type is :date" do
      let(:date) { Date.current }
      let(:integer) { date.to_time.to_i }

      before { User.stub(:_protobuf_date_column?).and_return(true) }

      it "converts the given value to an integer" do
        User._protobuf_convert_columns_to_fields(:foo_date, date).should eq integer
      end
    end

    context "when the column type is :datetime" do
      let(:datetime) { DateTime.current }
      let(:integer) { datetime.to_time.to_i }

      before { User.stub(:_protobuf_datetime_column?).and_return(true) }

      it "converts the given value to an integer" do
        User._protobuf_convert_columns_to_fields(:foo_datetime, datetime).should eq integer
      end
    end

    context "when the column type is :time" do
      let(:time) { Time.current }
      let(:integer) { time.to_time.to_i }

      before { User.stub(:_protobuf_time_column?).and_return(true) }

      it "converts the given value to an integer" do
        User._protobuf_convert_columns_to_fields(:foo_time, time).should eq integer
      end
    end

    context "when the column type is :timestamp" do
      let(:timestamp) { Time.current }
      let(:integer) { timestamp.to_time.to_i }

      before { User.stub(:_protobuf_timestamp_column?).and_return(true) }

      it "converts the given value to an integer" do
        User._protobuf_convert_columns_to_fields(:foo_timestamp, timestamp).should eq integer
      end
    end

    context "when no conversion is necessary" do
      let(:value) { "Foo" }

      it "returns the given value" do
        User._protobuf_convert_columns_to_fields(:foo, value).should eq value
      end
    end
  end

  describe "._protobuf_convert_fields_to_columns" do
    let(:email_value) { "foo@test.co" }
    let(:email_converter) { lambda { |value| value } }

    before { User.stub(:_protobuf_field_converters).and_return({ :email => email_converter }) }

    it "calls the field converter with the given value" do
      email_converter.should_receive(:call).with(email_value)
      User._protobuf_convert_fields_to_columns(:email, email_value)
    end

    context "and it's corresponding column type has a default converter" do
      before { User.stub(:_protobuf_date_column?).and_return(true) }

      it "calls the field converter with the given value" do
        email_converter.should_receive(:call).with(email_value)
        User._protobuf_convert_fields_to_columns(:email, email_value)
      end
    end

    context "when the given field's corresponding column type is :date" do
      let(:date) { Date.current }
      let(:value) { date.to_time.to_i }

      before { User.stub(:_protobuf_date_column?).and_return(true) }

      it "converts the given value to a Date object" do
        User._protobuf_convert_fields_to_columns(:foo_date, value).should eq date
      end
    end

    context "when given field's corresponding the column type is :datetime" do
      let(:datetime) { DateTime.current }
      let(:value) { datetime.to_i }

      before { User.stub(:_protobuf_datetime_column?).and_return(true) }

      it "converts the given value to a DateTime object" do
        User._protobuf_convert_fields_to_columns(:foo_datetime, value).should be_a(DateTime)
      end

      it "converts the given value to a DateTime object of the same value" do
        User._protobuf_convert_fields_to_columns(:foo_datetime, value).should be_within(1).of(datetime)
      end
    end

    context "when given field's corresponding the column type is :time" do
      let(:time) { Time.current }
      let(:value) { time.to_i }

      before { User.stub(:_protobuf_time_column?).and_return(true) }

      it "converts the given value to a Time object" do
        User._protobuf_convert_fields_to_columns(:foo_time, value).should be_a(Time)
      end

      it "converts the given value to a Time object of the same value" do
        User._protobuf_convert_fields_to_columns(:foo_time, value).should be_within(1).of(time)
      end
    end

    context "when given field's corresponding the column type is :timestamp" do
      let(:time) { Time.current }
      let(:value) { time.to_i }

      before { User.stub(:_protobuf_timestamp_column?).and_return(true) }

      it "converts the given value to a Time object" do
        User._protobuf_convert_fields_to_columns(:foo_time, value).should be_a(Time)
      end

      it "converts the given value to a Time object of the same value" do
        User._protobuf_convert_fields_to_columns(:foo_timestamp, value).should be_within(1).of(time)
      end
    end

    context "when no conversion is necessary" do
      let(:value) { "Foo" }

      it "returns the given value" do
        User._protobuf_convert_fields_to_columns(:foo, value).should eq value
      end
    end
  end

  context "column type predicates" do
    before { User.stub(:_protobuf_column_types).and_return(Hash.new) }
    after { User.unstub(:_protobuf_column_types) }

    describe "._protobuf_date_column?" do
      before { User._protobuf_column_types[:date] = [ :foo_date ] }

      context "when the column type is :date" do
        it "is true" do
          User._protobuf_date_column?(:foo_date).should be_true
        end
      end

      context "when the column type is not :date" do
        it "is false" do
          User._protobuf_date_column?(:bar_date).should be_false
        end
      end
    end

    describe "._protobuf_datetime_column?" do
      before { User._protobuf_column_types[:datetime] = [ :foo_datetime ] }

      context "when the column type is :datetime" do
        it "is true" do
          User._protobuf_datetime_column?(:foo_datetime).should be_true
        end
      end

      context "when the column type is not :datetime" do
        it "is false" do
          User._protobuf_datetime_column?(:bar_datetime).should be_false
        end
      end
    end

    describe "._protobuf_time_column?" do
      before { User._protobuf_column_types[:time] = [ :foo_time ] }

      context "when the column type is :time" do
        it "is true" do
          User._protobuf_time_column?(:foo_time).should be_true
        end
      end

      context "when the column type is not :time" do
        it "is false" do
          User._protobuf_time_column?(:bar_time).should be_false
        end
      end
    end

    describe "._protobuf_timestamp_column?" do
      before { User._protobuf_column_types[:timestamp] = [ :foo_timestamp ] }

      context "when the column type is :timestamp" do
        it "is true" do
          User._protobuf_timestamp_column?(:foo_timestamp).should be_true
        end
      end

      context "when the column type is not :timestamp" do
        it "is false" do
          User._protobuf_timestamp_column?(:bar_timestamp).should be_false
        end
      end
    end
  end
end

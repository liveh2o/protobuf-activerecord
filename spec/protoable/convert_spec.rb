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

  describe "._protobuf_convert_fields_to_columns" do
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
end

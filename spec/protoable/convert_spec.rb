require 'spec_helper'

describe Protoable::Convert do
  describe ".convert_int64_to_date" do
    it "initializes a new Date object from the value"
  end

  describe ".convert_int64_to_datetime" do
    it "initializes a new DateTime object from the value"
  end

  describe ".convert_int64_to_time" do
    it "initializes a new Time object from the value"
  end

  describe "._protobuf_convert_columns_to_fields" do
    context "when there is a column converter for the field" do
      it "calls the column converter with the given value"

      context "and it's corresponding column type has a default converter" do
        it "calls the column converter with the given value"
      end
    end

    context "when the column type is :date" do
      it "converts the given value to an integer"
    end

    context "when the column type is :datetime" do
      it "converts the given value to an integer"
    end

    context "when the column type is :time" do
      it "converts the given value to an integer"
    end

    context "when the column type is :timestamp" do
      it "converts the given value to an integer"
    end

    context "when no conversion is necessary" do
      it "returns the given value"
    end
  end

  describe "._protobuf_convert_fields_to_columns" do
    context "when there is a field converter for the field" do
      it "calls the field converter with the given value"

      context "and it's corresponding column type has a default converter" do
        it "calls the field converter with the given value"
      end
    end

    context "when the given field's corresponding column type is :date" do
      it "converts the given value to a Date object"
    end

    context "when given field's corresponding the column type is :datetime" do
      it "converts the given value to a DateTime object"
    end

    context "when given field's corresponding the column type is :time" do
      it "converts the given value to a Time object"
    end

    context "when given field's corresponding the column type is :timestamp" do
      it "converts the given value to a Time object"
    end

    context "when no conversion is necessary" do
      it "returns the given value"
    end
  end

  describe "._protobuf_date_column?" do
    context "when the column type is :date" do
      it "is true"
    end

    context "when the column type is not :date" do
      it "is false"
    end
  end

  describe "._protobuf_datetime_column?" do
    context "when the column type is :datetime" do
      it "is true"
    end

    context "when the column type is not :datetime" do
      it "is false"
    end
  end

  describe "._protobuf_time_column?" do
    context "when the column type is :time" do
      it "is true"
    end

    context "when the column type is not :time" do
      it "is false"
    end
  end

  describe "._protobuf_timestamp_column?" do
    context "when the column type is :timestamp" do
      it "is true"
    end

    context "when the column type is not :timestamp" do
      it "is false"
    end
  end
end

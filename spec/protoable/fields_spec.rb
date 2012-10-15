require 'spec_helper'

describe Protoable::Fields do
  describe "._protobuf_map_columns" do
    context "when the class has a table" do
      it "maps columns by name"
      it "maps column names by column type"
    end
  end

  describe ".convert_column" do
    context "when the given converter is a hash" do
      it "determines the method using the hash's :to and :from keys"
    end

    context "when the given converter is a symbol" do
      context "when the converter is not a defined method" do
        it "determines the method using the converter as the 'from' and the column type as the 'to'"
      end

      context "when the converter is a defined method" do
        it "creates a callable method object from the converter"
      end
    end

    context "when the given converter is nil" do
      it "raises an exception"
    end

    context "when the given converter is not callable" do
      it "raises an exception"
    end

    it "adds the given converter to the list of protobuf column converters"
  end

  describe ".transform_column" do
    context "when the given converter is a symbol" do
      context "when the converter is not a defined method" do
        it "raises an exception"
      end

      context "when the converter is a defined method" do
        it "creates a callable method object from the converter"
      end
    end

    context "when the given converter is nil" do
      it "raises an exception"
    end

    context "when the given converter is not callable" do
      it "raises an exception"
    end

    it "adds the given converter to the list of protobuf field converters"
  end
end
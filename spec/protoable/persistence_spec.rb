require 'spec_helper'

describe Protoable::Persistence do
  describe "._filter_attribute_fields" do
    it "filters fields with nil values"
    it "filters repeated fields"
    it "filters fields that map to protected attributes"
    it "includes fields that have column transformers"
  end

  describe ".attributes_from_proto" do
    context "when a column transformer is defined for the field" do
      it "transforms the field value"
    end

    context "when column transformer is not defined for the field" do
      it "converts the field value"
    end

    it "is aliased as .create_hash"
    it "is aliased as .protobuf_create_hash"
  end

  describe ".create_from_proto" do
    it "initializes a new object with attributes from the given protobuf message"

    context "when a block is given" do
      it "yields to the block with attributes from the given protobuf message"
    end

    context "when the object is valid" do
      it "saves the record"

      context "when an error occurs while saving" do
        it "raises an exception"
      end
    end

    it "returns the new object"
  end

  describe "#attributes_from_proto" do
    it "gets attributes from the given protobuf message"
    it "is aliased as #update_hash"
    it "is aliased as #protobuf_update_hash"
  end

  describe "#destroy_from_proto" do
    it "destroys the object"
  end

  describe "#update_from_proto" do
    it "updates the object with attributes from the given protobuf message"

    context "when a block is given" do
      it "yields to the block with attributes from the given protobuf message"
    end

    context "when the object is valid" do
      context "when saving is successful" do
        it "saves the record"
        it "returns true"
      end

      context "when an error occurs while saving" do
        it "raises an exception"
      end
    end

    context "when the object is invalid" do
      it "returns false"
    end
  end
end
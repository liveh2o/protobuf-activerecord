require 'spec_helper'

describe Protoable::Serialization do
  describe ".convert_field" do
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

    it "adds the given converter to the list of protobuf field converters"
  end

  describe ".protobuf_message" do
    context "given a value" do
      it "sets .protobuf_fields"
      it "defines #to_proto"
      it "defines #to_proto_hash"
      it "sets @protobuf_message"
    end

    it "returns the protobuf message for this object"
  end

  describe "#protoable_attributes" do
    it "extracts attributes that map to protobuf fields"
    it "converts attributes values for protobuf messages"
  end
end

require "spec_helper"

describe ::Protobuf::ActiveRecord::Transformer do
  let(:callable) { lambda { |proto| proto.name } }
  let(:proto) { ::UserMessage.new(name: "test", nullify: ["name"]) }
  let(:options) { {} }

  subject { described_class.new(callable, options) }

  describe "#call" do
    it "calls the callable" do
      result = subject.call(proto)
      expect(result).to eq("test")
    end
  end

  describe "#nullify?" do
    context "no nullify_on set" do
      it "returns false" do
        expect(subject.nullify?(proto)).to eq(false)
      end
    end

    context "nullify_on name" do
      let(:options) { {nullify_on: :name} }

      context "invalid message" do
        let(:proto) { ::UserSearchMessage.new }

        it "returns false" do
          expect(subject.nullify?(proto)).to eq(false)
        end
      end

      context "valid message" do
        it "returns true" do
          expect(subject.nullify?(proto)).to eq(true)
        end
      end
    end
  end
end

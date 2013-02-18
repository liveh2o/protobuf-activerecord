require 'spec_helper'

describe Protoable::Fields do
  describe "._protobuf_map_columns" do
    context "when the class has a table" do
      let(:expected_column_names) {
        User.columns.inject({}) do |hash, column|
          hash[column.name.to_sym] = column
          hash
        end
      }

      let(:expected_column_types) {
        User.columns.inject({}) do |hash, column|
          hash[column.type.to_sym] ||= []
          hash[column.type.to_sym] << column.name.to_sym
          hash
        end
      }

      it "maps columns by name" do
        User._protobuf_columns.should eq expected_column_names
      end

      it "maps column names by column type" do
        User._protobuf_column_types.should eq expected_column_types
      end
    end
  end

  describe ".attribute_from_proto" do
    context "when the given transformer is a symbol" do
      let(:callable) { lambda { |value| User.__send__(:extract_first_name) } }

      before { User.attribute_from_proto :first_name, :extract_first_name }

      it "creates a callable method object from the converter" do
        User.should_receive(:extract_first_name)
        User._protobuf_attribute_transformers[:first_name].call(1)
      end
    end

    context "when the given transformer is not callable" do
      it "raises an exception" do
        expect { User.attribute_from_proto :name, nil }.to raise_exception(Protoable::AttributeTransformerError)
      end
    end

    context "when the given transformer is callable" do
      let(:callable) { lambda { |proto| nil } }

      before {
        User.stub(:_protobuf_attribute_transformers).and_return(Hash.new)
        User.attribute_from_proto :account_id, callable
      }

      it "adds the given converter to the list of protobuf field transformers" do
        User._protobuf_attribute_transformers[:account_id] = callable
      end
    end
  end
end

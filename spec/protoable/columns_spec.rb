require 'spec_helper'

describe Protoable::Columns do
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
end

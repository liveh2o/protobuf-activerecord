require 'spec_helper'

describe Protobuf::ActiveRecord::Columns do
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
        User._protobuf_columns.must_equal expected_column_names
      end

      it "maps column names by column type" do
        User._protobuf_column_types.must_equal expected_column_types
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
          User._protobuf_date_column?(:foo_date).must_equal true
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
          User._protobuf_datetime_column?(:foo_datetime).must_equal true
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
          User._protobuf_time_column?(:foo_time).must_equal true
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
          User._protobuf_timestamp_column?(:foo_timestamp).must_equal true
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

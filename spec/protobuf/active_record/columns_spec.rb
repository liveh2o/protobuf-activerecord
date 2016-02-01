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
          hash[column.type.to_sym] ||= ::Set.new
          hash[column.type.to_sym] << column.name.to_sym
          hash
        end
      }

      it "maps columns by name" do
        expect(User._protobuf_columns).to eq expected_column_names
      end

      it "maps column names by column type" do
        expected_column_types.each do |expected_column_type, value|
          expect(User._protobuf_column_types).to include expected_column_type => value
        end
      end
    end
  end

  context "column type predicates" do
    before { allow(User).to receive(:_protobuf_column_types).and_return(Hash.new) }

    describe "._protobuf_date_column?" do
      before { User._protobuf_column_types[:date] = [ :foo_date ] }

      context "when the column type is :date" do
        it "is true" do
          expect(User._protobuf_date_column?(:foo_date)).to be true
        end
      end

      context "when the column type is not :date" do
        it "is false" do
          expect(User._protobuf_date_column?(:bar_date)).to be false
        end
      end
    end

    describe "._protobuf_datetime_column?" do
      before { User._protobuf_column_types[:datetime] = [ :foo_datetime ] }

      context "when the column type is :datetime" do
        it "is true" do
          expect(User._protobuf_datetime_column?(:foo_datetime)).to be true
        end
      end

      context "when the column type is not :datetime" do
        it "is false" do
          expect(User._protobuf_datetime_column?(:bar_datetime)).to be false
        end
      end
    end

    describe "._protobuf_time_column?" do
      before { User._protobuf_column_types[:time] = [ :foo_time ] }

      context "when the column type is :time" do
        it "is true" do
          expect(User._protobuf_time_column?(:foo_time)).to be true
        end
      end

      context "when the column type is not :time" do
        it "is false" do
          expect(User._protobuf_time_column?(:bar_time)).to be false
        end
      end
    end

    describe "._protobuf_timestamp_column?" do
      before { User._protobuf_column_types[:timestamp] = [ :foo_timestamp ] }

      context "when the column type is :timestamp" do
        it "is true" do
          expect(User._protobuf_timestamp_column?(:foo_timestamp)).to be true
        end
      end

      context "when the column type is not :timestamp" do
        it "is false" do
          expect(User._protobuf_timestamp_column?(:bar_timestamp)).to be false
        end
      end
    end
  end
end

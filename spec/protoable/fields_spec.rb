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

  describe ".convert_field" do
    context "when the given converter is a hash" do
      let(:method) { User.method(:convert_base64_to_string) }

      before { User.convert_field :public_key, :from => :base64, :to => :string }

      it "determines the method using the hash's :to and :from keys" do
        User._protobuf_field_converters[:public_key].should eq method
      end
    end

    context "when the given converter is a symbol" do
      context "when the converter is not a defined method" do
        let(:callable) { User.method(:convert_base64_to_string) }

        before { User.convert_field :email, :base64 }

        it "determines the method using the converter as the 'from' and the column type as the 'to'" do
          User._protobuf_field_converters[:email].should eq callable
        end
      end

      context "when the converter is a defined method" do
        let(:callable) { User.method(:convert_email_to_lowercase) }

        before { User.convert_field :email, :convert_email_to_lowercase }

        it "creates a callable method object from the converter" do
          User._protobuf_field_converters[:email].should eq callable
        end
      end
    end

    context "when the given converter is nil" do
      it "raises an exception" do
        expect { User.convert_field :email, nil }.to raise_exception(Protoable::FieldConverterError)
      end
    end

    context "when the given converter is not callable" do
      it "raises an exception" do
        expect { User.convert_field :email, :foo }.to raise_exception(Protoable::FieldConverterError)
      end
    end

    context "when the given converter is callable" do
      let(:callable) { lambda { |value| value } }

      before { User.convert_field :email, callable }

      it "adds the given converter to list of field converters" do
        User._protobuf_field_converters[:email].should eq callable
      end
    end
  end

  describe ".transform_column" do
    context "when the given converter is a symbol" do
      context "when the converter is not a defined method" do
        it "raises an exception" do
          expect { User.transform_column :name, :foo }.to raise_exception(Protoable::ColumnTransformerError)
        end
      end

      context "when the converter is a defined method" do
        let(:callable) { User.method(:extract_first_name) }

        before { User.transform_column :first_name, :extract_first_name }

        it "creates a callable method object from the converter" do
          User._protobuf_column_transformers[:first_name].should eq callable
        end
      end
    end

    context "when the given converter is nil" do
      it "raises an exception" do
        expect { User.transform_column :name, nil }.to raise_exception(Protoable::ColumnTransformerError)
      end
    end

    context "when the given converter is not callable" do
      it "raises an exception" do
        expect { User.transform_column :name, double(:not_callable) }.to raise_exception(Protoable::ColumnTransformerError)
      end
    end

    context "when the given transformer is callable" do
      let(:callable) { lambda { |proto| nil } }

      before {
        User.stub(:_protobuf_column_transformers).and_return(Hash.new)
        User.transform_column :account_id, callable
      }

      it "adds the given converter to the list of protobuf field transformers" do
        User._protobuf_column_transformers[:account_id] = callable
      end
    end
  end
end

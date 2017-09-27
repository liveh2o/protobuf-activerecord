require 'spec_helper'

# Used to test calling #to_proto when no protobuf message is configured.
class UnconfiguredUser
  include Protobuf::ActiveRecord::Model
end

describe Protobuf::ActiveRecord::Serialization do
  let(:protobuf_message) { UserMessage }

  describe ".field_from_record" do
    context "when the given transformer is a symbol" do
      before { User.field_from_record :first_name, :extract_first_name }

      it "creates a symbol transformer from the converter" do
        expect(User._protobuf_field_symbol_transformers[:first_name]).to eq :extract_first_name
      end
    end

    context "when the given transformer is not callable" do
      it "raises an exception" do
        expect { User.field_from_record :name, nil }.to raise_exception(Protobuf::ActiveRecord::FieldTransformerError)
      end
    end

    context "when the given transformer is callable" do
      let(:callable) { lambda { |proto| nil } }

      before {
        allow(User).to receive(:_protobuf_field_transformers).and_return(Hash.new)
        User.field_from_record :account_id, callable
      }

      it "adds the given converter to the list of protobuf field transformers" do
        expect(User._protobuf_field_transformers[:account_id]).to eq(callable)
      end
    end
  end

  describe ".protobuf_message" do
    let(:options) { { :only => [] } }

    before { User.protobuf_message(protobuf_message, options) }
    after { User.protobuf_message(protobuf_message, {}) }

    context "given a value" do
      it "defines #to_proto" do
        expect(User.allocate).to respond_to :to_proto
      end
    end

    context "given options" do
      it "merges them with protobuf field options" do
        expect(User._protobuf_field_options).to eq options
      end
    end

    it "returns the protobuf message for this object" do
      expect(User.protobuf_message).to eq protobuf_message
    end
  end

  context "when protobuf_message is defined" do
    let(:attributes) { Hash.new }
    let(:user) { User.new(attributes) }

    before { User.protobuf_message(protobuf_message) }

    describe "#_filter_field_attributes" do
      context "when options has :only" do
        it "only returns the given field(s)" do
          fields = user._filter_field_attributes(:only => :name)
          expect(fields).to eq [ :name ]
        end
      end

      context "when options has :except" do
        it "returns all except the given field(s)" do
          fields = user._filter_field_attributes(:except => :name)
          expect(fields).to match_array([ :guid, :email, :email_domain, :password, :nullify, :photos ])
        end
      end
    end

    describe "#_filtered_fields" do
      it "returns protobuf fields" do
        expect(user._filtered_fields).to match_array([ :guid, :name, :email, :email_domain, :password, :nullify, :photos ])
      end

      context "given :deprecated => false" do
        it "filters all deprecated fields" do
          fields = user._filtered_fields(:deprecated => false)
          expect(fields).to match_array([ :guid, :name, :email, :password, :nullify, :photos ])
        end

        context 'and :include => :email_domain' do
          it 'includes deprecated fields that have been explicitly specified' do
            fields = user._filtered_fields(:deprecated => false, :include => :email_domain)
            expect(fields).to match_array([ :guid, :name, :email, :email_domain, :password, :nullify, :photos ])
          end
        end
      end
    end

    describe "#_normalize_options" do
      let(:options) { { :only => [ :name ] } }

      context "given empty options" do
        before { User.protobuf_message(protobuf_message, options) }

        it "returns the class's protobuf field options" do
          expect(User.allocate._normalize_options({})).to eq options
        end
      end

      context "given options" do
        before { User.protobuf_message(protobuf_message, {}) }

        it "merges them with the class's protobuf field options" do
          normalized_options = User.allocate._normalize_options(options)
          expect(normalized_options[:only]).to eq options[:only]
        end
      end

      context "given options with :only" do
        before { User.protobuf_message(protobuf_message, {}) }

        it "ensures that :except exists" do
          normalized_options = User.allocate._normalize_options(options)
          expect(normalized_options[:except]).to eq []
        end
      end

      context "given options with :except" do
        let(:options) { { :except => [ :name ] } }

        before { User.protobuf_message(protobuf_message, {}) }

        it "ensures that :only exists" do
          normalized_options = User.allocate._normalize_options(options)
          expect(normalized_options[:only]).to eq []
        end
      end
    end

    describe "#fields_from_record" do
      let(:attributes) {
        {
          :guid => "foo",
          :first_name => "bar",
          :last_name => "baz",
          :email => "foo@test.co"
        }
      }

      context "when a transformer is defined for the field" do
        it "gets the field from the transformer" do
          expect(user.fields_from_record[:email_domain]).to eq('test.co')
        end
      end

      context "given options with :include" do
        it "adds the given field to the list of serialized fields" do
          fields = user.fields_from_record(:include => :token)
          expect(fields).to include(:token)
        end
      end

      context "when a field is a collection association" do
        let(:user) { User.create(attributes) }

        it "terminates the association proxy" do
          fields = user.fields_from_record(:include => :photos)
          expect(fields[:photos]).to be_an(Array)
        end
      end
    end

    describe "#to_proto" do
      context "when a protobuf message is configured" do
        let(:proto) { protobuf_message.new(proto_hash) }
        let(:proto_hash) { { :name => "foo" } }

        before { allow(user).to receive(:fields_from_record).and_return(proto_hash) }

        it "intializes a new protobuf message with attributes from #to_proto_hash" do
          expect(user.to_proto).to eq proto
        end
      end

      context "when a protobuf message is not configured" do
        let(:user) { UnconfiguredUser.new }

        it "raises an exception" do
          expect { user.to_proto }.to raise_exception(Protobuf::ActiveRecord::MessageNotDefined)
        end
      end
    end
  end
end

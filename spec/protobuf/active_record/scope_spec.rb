require "spec_helper"

describe Protobuf::ActiveRecord::Scope do
  before do
    @field_parsers = User.instance_variable_get("@_searchable_field_parsers")
    @fields = User.instance_variable_get("@_searchable_fields")
  end

  after do
    User.instance_variable_set("@_searchable_field_parsers", @field_parsers)
    User.instance_variable_set("@_searchable_fields", @fields)
    User.instance_variable_set("@_upsert_keys", [])
  end

  describe ".search_scope" do
    let(:request) { UserSearchMessage.new(:guid => ["foo"], :email => ["foo@test.co"]) }

    before {
      allow(User).to receive(:searchable_field_parsers).and_return(:email => proc { |val| val })
    }

    it "builds scopes for searchable fields" do
      allow(User).to receive(:searchable_fields).and_return(:email => :by_email)
      expect(User.search_scope(request)).to eq User.by_email("foo@test.co")
    end

    it "is chainable" do
      expect(User.limit(1).search_scope(request).order(:email)).to eq User.limit(1).order(:email)
    end

    context "when a searchable field does not have a value" do
      let(:request) { UserSearchMessage.new(:email => ["foo@test.co"]) }

      it "doesn't build a scope from that field" do
        allow(User).to receive(:searchable_fields).and_return(:email => :by_email)
        expect(User.search_scope(request)).to eq User.by_email("foo@test.co")
      end
    end

    context "when a searchable field uses a non-existant scope" do
      let(:request) { UserSearchMessage.new(:email => ["foo@test.co"]) }

      it "raises an exception" do
        allow(User).to receive(:searchable_fields).and_return(:email => :by_hullabaloo)
        expect { User.search_scope(request) }.to raise_exception(/undefined method .*by_hullabaloo/i)
      end
    end
  end

  describe ".field_scope" do
    context "when :scope is not defined" do
      it "defines the given field as searchable using the `by_[:field]` as the scope" do
        User.field_scope :guid
        expect(User.searchable_fields[:guid]).to eq :by_guid
      end
    end

    context "when :scope is defined" do
      it "defines the given field as searchable using the given :scope" do
        User.field_scope :guid, :scope => :custom_scope
        expect(User.searchable_fields[:guid]).to eq :custom_scope
      end
    end

    context "when :parser is not defined" do
      it "doesn't define the given field as parseable" do
        User.field_scope :guid
        expect(User.searchable_field_parsers[:guid]).to eq nil
      end
    end

    context "when :parser is defined" do
      it "defines the given field as parseable using the given :parser" do
        User.field_scope :guid, :parser => :parser
        expect(User.searchable_field_parsers[:guid]).to eq :parser
      end
    end
  end

  describe ".parse_search_values" do
    it "converts single values to collections" do
      proto = UserMessage.new(:email => "the.email@test.in")

      User.field_scope :email
      expect(User.parse_search_values(proto, :email)).to eq ["the.email@test.in"]
    end

    context "when a field parser is defined" do
      before { User.field_scope :guid, :parser => parser }

      let(:proto) { UserSearchMessage.new(:guid => ["foo"]) }

      context "and the parser does not respond to :to_sym" do
        let(:parser) { double("parser") }

        it "passes the value to the parser" do
          expect(parser).to receive(:call).with(["foo"])
          User.parse_search_values(proto, :guid)
        end
      end
    end

    context "when the field is an enum" do
      it "maps values to integers" do
        TheEnum = Class.new(::Protobuf::Enum) do
          define :VALUE, 1
        end

        TheMessage = Class.new(::Protobuf::Message) do
          optional TheEnum, :the_enum_value, 1
        end

        proto = TheMessage.new(:the_enum_value => TheEnum::VALUE)
        expect(User.parse_search_values(proto, :the_enum_value)[0]).to be 1
      end
    end
  end

  describe ".upsert_key" do
    it "adds the fields to the upsert_keys" do
      ::User.field_scope(:guid)
      ::User.upsert_key(:guid)
      expect(::User.upsert_keys).to eq([[:guid]])
    end

    context "no field_scope defined" do
      it "raises an error" do
        expect { ::User.upsert_key(:foobar) }.to raise_error(::Protobuf::ActiveRecord::UpsertScopeError)
      end
    end
  end

  describe ".for_upsert" do
    let(:guid) { "USR-1" }
    let(:proto) { ::UserMessage.new(:guid => guid) }

    before do
      ::User.delete_all
      ::User.field_scope(:guid)
      ::User.upsert_key(:guid)
    end

    context "no matching upsert keys" do
      let(:proto) { ::UserMessage.new }

      it "raises an error" do
        expect { ::User.for_upsert(proto) }.to raise_error(::Protobuf::ActiveRecord::UpsertNotFoundError)
      end
    end

    context "no existing records" do
      it "returns a new record" do
        record = ::User.for_upsert(proto)
        expect(record.new_record?).to be true
      end
    end

    context "existing record" do
      before { ::User.create(:guid => guid) }
      after { ::User.delete_all }

      it "returns the existing record" do
        record = ::User.for_upsert(proto)
        expect(record.new_record?).to be false
      end
    end
  end

  describe ".upsert" do
    let(:guid) { "USR-1" }
    let(:proto) { ::UserMessage.new(:guid => guid, :email => "bar") }

    before do
      ::User.delete_all
      ::User.field_scope(:guid)
      ::User.upsert_key(:guid)
    end

    context "no existing records" do
      it "creates a new record" do
        ::User.upsert(proto)
        expect(::User.count).to eq(1)
      end
    end

    context "existing record" do
      before { ::User.create(:guid => guid, :email => "foo") }
      after { ::User.delete_all }

      it "updates the existing record" do
        ::User.upsert(proto)
        expect(::User.first.email).to eq("bar")
      end

      it "returns a user" do
        result = ::User.upsert(proto)
        expect(result).to be_a(::User)
      end
    end
  end
end

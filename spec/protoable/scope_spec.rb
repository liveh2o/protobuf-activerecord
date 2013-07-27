require 'spec_helper'

describe Protoable::Scope do
  before do
    @field_parsers = User.instance_variable_get("@_searchable_field_parsers")
    @fields = User.instance_variable_get("@_searchable_fields")
  end

  after do
    User.instance_variable_set("@_searchable_field_parsers", @field_parsers)
    User.instance_variable_set("@_searchable_fields", @fields)
  end


  describe ".search_scope" do
    let(:request) { UserSearchMessage.new(:guid => ["foo"], :email => ["foo@test.co"]) }

    before {
      User.stub(:searchable_field_parsers).and_return({ :email => proc { |val| val } })
    }

    it "builds scopes for searchable fields" do
      User.stub(:searchable_fields).and_return({ :email =>  :by_email })
      User.search_scope(request).should eq User.by_email("foo@test.co")
    end

    it "is chainable" do
      User.limit(1).search_scope(request).order(:email).should eq User.limit(1).order(:email)
    end

    context "when a searchable field does not have a value" do
      let(:request) { UserSearchMessage.new(:email => ["foo@test.co"]) }

      it "doesn't build a scope from that field" do
        User.stub(:searchable_fields).and_return({ :email =>  :by_email })
        User.search_scope(request).should eq User.by_email("foo@test.co")
      end
    end

    context "when a searchable field uses a non-existant scope" do
      let(:request) { UserSearchMessage.new(:email => ["foo@test.co"]) }

      it "raises an exception" do
        User.stub(:searchable_fields).and_return({ :email =>  :by_hullabaloo })
        expect { User.search_scope(request) }.to raise_exception(/Undefined scope :by_hullabaloo/)
      end
    end
  end

  describe ".field_scope" do
    context "when scope is passed in the old style" do
      it "defines the given field as searchable using the given scope" do
        User.field_scope :guid, :by_guid
        User.searchable_fields[:guid].should eq :by_guid
      end
    end

    context "when :scope is not defined" do
      it "defines the given field as searchable using the `by_[:field]` as the scope" do
        User.field_scope :guid
        User.searchable_fields[:guid].should eq :by_guid
      end
    end

    context "when :scope is defined" do
      it "defines the given field as searchable using the given :scope" do
        User.field_scope :guid, :scope => :custom_scope
        User.searchable_fields[:guid].should eq :custom_scope
      end
    end

    context "when :parser is not defined" do
      it "doesn't define the given field as parseable" do
        User.field_scope :guid
        User.searchable_field_parsers[:guid].should eq nil
      end
    end

    context "when :parser is defined" do
      it "defines the given field as parseable using the given :parser" do
        User.field_scope :guid, :parser => :parser
        User.searchable_field_parsers[:guid].should eq :parser
      end
    end
  end

  describe ".parse_search_values" do

    it "converts single values to collections" do
      proto = UserMessage.new(:email => "the.email@test.in")

      User.field_scope :email
      User.parse_search_values(proto, :email).should eq ["the.email@test.in"]
    end

    context "when a field parser is defined" do
      before { User.field_scope :guid, :parser => parser }

      let(:proto) { UserSearchMessage.new(:guid => ["foo"]) }

      context "and the parser responds to :to_sym" do
        let(:parser) { double('parser', :to_sym => :parser_to_sym) }

        it "passes the value to the parser" do
          User.should_receive(:parser_to_sym).with([ "foo" ])
          User.parse_search_values(proto, :guid)
        end
      end

      context "and the parser does not respond to :to_sym" do
        let(:parser) { double('parser') }

        it "passes the value to the parser" do
          parser.should_receive(:call).with(["foo"])
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
        User.parse_search_values(proto, :the_enum_value)[0].should be 1
      end
    end
  end
end

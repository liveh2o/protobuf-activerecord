require 'spec_helper'

describe Protobuf::ActiveRecord::Scope do
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
      User.stubs(:searchable_field_parsers).returns({ :email => proc { |val| val } })
    }

    it "builds scopes for searchable fields" do
      User.stubs(:searchable_fields).returns({ :email =>  :by_email })
      User.search_scope(request).must_equal User.by_email("foo@test.co")
    end

    it "is chainable" do
      User.limit(1).search_scope(request).order(:email).must_equal User.limit(1).order(:email)
    end

    context "when a searchable field does not have a value" do
      let(:request) { UserSearchMessage.new(:email => ["foo@test.co"]) }

      it "doesn't build a scope from that field" do
        User.stubs(:searchable_fields).returns({ :email =>  :by_email })
        User.search_scope(request).must_equal User.by_email("foo@test.co")
      end
    end

    context "when a searchable field uses a non-existant scope" do
      let(:request) { UserSearchMessage.new(:email => ["foo@test.co"]) }

      it "raises an exception" do
        User.stubs(:searchable_fields).returns({ :email =>  :by_hullabaloo })
        proc { User.search_scope(request) }.must_raise(/Undefined scope :by_hullabaloo/)
      end
    end
  end

  describe ".field_scope" do
    context "when :scope is not defined" do
      it "defines the given field as searchable using the `by_[:field]` as the scope" do
        User.field_scope :guid
        User.searchable_fields[:guid].must_equal :by_guid
      end
    end

    context "when :scope is defined" do
      it "defines the given field as searchable using the given :scope" do
        User.field_scope :guid, :scope => :custom_scope
        User.searchable_fields[:guid].must_equal :custom_scope
      end
    end

    context "when :parser is not defined" do
      it "doesn't define the given field as parseable" do
        User.field_scope :guid
        User.searchable_field_parsers[:guid].must_equal nil
      end
    end

    context "when :parser is defined" do
      it "defines the given field as parseable using the given :parser" do
        User.field_scope :guid, :parser => :parser
        User.searchable_field_parsers[:guid].must_equal :parser
      end
    end
  end

  describe ".parse_search_values" do

    it "converts single values to collections" do
      proto = UserMessage.new(:email => "the.email@test.in")

      User.field_scope :email
      User.parse_search_values(proto, :email).must_equal ["the.email@test.in"]
    end

    context "when a field parser is defined" do
      before { User.field_scope :guid, :parser => parser }

      let(:proto) { UserSearchMessage.new(:guid => ["foo"]) }

      context "and the parser responds to :to_sym" do
        let(:parser) { double('parser', :to_sym => :parser_to_sym) }

        it "passes the value to the parser" do
          User.expects(:parser_to_sym).with([ "foo" ])
          User.parse_search_values(proto, :guid)
        end
      end

      context "and the parser does not respond to :to_sym" do
        let(:parser) { double('parser') }

        it "passes the value to the parser" do
          parser.expects(:call).with(["foo"])
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
        User.parse_search_values(proto, :the_enum_value)[0].must_equal 1
      end
    end
  end
end

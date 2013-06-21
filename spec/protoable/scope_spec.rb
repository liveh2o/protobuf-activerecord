require 'spec_helper'

describe Protoable::Scope do
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
    before { @fields = User.instance_variable_get("@_searchable_fields") }
    after { User.instance_variable_set("@_searchable_fields", @fields) }

    it "stores the search scope in the searchable fields hash using the field as the key" do
      User.field_scope :guid, :by_guid
      User.searchable_fields[:guid].should eq :by_guid
    end
  end
end

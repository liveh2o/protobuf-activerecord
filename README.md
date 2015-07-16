# Protobuf ActiveRecord

Protobuf Active Record provides the ability to create and update Active Record objects from protobuf messages and to serialize Active Record objects to protobuf messages.

## Installation

Add this line to your application's Gemfile:

    gem 'protobuf-activerecord'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install protobuf-activerecord

## Usage

Protobuf Active Record is automatically available in any Active Record model. Once installed, you can pass protobuf messages to your user model just like you would attributes. It will take care of converting the protobuf message to attributes and continue on with Active Record's normal behavior.

### Field/Attribute mapping

Just like Active Record maps database columns to your model's attributes, Protobuf Active Record maps protobuf fields to your model's attributes.

Given a table that looks like this:

```Ruby
create_table :users do |t|
  t.string :first_name
  t.string :last_name
  t.string :email
  t.integer :account_id

  t.timestamps
end
```

and a protobuf message that looks like this:

```Ruby
class UserMessage < ::Protobuf::Message
  optional ::Protobuf::Field::StringField, :first_name, 1
  optional ::Protobuf::Field::StringField, :last_name, 2
  optional ::Protobuf::Field::StringField, :email, 3
  optional ::Protobuf::Field::IntegerField, :account_id, 4
end
```

Protobuf Active Record will map the `first_name`, `last_name`, `email`, & `account_id` columns, skipping the timestamp columns. Repeated fields and fields that are nil will not be mapped.

**Dates**

Since Protocol Buffer messages don't support sending date, time, or datetime fields, Protobuf Active Record expects date, time, and datetime fields to be sent as integers. Just like Active Record handles translating Ruby dates, times, and datetimes into the proper database column types, Protobuf Active Record will handle converting dates, times, and dateimes to and from integers mapping protobuf message fields.

Picking up our users table example again, if you wanted to add a `created_at` field to your protobuf message, if you add it as an integer field, Protobuf Active Record will handle the conversions for you:

```Ruby
class UserMessage < ::Protobuf::Message
  optional ::Protobuf::Field::StringField, :first_name, 1
  optional ::Protobuf::Field::StringField, :last_name, 2
  optional ::Protobuf::Field::StringField, :email, 3
  optional ::Protobuf::Field::IntegerField, :account_id, 4

  # Add a datetime field as an integer and Protobuf Active Record will map it for you
  optional ::Protobuf::Field::IntegerField, :created_at, 5
end
```

### Creating/Updating

Protobuf Active Record doesn't alter Active Record's normal persistence methods. It simply adds to ability to pass protobuf messages to them in place of an attributes hash.

### Serialization to protobuf

In addition to mapping protobuf message fields to Active Record objects when creating or updating records, Active Record objects can also be serialized to protobuf messages. Simply specify the protobuf message that should be used and Protobuf Active Record will take care of the rest:

```Ruby
class User < ActiveRecord::Base
  # Configures Protobuf Active Record to use the UserMessage class and adds :to_proto.
  protobuf_message :user_message
end
```

Once the desired protobuf message has been specified, a `to_proto` method will be added to the model. Calling `to_proto` will automatically convert the model to the specified protobuf message using the same attribute to field mapping it uses to create and update objects from protobuf messages.

### Choosing serializable fields

Protobuf Active Record also provides a mechanism for choosing which fields should be included when serializing objects to protobuf messages by passing additional options to `protobuf_message`:

```Ruby
class User < ActiveRecord::Base
  # Passing :only => ... configures Protobuf Active Record to only serialize the given fields
  protobuf_message :user_message, :only => [ :first_name, :last_name, :email ]
end
```

This will only include the first_name, last_name, and email fields.

Conversely, the `:except` option allows the fields that should be excluded to be specified.

```Ruby
class User < ActiveRecord::Base
  # Passing :except => ... configures Protobuf Active Record to serialize everything except the given fields
  protobuf_message :user_message, :except => [ :account_id, :created_at ]
end
```

This does pretty much the same thing, but from a different perspective.

`to_proto` also accepts these options, so you can override the class-level serializable fields on a per-instance basis:

```Ruby
user.to_proto(:only => :email) # Only the email
user.to_proto(:except => :email) # Everything except the email
user.to_proto(:include => :email) # Start with the class-level settings, but add email
```

### Serializing deprecated fields

By default, deprecated fields are included when mapping protobuf message to Active Record objects. To exclude deprecated fields, simply pass the `:deprecated` option:

```Ruby
class User < ActiveRecord::Base
  # Passing :deprecated => false configures Protobuf Active Record to exclude deprecated fields.
  protobuf_message :user_message, :deprecated => false
end
```

### Field transformers

Field transformers are used when serializing objects to protobuf messages. Regular field mapping and conversions will be handled out of the box, but for those times when fields don't map directly to attributes or custom behavior is needed, use `field_from_record` method.

`field_from_record` takes the name of the field being transformed and a method name or callable (lambda or proc). When transforming that field, it calls the given callable, passing it the object being serialized.

**Converting attributes**

```Ruby
class User < ActiveRecord::Base
  # Calls the lambda when serializing objects to protobuf messages, passing it
  # the object being serialized.
  field_from_record :status, lambda { |object_being_serlialized| # Some custom behavior }
end
```

### Attribute transformers

Protobuf Active Record handles mapping protobuf message fields to object attributes, but what happens when an attribute doesn't have a matching field? Using the `attribute_from_proto` method, you can define custom attribute transformations. Simply call `attribute_from_prot`, passing it the name of the attribute and a method name or callable (lambda or proc). When creating or updating objects, the transformer will be called and passed the protobuf message.

```Ruby
class User < ActiveRecord::Base
  # Calls the lambda when creating/updating objects, passing it the protobuf
  # message.
  attribute_from_proto :account_id, lambda { |protobuf_message| # Some custom transformation... }
end
```

### Setting attributes to nil

The protocol buffers specification does not allow for the transport of 'null' or 'nil' values for a field.  In fact, in order to keep messages small and lightweight this is desireable behavior.  Fields are that are not set to a value will not be sent over the wire, but we cannot assume given a message has an absent value for a field that we should set the our attributes to nil.

In order to solve this problem, Protobuf::ActiveRecord has a convention that tells it when to set an attribute to nil.  A message must define a repeated string field named 'nullify'.  If an attribute has the same name as an element in the 'nullify' field, this attribute will be set to nil.

Example:
```
message UserMessage {
  optional string name = 1;
  repeated string nullify = 2;
}

```
```ruby
m = UserMessage.new(:nullify => [:name])
# When Protobuf::ActiveRecord maps this message, it will set the name attribute to nil overwriting any value that is set.
```

For attribute transformers, the field name will not match the attribute name so we need to give the attribute transformer a hint to instruct it on how to nullify a given attribute.  When declaring an attribute transformer, you can specify a :nullify_on option.  This indicates for the given attribute, if the value of 'nullify_on' is present in the nullify field, set this attribute to nil.

Example:
```Ruby
class User < ActiveRecord::Base
  # When 'account_guid' is present in the nullify array, our 'account_id' attribute will be set to nil
  attribute_from_proto :account_id, :nullify_on => :account_guid do
    # transform
  end
end
```

#### Searching

Protobuf Active Record's `search_scope` method takes the protobuf message and builds ARel scopes from it.

Before you can use `search_scope`, you'll need to tell Protobuf Active Record which fields should be searchable and what scope should be used to search with that field.

Consider this protobuf message:

```
message UserSearchRequest {
  repeated string guid = 1;
  repeated string name = 2;
  repeated string email = 3;
}
```

To make the `name` field searchable, use the `field_scope` method:

```Ruby
class User < ActiveRecord::Base
  scope :by_name, lambda { |*values| where(:name => values) }

  field_scope :name, :scope => :by_name
end
```

This tells Protobuf Active Record that the name field should be searchable and that the :scope with the given name should be used to build the search scope.

`field_scope` can also be called with just a field name:

```Ruby
class User < ActiveRecord::Base
  scope :by_name, lambda { |*values| where(:name => values) }

  field_scope :name
end
```

If no scope is given, Protobuf Active Record assumes that a scope matching the given field prefixed with `by_`, in this case `by_name`.

Now that your class is configured with some searchable fields, you can use the `search_scope` method to build ARel scopes from a protobuf message.

`search_scope` is chainable just like regular ARel scopes. It takes a protobuf messages and will build search scopes from any searchable fields that have values.

Picking up our User class again:

```Ruby
# Build a search scope from the given protobuf message
User.search_scope(request)

# It's chainable too
User.limit(10).search_scope(request)
```

Protobuf Active Record also provides some aliases for the `search_scope` method in the event that you'd like something a little more descriptive: `by_fields` and `scope_from_proto` are all aliases of `search_scope`.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

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

Protobuf Active Record's functionality is contained within the `Protoable` module. To endow your Active Record models with the protoable behaviour, simply include it into your model:

```Ruby
class User < ActiveRecord::Base
  include Protoable

  # Your awesome methods...
  #
end
```

Now you can pass protobuf messages to your user model just like you would attributes. Protoable will take care of converting the protobuf message to attributes and continue on with Active Record's normal behavior.

### Field/Attribute mapping

Just like Active Record maps database columns to your model's attributes, Protoable maps protobuf fields to your model's attributes.

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

Protoable will map the `first_name`, `last_name`, `email`, & `account_id` columns, skipping the timestamp columns. Repeated fields and fields that are nil will not be mapped.

**Dates**

Since Protocol Buffer messages don't support sending date, time, or datetime fields, Protoable expects date, time, and datetime fields to be sent as integers. Just like Active Record handles translating Ruby dates, times, and datetimes into the proper database column types, Protoable will handle converting dates, times, and dateimes to and from integers mapping protobuf message fields.

Picking up our users table example again, if you wanted to add a `created_at` field to your protobuf message, if you add it as an integer field, Protoable will handle the conversions for you:

```Ruby
class UserMessage < ::Protobuf::Message
  optional ::Protobuf::Field::StringField, :first_name, 1
  optional ::Protobuf::Field::StringField, :last_name, 2
  optional ::Protobuf::Field::StringField, :email, 3
  optional ::Protobuf::Field::IntegerField, :account_id, 4

  # Add a datetime field as an integer and Protoable will map it for you
  optional ::Protobuf::Field::IntegerField, :created_at, 5
end
```

### Creating/Updating

Protoable doesn't alter Active Record's normal persistence methods. It simply adds to ability to pass protobuf messages to them in place of an attributes hash.

### Serialization to protobuf

In addition to mapping protobuf message fields to Active Record objects when creating or updating records, Protoable also provides the ability to serialize Active Record objects to protobuf messages. Simply tell Protoable the protobuf message that should be used and it will take care of the rest:

```Ruby
class User < ActiveRecord::Base
  include Protoable

  # Configures Protoable to use the UserMessage class and adds :to_proto.
  protobuf_message :user_message
end
```

Once the desired protobuf message has been specified, Protoable adds a `to_proto` method to the model. Calling `to_proto` will automatically convert the model to the specified protobuf message using the same attribute to field mapping it uses to create and update objects from protobuf messages.

### Choosing serializable fields

Protoable also provides a mechanism for choosing which fields should be included when serializing objects to protobuf messages by passing additional options to `protobuf_message`:

```Ruby
class User < ActiveRecord::Base
  include Protoable

  # Passing :only => ... configures Protoable to only serialize the given fields
  protobuf_message :user_message, :only => [ :first_name, :last_name, :email ]
end
```

This will only include the first_name, last_name, and email fields.

Conversely, the `:except` option allows the fields that should be excluded to be specified.

```Ruby
class User < ActiveRecord::Base
  include Protoable

  # Passing :except => ... configures Protoable to serialize everything except the given fields
  protobuf_message :user_message, :except => [ :account_id, :created_at ]
end
```

This does pretty much the same thing, but from a different perspective.

`to_proto` also accepts these options, so you can override the class-level serializable fields on a per-instance basis:

```Ruby
user.to_proto(:only => :email) # Only the email
user.to_proto(:except => :email) # Everthing except the email
user.to_proto(:include => :email) # Start with the class-level settings, but add email
```

### Serializing deprecated fields

By default, Protoaable includes deprecated fields when mapping protobuf message to Active Record objects. To exclude deprecated fields, simply pass the `:deprecated` option:

```Ruby
class User < ActiveRecord::Base
  include Protoable

  # Passing :deprecated => false configures Protoable to exclude deprecated fields.
  protobuf_message :user_message, :deprecated => false
end
```

### Field transformers

Field transformers are used when serializing objects to protobuf messages. Protoable will handle regular field mapping and conversions out of the box, but for those times when fields don't map directly to attributes or custom behavior is needed, Protoable provides the `field_from_record` method.

`field_from_record` takes the name of the field being transformed and a method name or callable (lambda or proc). When transforming that field, it calls the given callable, passing it the object being serialized.

**Converting attributes**

```Ruby
class User < ActiveRecord::Base
  include Protoable

  # Calls the lambda when serializing objects to protobuf messages, passing it
  # the object being serialized.
  field_from_record :status, lambda { |object_being_serlialized| # Some custom behavior }
end
```

### Attribute transformers

Protoable handles mapping protobuf message fields to object attributes, but what happens when an attribute doesn't have a matching field? Using the `attribute_from_proto` method, you can define custom attribute transformations. Simply call `attribute_from_prot`, passing it the name of the attribute and a method name or callable (lambda or proc). When creating or updating objects, Protoable will call the transformer, passing it the protobuf message.

```Ruby
class User < ActiveRecord::Base
  include Protoable

  # Calls the lambda when creating/updating objects, passing it the protobuf
  # message.
  attribute_from_proto :account_id, lambda { |protobuf_message| # Some custom transformation... }
end
```
#### Searching

Protoable's `search_scope` method takes the protobuf message and builds ARel scopes from it.

Before you can use `search_scope`, you'll need to tell Protoable which fields should be searchable and what scope should be used to search with that field.

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
  include Protoable

  scope :by_name, lambda { |*values| where(:name => values) }

  field_scope :name, :by_name
end
```

This tells Protoable that the name field should be searchable and that the scope with the given name should be used to build the search scope.

Now that your class is configured with some searchable fields, you can use the `search_scope` method to build ARel scopes from a protobuf message.

`search_scope` is chainable just like regular ARel scopes. It takes a protobuf messages and will build search scopes from any searchable fields that have values.

Picking up our User class again:

```Ruby
# Build a search scope from the given protobuf message
User.search_scope(request)

# It's chainable too
User.limit(10).search_scope(request)
```

Protoable also provides some aliases for the `search_scope` method in the event that you'd like something a little more descriptive: `by_fields` and `scope_from_proto` are all aliases of `search_scope`.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

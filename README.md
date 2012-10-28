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

**Mass-assignment**

If a model has protected attributes defined, Protoable will skip any fields that map to them. Likewise, if there are accessible attributes defined, only they will be mapped.

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

### Field & column converters

Protoable will handle regular field conversions out of the box, but for those times when custom conversions are needed, they can be defined with the `convert_field` and `convert_column` methods. Field converters are used when creating or updating objects from a protobuf message and column converters are used when serializing objects to protobuf messages.

`convert_field` and `convert_column` both take the name of the field/column being converted and a method name or callable (lambda or proc). when converting that field, calls the given callable, passing it the value of the field being converted.

**Converting fields**

```Ruby
class User < ActiveRecord::Base
  include Protoable

  # Calls :map_status_from_proto when creating/updating objects, passing it the
  # value of the status field from the protobuf message.
  def self.map_status_from_proto(field_value)
    # Some custom mapping
  end
  convert_field :status, :map_status_from_proto
end
```

**Converting columns**

```Ruby
class User < ActiveRecord::Base
  include Protoable

  # Calls the lambda when serializing objects to protobuf messages, passing it
  # the value of the status column from the database.
  convert_column :status, lambda { |column_value| column_value_.to_s }
end
```

### Column transformers

Protoable handles mapping protobuf message fields to object attributes, but what happens when an attribute doesn't have a matching field? Using the `transform_column` method, you can define custom column transformations. Simply call `transform_column`, passing it the name of the column and a method name or callable (lambda or proc). When creating or updating objects, Protoable will call the transformer, passing it the protobuf message.

```Ruby
class User < ActiveRecord::Base
  include Protoable

  # Calls the lambda when creating/updating objects, passing it the protobuf
  # message.
  transform_column :account_id, lambda { |protobuf_message| # Some custom transformation... }
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

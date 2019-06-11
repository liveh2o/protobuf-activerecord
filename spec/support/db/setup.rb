require "active_record"

ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database => "spec/test.db"
)

ActiveRecord::Base.connection.data_sources.each do |table|
  ActiveRecord::Base.connection.drop_table(table)
end

ActiveRecord::Schema.define(:version => 1) do
  create_table :photos do |t|
    t.string :url
    t.integer :user_id

    t.timestamps :null => false
  end

  create_table :users do |t|
    t.string :guid
    t.string :first_name
    t.string :last_name
    t.string :email
    t.integer :account_id

    t.timestamps :null => false
  end
end

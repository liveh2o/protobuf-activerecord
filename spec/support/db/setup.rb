require 'active_record'

ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database => "spec/test.db"
)

ActiveRecord::Base.connection.tables.each do |table|
  ActiveRecord::Base.connection.drop_table(table)
end

ActiveRecord::Schema.define(:version => 1) do
  create_table :users do |t|
    t.string    :first_name
    t.string    :last_name
    t.date      :birthday
    t.time      :notify_me_at

    t.timestamps
  end
end

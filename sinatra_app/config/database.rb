# frozen_string_literal: true

require "sqlite3"
require "sequel"

# connect to an in-memory database
DB = Sequel.sqlite

# create an items table
DB.create_table :lists do
  primary_key :id
  String :name, unique: true, null: false
end

# create a dataset from the items table
items = DB[:lists]

# populate the table
items.insert(name: "abc")
items.insert(name: "def")
items.insert(name: "ghi")

ITEMS = items

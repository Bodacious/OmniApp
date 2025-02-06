# frozen_string_literal: true
require 'bundler'
Bundler.require(:database)

require "sequel"
require 'sqlite3'

# connect to an in-memory database
DB = Sequel.sqlite(database: "../databases/#{ENV['RACK_ENV']}.db", logger: Logger.new("../log/#{ENV['RACK_ENV']}.db.log"))

table_creation_method = ENV['RACK_ENV'] == 'development' ? :create_table : :create_table!
# create an items table
DB.public_send table_creation_method, :lists do
  primary_key :id
  String :name, unique: false, null: false
  String :slug, unique: true, null: false
end unless ENV['RACK_ENV'] != 'test' && DB.table_exists?(:lists)

DB.public_send table_creation_method, :list_items do
  primary_key :id
  String :summary, null: false
  foreign_key :list_id, references: :lists, null: false
end unless ENV['RACK_ENV'] != 'test' && DB.table_exists?(:lists)

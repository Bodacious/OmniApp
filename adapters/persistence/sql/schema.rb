# frozen_string_literal: true

module Adapters
  module Persistence
    module Sql
      ##
      # The tables behind the Sequel adapters, created if they aren't
      # there yet, so booting against an existing database is harmless.
      # A database from before accounts existed gets a list_id column on
      # todos; its old rows belong to no list and so to no one.
      #
      # +position+ columns exist only to keep things in the order they
      # were added. Identity is +id+, which the domain generates.
      module Schema
        def self.create(database)
          database.create_table?(:users) do
            primary_key :position
            String :id, null: false, unique: true
            String :email, null: false, unique: true
            String :password_digest, null: false, text: true
          end

          database.create_table?(:lists) do
            primary_key :position
            String :id, null: false, unique: true
            String :owner_id, null: false, index: true
            String :name, null: false, text: true
          end

          database.create_table?(:todos) do
            primary_key :position
            String :id, null: false, unique: true
            String :list_id, index: true
            String :title, null: false, text: true
            TrueClass :completed, null: false, default: false
          end
          unless database.schema(:todos, reload: true).any? { |name, _| name == :list_id }
            database.alter_table(:todos) { add_column :list_id, String }
          end

          database.create_table?(:todo_tags) do
            String :todo_id, null: false
            String :tag, null: false
            primary_key %i[todo_id tag]
          end
        end
      end
    end
  end
end

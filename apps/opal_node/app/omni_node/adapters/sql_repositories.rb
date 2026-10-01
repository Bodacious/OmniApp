# frozen_string_literal: true

# backtick_javascript: true

require 'model/user'
require 'model/list'
require 'model/todo'
require 'ports/user_repository'
require 'ports/list_repository'
require 'ports/todo_repository'

module OmniNode
  module Adapters
    ##
    # The domain's storage ports over a SqlDriver (sql_drivers.rb). Each
    # repository's SQL is written once and runs on both node:sqlite and
    # Postgres. Rows come back as JS objects; these classes turn them
    # into the domain's User, List and Todo.
    class SqlUserRepository
      include Ports::UserRepository

      def initialize(driver)
        @driver = driver
      end

      def find(id)
        build(@driver.query('SELECT id, email, password_digest FROM users WHERE id = ?', [id.to_s]).first)
      end

      def find_by_email(email)
        build(@driver.query('SELECT id, email, password_digest FROM users WHERE email = ?', [email.to_s]).first)
      end

      def save(user)
        @driver.execute(<<~SQL, [user.id, user.email, user.password_digest])
          INSERT INTO users (id, email, password_digest) VALUES (?, ?, ?)
          ON CONFLICT (id) DO UPDATE SET email = excluded.email, password_digest = excluded.password_digest
        SQL
        user
      end

      def clear
        @driver.execute('DELETE FROM users')
      end

      private

      def build(row)
        return nil unless row

        User.new(id: `#{row}.id`, email: `#{row}.email`, password_digest: `#{row}.password_digest`)
      end
    end

    class SqlListRepository
      include Ports::ListRepository

      def initialize(driver)
        @driver = driver
      end

      def owned_by(user_id)
        @driver.query('SELECT id, owner_id, name FROM lists WHERE owner_id = ? ORDER BY position', [user_id.to_s])
               .map { |row| build(row) }
      end

      def find(id)
        row = @driver.query('SELECT id, owner_id, name FROM lists WHERE id = ?', [id.to_s]).first
        row && build(row)
      end

      def save(list)
        @driver.execute(<<~SQL, [list.id, list.owner_id, list.name])
          INSERT INTO lists (id, owner_id, name) VALUES (?, ?, ?)
          ON CONFLICT (id) DO UPDATE SET name = excluded.name
        SQL
        list
      end

      def delete(id)
        @driver.query('DELETE FROM lists WHERE id = ? RETURNING id', [id.to_s]).any?
      end

      def clear
        @driver.execute('DELETE FROM lists')
      end

      private

      def build(row)
        List.new(id: `#{row}.id`, owner_id: `#{row}.owner_id`, name: `#{row}.name`)
      end
    end

    ##
    # Tags live in their own table, one row per tag, as in the Ruby
    # adapter; saving a todo rewrites its tags in the same transaction.
    class SqlTodoRepository
      include Ports::TodoRepository

      UPSERT = <<~SQL
        INSERT INTO todos (id, list_id, title, completed) VALUES (?, ?, ?, ?)
        ON CONFLICT (id) DO UPDATE SET title = excluded.title, completed = excluded.completed
      SQL

      def initialize(driver)
        @driver = driver
      end

      def in_list(list_id)
        tags = tags_by_todo(@driver.query(<<~SQL, [list_id.to_s]))
          SELECT todo_tags.todo_id, todo_tags.tag FROM todo_tags
          JOIN todos ON todos.id = todo_tags.todo_id WHERE todos.list_id = ?
        SQL
        @driver.query('SELECT id, list_id, title, completed FROM todos WHERE list_id = ? ORDER BY position',
                      [list_id.to_s]).map { |row| build(row, tags.fetch(`#{row}.id`, [])) }
      end

      def find(id)
        row = @driver.query('SELECT id, list_id, title, completed FROM todos WHERE id = ?', [id.to_s]).first
        return nil unless row

        tags = tags_by_todo(@driver.query('SELECT todo_id, tag FROM todo_tags WHERE todo_id = ?', [id.to_s]))
        build(row, tags.fetch(id.to_s, []))
      end

      def save(todo)
        @driver.transaction do
          @driver.execute(UPSERT, [todo.id, todo.list_id, todo.title, @driver.boolean(todo.completed?)])
          @driver.execute('DELETE FROM todo_tags WHERE todo_id = ?', [todo.id])
          todo.tags.each do |tag|
            @driver.execute('INSERT INTO todo_tags (todo_id, tag) VALUES (?, ?)', [todo.id, tag.name])
          end
        end
        todo
      end

      def delete(id)
        @driver.transaction do
          @driver.execute('DELETE FROM todo_tags WHERE todo_id = ?', [id.to_s])
          @driver.query('DELETE FROM todos WHERE id = ? RETURNING id', [id.to_s]).any?
        end
      end

      def clear
        @driver.execute('DELETE FROM todo_tags')
        @driver.execute('DELETE FROM todos')
      end

      private

      # { todo id => [tag names] } from JS rows of todo_id and tag.
      def tags_by_todo(rows)
        rows.each_with_object({}) { |row, tags| (tags[`#{row}.todo_id`] ||= []) << `#{row}.tag` }
      end

      def build(row, tag_names)
        Todo.new(id: `#{row}.id`, list_id: `#{row}.list_id`, title: `#{row}.title`,
                 completed: @driver.true?(`#{row}.completed`), tags: tag_names)
      end
    end

    ##
    # The repositories on one driver, plus what the composition root
    # needs that isn't part of any port: which database this is (for
    # /health) and a way to empty it (for the test-only reset).
    class SqlStore
      attr_reader :users, :lists, :todos

      def initialize(driver)
        @driver = driver
        @users = SqlUserRepository.new(driver)
        @lists = SqlListRepository.new(driver)
        @todos = SqlTodoRepository.new(driver)
      end

      def persistence_name
        @driver.persistence_name
      end

      def clear
        @driver.transaction do
          todos.clear
          lists.clear
          users.clear
        end
      end
    end
  end
end

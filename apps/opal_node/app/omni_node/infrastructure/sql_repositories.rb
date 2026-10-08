# frozen_string_literal: true

# backtick_javascript: true

require 'model/user_repository'
require 'model/list_repository'
require 'omni_node/node'

module OmniNode
  module Infrastructure
    ##
    # New ids for the repositories: random UUIDs from node:crypto.
    module CryptoIdentity
      def next_identity
        `#{Node.require_module('node:crypto')}.randomUUID()`
      end
    end

    ##
    # The domain's UserRepository over a SqlDriver (sql_drivers.rb). Its
    # SQL is written once and runs on both node:sqlite and Postgres.
    # Rows come back as JS objects, which it turns into Users.
    class SqlUserRepository
      include ::UserRepository
      include CryptoIdentity

      # @param driver [SqlDriver]
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

      # Deletes every user: the test-only reset, not part of the repository.
      def clear
        @driver.execute('DELETE FROM users')
      end

      private

      def build(row)
        return nil unless row

        User.new(id: `#{row}.id`, email: `#{row}.email`, password_digest: `#{row}.password_digest`)
      end
    end

    ##
    # The domain's ListRepository over a SqlDriver, storing each List
    # across the same three tables as the Ruby repository: lists, a row
    # per todo, and a row per tag on a todo. #save writes the whole
    # aggregate in one transaction.
    class SqlListRepository
      include ::ListRepository
      include CryptoIdentity

      UPSERT_LIST = <<~SQL
        INSERT INTO lists (id, owner_id, name) VALUES (?, ?, ?)
        ON CONFLICT (id) DO UPDATE SET name = excluded.name
      SQL
      UPSERT_TODO = <<~SQL
        INSERT INTO todos (id, list_id, title, completed) VALUES (?, ?, ?, ?)
        ON CONFLICT (id) DO UPDATE SET title = excluded.title, completed = excluded.completed
      SQL
      DELETE_TAGS = 'DELETE FROM todo_tags WHERE todo_id IN (SELECT id FROM todos WHERE list_id = ?)'

      # @param driver [SqlDriver]
      def initialize(driver)
        @driver = driver
      end

      def find(id)
        build(@driver.query('SELECT id, owner_id, name FROM lists WHERE id = ?', [id.to_s])).first
      end

      def owned_by(user)
        build(@driver.query('SELECT id, owner_id, name FROM lists WHERE owner_id = ? ORDER BY position', [user.id]))
      end

      def save(list)
        @driver.transaction do
          @driver.execute(UPSERT_LIST, [list.id, list.owner_id, list.name])
          @driver.execute(DELETE_TAGS, [list.id])
          kept = list.todos.map(&:id)
          @driver.query('SELECT id FROM todos WHERE list_id = ?', [list.id]).each do |row|
            @driver.execute('DELETE FROM todos WHERE id = ?', [`#{row}.id`]) unless kept.include?(`#{row}.id`)
          end
          list.todos.each do |todo|
            @driver.execute(UPSERT_TODO, [todo.id, list.id, todo.title, @driver.boolean(todo.completed?)])
            todo.tags.each do |tag|
              @driver.execute('INSERT INTO todo_tags (todo_id, tag) VALUES (?, ?)', [todo.id, tag.name])
            end
          end
        end
        list
      end

      def remove(list)
        @driver.transaction do
          @driver.execute(DELETE_TAGS, [list.id])
          @driver.execute('DELETE FROM todos WHERE list_id = ?', [list.id])
          @driver.execute('DELETE FROM lists WHERE id = ?', [list.id])
        end
        nil
      end

      # Deletes every list, todo and tag: the test-only reset, not part
      # of the repository.
      def clear
        @driver.execute('DELETE FROM todo_tags')
        @driver.execute('DELETE FROM todos')
        @driver.execute('DELETE FROM lists')
      end

      private

      # Whole Lists from JS rows of lists, each with its todos and their
      # tags.
      def build(rows)
        rows.map do |row|
          list_id = `#{row}.id`
          tags = {}
          @driver.query(<<~SQL, [list_id]).each { |tag| (tags[`#{tag}.todo_id`] ||= []) << `#{tag}.tag` }
            SELECT todo_tags.todo_id, todo_tags.tag FROM todo_tags
            JOIN todos ON todos.id = todo_tags.todo_id WHERE todos.list_id = ?
          SQL
          todos = @driver.query('SELECT id, title, completed FROM todos WHERE list_id = ? ORDER BY position', [list_id])
                         .map do |todo|
            Todo.new(id: `#{todo}.id`, title: `#{todo}.title`, completed: @driver.true?(`#{todo}.completed`),
                     tags: tags.fetch(`#{todo}.id`, []))
          end
          List.new(id: list_id, owner_id: `#{row}.owner_id`, name: `#{row}.name`, todos: todos)
        end
      end
    end

    ##
    # The repositories on one driver, plus what the composition root
    # needs that no repository offers: which database this is (for
    # /health) and a way to empty it (for the test-only reset).
    class SqlStore
      attr_reader :users, :lists

      # @param driver [SqlDriver]
      def initialize(driver)
        @driver = driver
        @users = SqlUserRepository.new(driver)
        @lists = SqlListRepository.new(driver)
      end

      def persistence_name
        @driver.persistence_name
      end

      def clear
        @driver.transaction do
          lists.clear
          users.clear
        end
      end
    end
  end
end

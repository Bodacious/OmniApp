# frozen_string_literal: true

require 'securerandom'
require 'sequel'
require_relative '../../domain/model/list_repository'

module Infrastructure
  module Sql
    ##
    # The domain's ListRepository over a Sequel database. The same class
    # serves the sqlite_memory and postgres stacks: only the connection
    # handed to it differs (see Sql.store), and Schema creates the
    # tables.
    #
    # A List is stored across three tables: the list itself, a row per
    # todo, and a row per tag on a todo. The domain sees none of that:
    # it gets and gives whole Lists, and #save writes one in a single
    # transaction.
    class ListRepository
      include ::ListRepository

      # @param database [Sequel::Database]
      def initialize(database)
        @database = database
      end

      def next_identity
        SecureRandom.uuid
      end

      def find(id)
        row = lists.where(id: id.to_s).first
        row && build([row]).first
      end

      def owned_by(user)
        build(lists.where(owner_id: user.id).order(:position).all)
      end

      def save(list)
        @database.transaction do
          lists.insert_conflict(target: :id, update: { name: ::Sequel[:excluded][:name] })
               .insert(id: list.id, owner_id: list.owner_id, name: list.name)
          kept = list.todos.map(&:id)
          tags.where(todo_id: todos.where(list_id: list.id).select(:id)).delete
          todos.where(list_id: list.id).exclude(id: kept).delete
          list.todos.each do |todo|
            todos.insert_conflict(target: :id,
                                  update: { title: ::Sequel[:excluded][:title],
                                            completed: ::Sequel[:excluded][:completed] })
                 .insert(id: todo.id, list_id: list.id, title: todo.title, completed: todo.completed?)
          end
          tags.multi_insert(list.todos.flat_map { |todo| todo.tags.map { |tag| { todo_id: todo.id, tag: tag.name } } })
        end
        list
      end

      def remove(list)
        @database.transaction do
          tags.where(todo_id: todos.where(list_id: list.id).select(:id)).delete
          todos.where(list_id: list.id).delete
          lists.where(id: list.id).delete
        end
        nil
      end

      # Deletes every list, todo and tag: the test-only reset, not part
      # of the repository.
      def clear
        @database.transaction do
          tags.delete
          todos.delete
          lists.delete
        end
        nil
      end

      private

      def lists
        @database[:lists]
      end

      def todos
        @database[:todos]
      end

      def tags
        @database[:todo_tags]
      end

      # Whole Lists from their rows, loading every list's todos and tags
      # in two queries.
      def build(rows)
        todo_rows = todos.where(list_id: rows.map { |row| row[:id] }).order(:position).all
        tag_names = tags.where(todo_id: todo_rows.map { |row| row[:id] }).select_map(%i[todo_id tag])
                        .group_by(&:first).transform_values { |pairs| pairs.map(&:last) }
        todos_by_list = todo_rows.group_by { |row| row[:list_id] }
        rows.map do |row|
          List.new(id: row[:id], owner_id: row[:owner_id], name: row[:name],
                   todos: todos_by_list.fetch(row[:id], []).map do |todo|
                     Todo.new(id: todo[:id], title: todo[:title], completed: todo[:completed],
                              tags: tag_names.fetch(todo[:id], []))
                   end)
        end
      end
    end
  end
end

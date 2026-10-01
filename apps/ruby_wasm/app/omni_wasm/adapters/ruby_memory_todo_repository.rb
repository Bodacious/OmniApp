# frozen_string_literal: true

require_relative '../../../../../domain/ports/todo_repository'

module OmniWasm
  module Adapters
    ##
    # The repository port as a plain Ruby Hash, in CRuby's own memory
    # inside the WebAssembly module. No SQL anywhere: the simplest
    # adapter that satisfies the port's contract. Gone on reload.
    class RubyMemoryTodoRepository
      include Ports::TodoRepository

      def initialize(tracer: nil)
        @todos = {}
        @tracer = tracer
      end

      def persistence_name
        'ruby_memory'
      end

      def in_list(list_id)
        note('Hash#values')
        @todos.values.select { |todo| todo.list_id == list_id.to_s }
      end

      def find(id)
        note('Hash#[]')
        @todos[id]
      end

      def save(todo)
        note('Hash#store')
        @todos.store(todo.id, todo)
        todo
      end

      def delete(id)
        note('Hash#delete')
        !@todos.delete(id).nil?
      end

      # Not part of the port: lets the contract runner start clean.
      def clear
        @todos.clear
        nil
      end

      private

      def note(call)
        @tracer&.note(:adapter, call)
      end
    end
  end
end

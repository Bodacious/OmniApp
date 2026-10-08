# frozen_string_literal: true

require 'js'
require_relative '../../../../../domain/model/list_repository'

module OmniWasm
  module Infrastructure
    ##
    # The domain's ListRepository as a plain Ruby Hash, in CRuby's own
    # memory inside the WebAssembly module. No SQL anywhere: the
    # simplest storage that satisfies the contract. It keeps copies, as
    # a database would. Gone on reload.
    class RubyMemoryListRepository
      include ::ListRepository

      # @param tracer [Tracer, nil] told about each Hash call, for the inspector
      def initialize(tracer: nil)
        @lists = {}
        @tracer = tracer
      end

      def persistence_name
        'ruby_memory'
      end

      def next_identity
        @tracer&.note(:storage, 'crypto.randomUUID()')
        JS.global[:crypto].call(:randomUUID).to_s
      end

      def find(id)
        @tracer&.note(:storage, 'Hash#[]')
        stored = @lists[id.to_s]
        stored && copy_of(stored)
      end

      def owned_by(user)
        @tracer&.note(:storage, 'Hash#values')
        @lists.values.select { |list| list.owned_by?(user) }.map { |list| copy_of(list) }
      end

      def save(list)
        @tracer&.note(:storage, 'Hash#store')
        @lists.store(list.id, copy_of(list))
        list
      end

      def remove(list)
        @tracer&.note(:storage, 'Hash#delete')
        @lists.delete(list.id)
        nil
      end

      # Empties the Hash, so the contract runner starts clean; not part
      # of the repository.
      def clear
        @lists.clear
        nil
      end

      private

      # Todos never change in place, so a new List around them is a copy.
      def copy_of(list)
        List.new(id: list.id, owner_id: list.owner_id, name: list.name, todos: list.todos)
      end
    end
  end
end

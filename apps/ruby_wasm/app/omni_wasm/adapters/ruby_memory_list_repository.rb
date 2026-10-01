# frozen_string_literal: true

require_relative '../../../../../domain/ports/list_repository'

module OmniWasm
  module Adapters
    ##
    # The list repository port as a plain Ruby Hash. This app has no
    # accounts yet, so it only ever holds the one list the composition
    # root makes for the browser.
    class RubyMemoryListRepository
      include Ports::ListRepository

      def initialize
        @lists = {}
      end

      def owned_by(user_id)
        @lists.values.select { |list| list.owner_id == user_id.to_s }
      end

      def find(id)
        @lists[id.to_s]
      end

      def save(list)
        @lists.store(list.id, list)
        list
      end

      def delete(id)
        !@lists.delete(id.to_s).nil?
      end
    end
  end
end

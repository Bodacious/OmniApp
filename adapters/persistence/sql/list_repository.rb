# frozen_string_literal: true

require 'sequel'
require_relative '../../../domain/model/list'
require_relative '../../../domain/ports/list_repository'

module Adapters
  module Persistence
    module Sql
      ##
      # The list repository port over a Sequel database.
      class ListRepository
        include Ports::ListRepository

        def initialize(database)
          @lists = database[:lists]
        end

        def owned_by(user_id)
          @lists.where(owner_id: user_id.to_s).order(:position).map { |row| build(row) }
        end

        def find(id)
          row = @lists.where(id: id.to_s).first
          row && build(row)
        end

        def save(list)
          @lists.insert_conflict(target: :id, update: { name: ::Sequel[:excluded][:name] })
                .insert(id: list.id, owner_id: list.owner_id, name: list.name)
          list
        end

        def delete(id)
          @lists.where(id: id.to_s).delete.positive?
        end

        # Not part of the port: the composition root's test-only reset.
        def clear
          @lists.delete
        end

        private

        def build(row)
          List.new(id: row[:id], owner_id: row[:owner_id], name: row[:name])
        end
      end
    end
  end
end

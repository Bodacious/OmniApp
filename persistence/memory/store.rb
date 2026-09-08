# frozen_string_literal: true

module Persistence
  module Memory
    ##
    # Stores entities in a plain Hash for the life of the process. No
    # database, no gems, no setup -- and no knowledge of any
    # particular entity: which class to rehydrate is configuration.
    class Store
      def initialize(entity_class:)
        @entity_class = entity_class
        @records = {}
        @next_id = 1
      end

      def save(entity)
        unless entity.persisted?
          entity.id = next_id
          self.next_id += 1
        end
        records[entity.id] = entity.attributes.dup
        entity
      end

      def find(id)
        record = records[id]
        record && build(record)
      end

      def all
        records.values.map { |record| build(record) }
      end

      def delete(id)
        return false unless records.key?(id)

        records.delete(id)
        true
      end

      def find_by(**criteria)
        record = records.values.find { |candidate| matches?(candidate, criteria) }
        record && build(record)
      end

      def where(**criteria)
        records.values
               .select { |candidate| matches?(candidate, criteria) }
               .map { |record| build(record) }
      end

      def delete_by(**criteria)
        ids = records.select { |_id, candidate| matches?(candidate, criteria) }.keys
        return false if ids.empty?

        ids.each { |id| records.delete(id) }
        true
      end

      private

      attr_reader :entity_class, :records
      attr_accessor :next_id

      def matches?(record, criteria)
        criteria.all? { |attribute, value| record[attribute.to_sym] == value }
      end

      def build(record)
        entity_class.new(**record)
      end
    end
  end
end

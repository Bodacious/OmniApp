# frozen_string_literal: true

require_relative 'collection'

module Persistence
  module LocalStorage
    ##
    # Stores entities as JSON in the browser's window.localStorage, so
    # they survive a page reload without a server. Knows nothing about
    # any particular entity: the storage key and the class to
    # rehydrate are both configuration.
    #
    # Records come back from JSON with string keys, so criteria keys
    # are normalised to strings here rather than in every caller.
    class Store
      def initialize(entity_class:, storage_key:)
        @entity_class = entity_class
        @storage_key = storage_key
      end

      def save(entity)
        records = read
        entity.id = next_id(records) unless entity.persisted?
        records[entity.id.to_s] = entity.attributes
        write(records)
        entity
      end

      def find(id)
        record = read[id.to_s]
        record && build(record)
      end

      def all
        read.values.map { |record| build(record) }
      end

      def delete(id)
        records = read
        return false unless records.key?(id.to_s)

        records.delete(id.to_s)
        write(records)
        true
      end

      def find_by(**criteria)
        record = read.values.find { |candidate| matches?(candidate, criteria) }
        record && build(record)
      end

      def where(**criteria)
        read.values
            .select { |candidate| matches?(candidate, criteria) }
            .map { |record| build(record) }
      end

      def delete_by(**criteria)
        records = read
        ids = records.select { |_id, candidate| matches?(candidate, criteria) }.keys
        return false if ids.empty?

        ids.each { |id| records.delete(id) }
        write(records)
        true
      end

      private

      attr_reader :entity_class, :storage_key

      def matches?(record, criteria)
        criteria.all? { |attribute, value| record[attribute.to_s] == value }
      end

      def build(record)
        entity_class.new(**record)
      end

      def read
        Collection.read(storage_key)
      end

      def write(records)
        Collection.write(storage_key, records)
      end

      def next_id(records)
        records.keys.map(&:to_i).max.to_i + 1
      end
    end
  end
end

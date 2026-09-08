# frozen_string_literal: true

module Persistence
  module Sql
    ##
    # Stores entities in a relational table via a Sequel database
    # handle. Knows nothing about any particular entity: the table and
    # the class to rehydrate are both configuration, so one Store
    # serves every entity rather than one subclass per entity.
    class Store
      def initialize(database, table:, entity_class:)
        @database = database
        @table = table
        @entity_class = entity_class
      end

      def save(entity)
        if entity.persisted?
          dataset.where(id: entity.id).update(**entity.attributes.except(:id))
        else
          entity.id = dataset.insert(**entity.attributes)
        end
        entity
      end

      def find(id)
        find_by(id: id)
      end

      def all
        dataset.all.map { |record| build(record) }
      end

      def delete(id)
        delete_by(id: id)
      end

      def find_by(**criteria)
        record = dataset.where(**criteria).first
        record && build(record)
      end

      def where(**criteria)
        dataset.where(**criteria).all.map { |record| build(record) }
      end

      def delete_by(**criteria)
        dataset.where(**criteria).delete.positive?
      end

      private

      attr_reader :database, :table, :entity_class

      def dataset
        database[table]
      end

      def build(record)
        entity_class.new(**record)
      end
    end
  end
end

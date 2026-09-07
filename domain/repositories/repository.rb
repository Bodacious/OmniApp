# frozen_string_literal: true

##
# A generic Sequel-backed persistence backend for any domain entity
# with id/attributes/persisted? (see List, ListItem). Which entity
# class it loads is configuration, not hardcoded per subclass: pass
# entity_class: to the constructor (or have a subclass do so via
# super) and save/find/all/delete work for that entity.
#
# Subclassing is still how the table name is derived (from the
# subclass's own name) and how entity-specific finders like
# find_by_slug or all_for_list get added -- see ListRepository and
# ListItemRepository.
class Repository
  attr_reader :database, :entity_class
  attr_accessor :table_name

  require 'forwardable'
  extend Forwardable

  def self.table_name
    @table_name ||= begin
      singular = name.gsub('Repository', '')
                     .gsub(/([A-Z])/, '_\1')
                     .downcase
                     .sub(
                       /^_/, ''
                     )
      "#{singular}s"
    end
  end

  def_delegators :data_source, :insert

  def initialize(database_connection, entity_class:)
    @database = database_connection
    @table_name = self.class.table_name
    @entity_class = entity_class
  end

  def data_source
    database[table_name.to_sym]
  end

  def save(entity)
    if entity.persisted?
      data_source.where(id: entity.id).update(**entity.attributes.except(:id))
    else
      entity.id = insert(**entity.attributes)
    end
    entity
  end

  def find(id)
    result = data_source.where(id: id).first
    result && entity_class.new(**result)
  end

  def all
    data_source.all.map { entity_class.new(**_1) }
  end

  def delete(id)
    data_source.where(id: id).delete.positive?
  end
end

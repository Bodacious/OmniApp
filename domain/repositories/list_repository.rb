# frozen_string_literal: true

require_relative 'repository'
require 'models/list'

class ListRepository < Repository
  def initialize(database_connection)
    super(database_connection, entity_class: List)
  end

  def find_by_slug(slug)
    result = data_source.where(slug: slug).first
    result && entity_class.new(**result)
  end

  def delete_by_slug(slug)
    data_source.where(slug: slug).delete.positive?
  end
end

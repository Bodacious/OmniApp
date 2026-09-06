# frozen_string_literal: true

require_relative 'repository'
require 'models/list'

class ListRepository < Repository
  def save(list)
    if list.persisted?
      data_source.where(id: list.id).update(**list.attributes.except(:id))
    else
      list.id = insert(**list.attributes)
    end
    list
  end

  def find(id)
    result = data_source.select(:id, :name, :slug).where(id: id).first
    result && List.new(**result)
  end

  def find_by_slug(slug)
    result = data_source.select(:id, :name, :slug).where(slug: slug).first
    result && List.new(**result)
  end

  def delete_by_slug(slug)
    data_source.where(slug: slug).delete.positive?
  end

  def all
    data_source.all.map { List.new(**_1) }
  end
end

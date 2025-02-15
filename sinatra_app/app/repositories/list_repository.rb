require_relative "repository"
require "models/list"

class ListRepository < Repository
  def save(list)
    if list.persisted?
      insert(**list.attributes)
    else
      list.id = insert(**list.attributes)
    end
    list
  end

  def find(id)
    result = data_source.select(:id, :name, :slug).where(id: id).first
    List.new(**result.to_h)
  end

  def find_by_slug(slug)
    result = data_source.select(:id, :name, :slug).where(slug: slug).first
    List.new(**result.to_h)
  end

  def delete_by_slug(slug)
    data_source.where(slug: slug).delete
  end

  def all
    data_source.all.map { List.new(**_1) }
  end
end

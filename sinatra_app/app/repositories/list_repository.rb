require_relative "repository"
require "models/list"
class ListRepository < Repository
  def create(**attributes)
    list = List.new(**attributes)
    list.id = 1
    list
  end

  def find(id)
    list = List.new(**{})
    list.id = id
    list.name = "list-name"
    list
  end
end

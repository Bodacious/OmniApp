require 'models/list'

class ListRepository
  def create(**attributes)
    list = List.new(**attributes)
    list.id = 1
    list
  end

  def find(id)
    list = List.new(**{})
    list.id = id
    list
  end
end

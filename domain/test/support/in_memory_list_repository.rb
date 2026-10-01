# frozen_string_literal: true

require 'ports/list_repository'

##
# A test double for the list repository port.
class InMemoryListRepository
  include Ports::ListRepository

  def initialize
    @lists = {}
  end

  def owned_by(user_id)
    @lists.values.select { |list| list.owner_id == user_id }
  end

  def find(id)
    @lists[id]
  end

  def save(list)
    @lists[list.id] = list
    list
  end

  def delete(id)
    !@lists.delete(id).nil?
  end
end

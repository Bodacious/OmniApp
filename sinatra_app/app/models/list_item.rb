# frozen_string_literal: true

class ListItem
  attr_accessor :id, :name, :list_id

  def initialize(attributes = {})
    @id = attributes["id"]
    @name = attributes["name"]
    @list_id = attributes["list_id"]
  end

  def persisted?
    !id.nil?
  end
end

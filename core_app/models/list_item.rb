# frozen_string_literal: true

class ListItem
  def initialize(attributes = {})
    @name = attributes["name"]
    @purchased = attributes["purchased"]
  end
end

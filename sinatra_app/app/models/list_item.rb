# frozen_string_literal: true

class ListItem
  attr_accessor :id, :summary, :list_id

  def initialize(attributes = {})
    @id = attributes[:id]
    @summary = attributes[:summary]
    @list_id = attributes[:list_id]
  end

  def persisted?
    !id.nil?
  end
end

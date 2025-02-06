# frozen_string_literal: true

class ListItem

  using CoreExtensions::Hash::SymbolizeKeys

  attr_reader :attributes

  def initialize(attributes = {})
    @attributes = attributes.symbolize_keys
  end

  def persisted?
    !id.nil?
  end

  def id
    attributes[:id]
  end

  def summary
    attributes[:summary]
  end
end

# frozen_string_literal: true

class ListItem
  require_relative '../lib/core_extensions/hash'

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

  def list_id=(value)
    attributes[:list_id] = value
  end

  def list_id
    attributes[:list_id]
  end
end

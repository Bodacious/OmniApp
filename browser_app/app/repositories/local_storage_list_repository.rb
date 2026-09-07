# frozen_string_literal: true

require 'models/list'
require_relative '../local_storage_repository'

##
# A List persistence backend backed by the browser's localStorage.
# Satisfies the same contract as any other List repository (see
# ListRepositoryContract in domain/test/support): save, find,
# find_by_slug, all, delete_by_slug.
class LocalStorageListRepository < LocalStorageRepository
  def initialize
    super(entity_class: List, storage_key: 'omniapp.lists')
  end

  def find_by_slug(slug)
    record = read.values.find { |attributes| attributes['slug'] == slug }
    record && entity_class.new(**record)
  end

  def delete_by_slug(slug)
    records = read
    id = records.find { |_id, attributes| attributes['slug'] == slug }&.first
    return false unless id

    records.delete(id)
    write(records)
    true
  end
end

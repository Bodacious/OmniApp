# frozen_string_literal: true

# backtick_javascript: true

require 'models/list'
require 'models/list_item'
require 'repositories/list_repository'
require 'repositories/list_item_repository'
require 'persistence/memory/store'
require_relative 'persistence/local_storage/store'
require_relative 'ui/lists_app'

# The composition root: the only place that knows both which entities
# exist and which backends can store them. The UI below is handed a
# set of named backends and never learns what's behind any of them.
BACKENDS = {
  'memory' => lambda {
    [ListRepository.new(Persistence::Memory::Store.new(entity_class: List)),
     ListItemRepository.new(Persistence::Memory::Store.new(entity_class: ListItem))]
  },
  'local_storage' => lambda {
    [ListRepository.new(Persistence::LocalStorage::Store.new(entity_class: List,
                                                             storage_key: 'omniapp.lists')),
     ListItemRepository.new(Persistence::LocalStorage::Store.new(entity_class: ListItem,
                                                                 storage_key: 'omniapp.list_items'))]
  }
}.freeze

start = proc { ListsApp.new(BACKENDS).start }
`document.addEventListener('DOMContentLoaded', #{start.to_n})`

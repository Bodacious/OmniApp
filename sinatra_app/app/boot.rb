# frozen_string_literal: true

# Loads the core classes of tha application, without establishing the routes, actions etc.
$LOAD_PATH << File.expand_path('../..', __dir__)
$LOAD_PATH << File.expand_path('../../domain', __dir__)

require_relative '../../domain/lib/core_extensions'
require 'models/list'
require 'models/list_item'
require 'repositories/list_repository'
require 'repositories/list_item_repository'
require 'persistence/memory/store'
require 'persistence/sql/database'
require 'persistence/sql/store'

ENVIRONMENT = ENV.fetch('RACK_ENV', 'development')

DATABASE = Persistence::Sql::Database.connect(ENVIRONMENT)
Persistence::Sql::Database.create_schema!(DATABASE, reset: ENVIRONMENT == 'test')

# The composition root: the only place that knows both which entities
# exist and which backend stores them. Everything downstream -- the
# repositories, the routes, the views -- is identical either way.
list_store, list_item_store =
  if ENV['PERSISTENCE_BACKEND'] == 'memory'
    [Persistence::Memory::Store.new(entity_class: List),
     Persistence::Memory::Store.new(entity_class: ListItem)]
  else
    [Persistence::Sql::Store.new(DATABASE, table: :lists, entity_class: List),
     Persistence::Sql::Store.new(DATABASE, table: :list_items, entity_class: ListItem)]
  end

LIST_REPOSITORY = ListRepository.new(list_store)
LIST_ITEM_REPOSITORY = ListItemRepository.new(list_item_store)

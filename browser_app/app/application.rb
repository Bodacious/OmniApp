# frozen_string_literal: true

# backtick_javascript: true

require 'models/list'
require 'models/list_item'
require 'repositories/in_memory_list_repository'
require 'repositories/in_memory_list_item_repository'
require_relative 'repositories/local_storage_list_repository'
require_relative 'repositories/local_storage_list_item_repository'
require_relative 'ui/lists_app'

start = proc { ListsApp.new.start }
`document.addEventListener('DOMContentLoaded', #{start.to_n})`

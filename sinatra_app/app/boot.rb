# frozen_string_literal: true

# Loads the core classes of tha application, without establishing the routes, actions etc.
$LOAD_PATH << File.expand_path('../../domain', __dir__)
puts $LOAD_PATH
require_relative '../../domain/lib/core_extensions'
require_relative '../config/database'
require_relative 'repositories/list_repository'
require_relative 'repositories/list_item_repository'
require 'repositories/in_memory_list_repository'

# The List persistence backend is chosen at boot via LIST_REPOSITORY_BACKEND,
# demonstrating that the app is agnostic to which one is plugged in.
LIST_REPOSITORY = if ENV['LIST_REPOSITORY_BACKEND'] == 'memory'
                    InMemoryListRepository.new
                  else
                    ListRepository.new(DB)
                  end

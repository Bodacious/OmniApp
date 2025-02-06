# Loads the core classes of tha application, without establishing the routes, actions etc.
require_relative '../lib/core_extensions'
require_relative "../config/database"
require_relative "repositories/list_repository"
require_relative "repositories/list_item_repository"

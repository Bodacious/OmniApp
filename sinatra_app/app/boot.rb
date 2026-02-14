# frozen_string_literal: true

# Loads the core classes of tha application, without establishing the routes, actions etc.
$LOAD_PATH << File.expand_path('../../domain', __dir__)
puts $LOAD_PATH
require_relative '../../domain/lib/core_extensions'
require_relative '../config/database'
require_relative 'repositories/list_repository'
require_relative 'repositories/list_item_repository'

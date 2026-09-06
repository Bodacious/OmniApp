# frozen_string_literal: true

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

$LOAD_PATH << File.expand_path('../../domain', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'bootsnap/setup' # Speed up boot time by caching expensive operations.

require 'repositories/database'

require 'repositories/list_repository'

require 'repositories/list_item_repository'

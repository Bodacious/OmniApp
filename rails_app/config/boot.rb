# frozen_string_literal: true

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

$LOAD_PATH << File.expand_path('../../domain', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'bootsnap/setup' # Speed up boot time by caching expensive operations.

require_relative '../../sinatra_app/config/database'

require_relative '../../sinatra_app/app/repositories/list_repository'

require_relative '../../sinatra_app/app/repositories/list_item_repository'

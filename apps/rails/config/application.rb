# frozen_string_literal: true

require 'securerandom'
require 'rails'
# Only the parts of Rails an HTTP app layer needs. No Active Record:
# persistence comes from the same adapters the Sinatra app uses.
require 'action_controller/railtie'
require 'action_view/railtie'
require 'slim-rails'
require_relative '../../../lib/omni/composition_root'

module OmniRails
  class Application < Rails::Application
    config.load_defaults 8.0
    config.root = File.expand_path('..', __dir__)

    config.eager_load = true
    config.enable_reloading = false
    config.consider_all_requests_local = false
    config.hosts.clear
    config.public_file_server.enabled = false
    config.logger = ActiveSupport::TaggedLogging.logger($stdout)
    config.log_level = :info

    # Forms carry Rails' CSRF token via the templates' hidden_fields.
    config.action_controller.allow_forgery_protection = true
    config.secret_key_base = ENV.fetch('SECRET_KEY_BASE') { SecureRandom.hex(64) }
  end
end

# frozen_string_literal: true

# test/test_helper.rb
ENV['RAILS_ENV'] ||= 'test'

require_relative '../config/environment'
require 'rails/test_help'

# Optional quality-of-life defaults
require 'minitest/reporters'
Minitest::Reporters.use!(Minitest::Reporters::DefaultReporter.new(color: true))

# Ensure backtraces are sane
Rails.backtrace_cleaner.remove_silencers!

# Load support files
Rails.root.glob('test/support/**/*.rb').each { |f| require f }

# --- Capybara / Selenium (your config) ---

require 'capybara/minitest'
require 'selenium-webdriver'
require 'capybara/dsl'

Capybara.app = Rack::Builder.app do
  use Rack::CommonLogger
  use Rack::MethodOverride
  run Rails.application
end

Capybara.server = :puma, { Silent: true } # Ensures Puma is used for tests

# Headless Chrome options
def headless_chrome_options
  Selenium::WebDriver::Chrome::Options.new.tap do |opts|
    opts.add_argument('--headless')
    opts.add_argument('--disable-gpu')
    opts.add_argument('--no-sandbox')
    opts.add_argument('--window-size=1280,800')
  end
end

Capybara.register_driver :selenium_chrome_headless do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: headless_chrome_options)
end

##
# Save test screenshots in repo/tmp/screenshots
Capybara.save_path = File.expand_path('../../tmp/screenshots', __dir__)

Capybara.default_driver = :selenium_chrome_headless
Capybara.javascript_driver = :selenium_chrome_headless
Capybara.server_port = 3000
Capybara.app_host = "http://127.0.0.1:#{Capybara.server_port}"

# Selenium::WebDriver.logger.level = :debug
# Selenium::WebDriver.logger.output = "../log/selenium.log"

require_relative '../../domain/test/support/database_truncation'
Minitest::Test.include(DatabaseTruncation)

# If you want Capybara DSL available everywhere, keep this.
# Otherwise prefer including it only in system/integration tests.
Minitest::Test.include(Capybara::DSL)

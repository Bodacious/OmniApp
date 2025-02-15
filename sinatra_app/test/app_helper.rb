require_relative "test_helper"
require "capybara/minitest"
require "selenium-webdriver"
require "capybara/dsl"

# Sinatra app setup for Capybara
require File.expand_path("../app/main", __dir__)

Capybara.app = Rack::Builder.app do |app|
  use Rack::CommonLogger
  use Rack::MethodOverride
  run OmniApp
end

Capybara.server = :puma, { Silent: true } # Ensures Puma is used for tests

Capybara.register_driver :selenium_chrome_headless do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: headless_chrome_options)
end

##
# Save test screenshots in repo/tmp/screenshots
Capybara.save_path = File.expand_path("../../../tmp/screenshots", __FILE__)

# Headless Chrome options
def headless_chrome_options
  Selenium::WebDriver::Chrome::Options.new.tap do |opts|
    opts.add_argument("--headless")
    opts.add_argument("--disable-gpu")
    opts.add_argument("--no-sandbox")
    opts.add_argument("--window-size=1280,800")
  end
end

Capybara.default_driver = :selenium_chrome_headless
Capybara.javascript_driver = :selenium_chrome_headless
Capybara.server_port = 4567

Capybara.app_host = "http://127.0.0.1:#{Capybara.server_port}"

# Selenium::WebDriver.logger.level = :debug
# Selenium::WebDriver.logger.output = '../log/selenium.log'

require 'support/database_truncation'
Minitest::Test.include(DatabaseTruncation)
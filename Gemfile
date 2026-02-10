# frozen_string_literal: true

source "https://rubygems.org"

ruby file: "./.ruby-version"

gem "rake", "~> 13.2"
gem "sinatra", "~> 4.1"
gem "puma", "~> 6.5"

group :sinatra, optional: true do
  gem "rack-unreloader", "~> 2.1"
  gem "rackup", "~> 2.2"
  gem "slim", "~> 5.2"
  gem "nio4r", "~> 2.7"
  gem "sinatra-reloader", "~> 1.0", require: "sinatra/reloader"
  gem "sequel", "~> 5.89"
  gem "sqlite3", "~> 2.5"
end

group :test do
  gem "capybara", "~> 3.40"
  gem "minitest", "~> 5.25"
  gem "difftastic"
  gem "launchy", "~> 3.1"
  gem "minitest-difftastic", "~> 0.1"
  gem "mocha", "~> 2.7"
  gem "mutex_m", "~> 0.3"
  gem "rack-test", "~> 2.2"
  gem "selenium-webdriver", "~> 4.28"
end

group :housekeeping do
  gem "pessimize", "~> 0.5"
  gem "rubocop", "~> 1.70"
end

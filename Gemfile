# frozen_string_literal: true

source 'https://rubygems.org'

ruby file: './.ruby-version'

gem 'rake', '~> 13.2'

gem 'puma', '~> 6.5'

group :rails do
  # Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
  gem 'rails', '~> 8.0.1'
  # Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
  gem 'importmap-rails'
  # Build JSON APIs with ease [https://github.com/rails/jbuilder]
  gem 'jbuilder'

  # Windows does not include zoneinfo files, so bundle the tzinfo-data gem
  gem 'tzinfo-data', platforms: %i[windows jruby]

  # Reduces boot times through caching; required in config/boot.rb
  gem 'bootsnap', require: false

  # Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
  gem 'thruster', require: false

  gem 'slim-rails'
end

group :sinatra do
  gem 'nio4r', '~> 2.7'
  gem 'rack-unreloader', '~> 2.1'
  gem 'rackup', '~> 2.2'
  gem 'sequel', '~> 5.89'
  gem 'sinatra', '~> 4.1'
  gem 'sinatra-reloader', '~> 1.0', require: 'sinatra/reloader'
  gem 'slim', '~> 5.2'
  gem 'sqlite3', '~> 2.5'
end

group :test do
  gem 'capybara', '~> 3.40'
  gem 'difftastic'
  gem 'launchy', '~> 3.1'
  gem 'minitest', '~> 5.25'
  gem 'minitest-difftastic', '~> 0.1'
  gem 'mocha', '~> 2.7'
  gem 'mutex_m', '~> 0.3'
  gem 'rack-test', '~> 2.2'
  gem 'selenium-webdriver', '~> 4.28'
end

group :housekeeping do
  gem 'pessimize', '~> 0.5'
  gem 'rubocop', '~> 1.70'
  gem 'rubocop-capybara'
  gem 'rubocop-minitest'
  gem 'rubocop-rails'
  gem 'rubocop-rake'
  gem 'rubocop-sequel'
end

gem 'minitest-reporters', '~> 1.7'

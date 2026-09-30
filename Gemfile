# frozen_string_literal: true

source 'https://rubygems.org'

ruby file: '.ruby-version'

# The domain (domain/) needs no gems at all.

gem 'puma', '~> 8.0'
gem 'rake', '~> 13.2'

# The Ruby persistence adapters (adapters/persistence/), shared by the
# Rails and Sinatra apps.
group :persistence do
  gem 'pg', '~> 1.6'
  gem 'sequel', '~> 5.89'
  gem 'sqlite3', '~> 2.5'
end

# apps/rails: only the parts of Rails an HTTP app layer needs. No
# Active Record; persistence comes from adapters/persistence/.
group :rails do
  gem 'actionpack', '~> 8.0.1'
  gem 'actionview', '~> 8.0.1'
  gem 'railties', '~> 8.0.1'
  gem 'slim-rails', '~> 4.0'
end

# apps/sinatra. Slim is also what renders adapters/interface/slim/.
group :sinatra do
  gem 'sinatra', '~> 4.1'
  gem 'slim', '~> 5.2'
end

# apps/opal_node, and bin/omni-domain-check's Opal compile of domain/.
group :opal do
  gem 'opal', '~> 1.8'
end

group :test do
  gem 'capybara', '~> 3.40'
  gem 'cucumber', '~> 11.1', require: false
  gem 'cuprite', '~> 0.17', require: false
  gem 'minitest', '~> 5.25'
  gem 'rspec-expectations', '~> 3.13', require: false
end

group :housekeeping do
  gem 'pessimize', '~> 0.5'
  gem 'rubocop', '~> 1.70', require: false
  gem 'rubocop-capybara', require: false
  gem 'rubocop-minitest', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rake', require: false
  gem 'rubocop-sequel', require: false
end

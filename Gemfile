# frozen_string_literal: true

source "https://rubygems.org"

ruby file: "./.ruby-version"

gem "rake", "~> 13.2"

group :development do
  gem 'rubocop'
end

group :test do
  gem "minitest", "~> 5.25"
  gem "mutex_m", "~> 0.3.0"
  gem "simplecov", require: false
end

group :ci do
  gem "rdoc", "~> 6.12", require: false
  gem "rubycritic", require: false
end

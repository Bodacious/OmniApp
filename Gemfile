# frozen_string_literal: true

source "https://rubygems.org"

ruby file: "./.ruby-version"

gem "rake", "~> 13.2"

group :development do
  gem "rubocop"
  gem "rubocop-minitest", "~> 0.37.1"
  gem "rubocop-rake", "~> 0.7.1"
end

group :test do
  gem "minitest", "~> 5.25"
  gem "simplecov", require: false
  gem "mocha", "~> 2.7"
end

group :ci do
  gem "rdoc", "~> 6.12", require: false
  gem "rubycritic", require: false
  gem "rorvswild_theme_rdoc", "~> 0.2", require: false
end





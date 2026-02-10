ENV['RACK_ENV'] = 'test'

require 'bundler'
Bundler.require(:default, :test, :sinatra)

require 'app/main'
require "minitest/autorun"
require "mocha/minitest"

require 'support/assertions'
Minitest::Test.include(Assertions)
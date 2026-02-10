ENV['RACK_ENV'] = 'test'

require 'bundler'
Bundler.require(:default, :test)

require "minitest/autorun"
require "mocha/minitest"

require 'support/assertions'
Minitest::Test.include(Assertions)
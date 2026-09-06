# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require_relative '../boot'

require 'minitest/autorun'
require 'mocha/minitest'

require 'support/assertions'
Minitest::Test.include(Assertions)

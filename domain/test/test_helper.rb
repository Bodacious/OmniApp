# frozen_string_literal: true

# The domain's tests, and the repository contracts run against each
# implementation. The domain itself needs no gems; its tests use
# ActiveSupport's test case and Mocha.
require 'active_support'
require 'active_support/test_case'
require 'minitest/autorun'
require 'mocha/minitest'

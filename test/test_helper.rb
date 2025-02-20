require "bundler/setup"
Bundler.setup(:test)

require "minitest/autorun"

require "simplecov"
SimpleCov.start do
  coverage_dir "doc/coverage"
end

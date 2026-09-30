# frozen_string_literal: true

require 'rake/testtask'

# Unit tests: the domain, and the repository contract against the Ruby
# persistence adapters. (The end-to-end specs are Cucumber, run per
# stack by bin/omni-test.)
Rake::TestTask.new(:test) do |t|
  t.libs = %w[. domain domain/test]
  t.pattern = '{domain,adapters}/test/**/*_test.rb'
  t.warning = false
end

task default: :test

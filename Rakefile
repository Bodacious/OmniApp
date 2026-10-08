# frozen_string_literal: true

require 'rake/testtask'

# Unit tests: the domain, the repository contracts against the Ruby
# infrastructure, and the architecture's own rules. (The end-to-end
# specs are Cucumber, run per stack by bin/omni-test.)
Rake::TestTask.new(:test) do |t|
  t.libs = %w[. domain domain/test]
  t.pattern = '{domain/test,infrastructure/test,test}/**/*_test.rb'
  t.warning = false
end

task default: :test

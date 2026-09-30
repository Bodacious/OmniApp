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

# The list-based apps that predate the stack matrix (sinatra_app/,
# rails_app/), selected with APP_NAME as before.
Rake::TestTask.new(:legacy_test) do |t|
  app_dir = "#{ENV.fetch('APP_NAME', 'sinatra')}_app"
  t.libs = %W[. domain domain/lib domain/test #{app_dir} #{app_dir}/test]
  t.pattern = "{domain/test,#{app_dir}/test}/**/*_test.rb"
  t.warning = false
end

task default: :test

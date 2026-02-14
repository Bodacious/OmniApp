# frozen_string_literal: true

$LOAD_PATH << File.expand_path("./domain", __dir__)
require "rake/testtask"

app_dir = "#{ENV.fetch("APP_NAME", "sinatra")}_app"

Rake::TestTask.new(:test) do |t|
  t.libs << %w[domain domain/lib domain/test]
  t.libs << %W[#{app_dir} #{app_dir}/test]

  # Only pick tests from these two directories
  t.pattern = "{domain/test,#{app_dir}/test}/**/*_test.rb"

  t.verbose = true
  t.warning = false
end

task default: :test

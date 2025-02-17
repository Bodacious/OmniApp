require "minitest/test_task"

Minitest::TestTask.create # named test, sensible defaults

# or more explicitly:

Minitest::TestTask.create(:test) do |t|
  t.libs << "domain"
  t.libs << "test"
  t.warning = false
  t.test_globs = ["test/**/*_test.rb"]
end

task :default => :test
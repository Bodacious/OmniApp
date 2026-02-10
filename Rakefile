# Rakefile
# Runs Minitest tests under domain/test

require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.pattern = "./domain/test/**/*_test.rb"
  t.libs << "./domain"
  t.libs << "./domain/lib"
  t.libs << "./domain/test"
  t.verbose = true
  t.warning = false
end

task default: :test

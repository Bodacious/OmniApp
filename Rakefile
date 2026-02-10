# Rakefile
# Runs Minitest tests under domain/test

require "rake/testtask"

app_dir = ENV.fetch('APP_NAME', 'sinatra') + "_app"

Rake::TestTask.new(:test) do |t|
  t.pattern = "**/*_test.rb"
  t.libs << %W[domain domain/lib domain/test]
  t.libs << %W[#{app_dir} #{app_dir}/test]

  t.verbose = true
  t.warning = false
end

task default: :test

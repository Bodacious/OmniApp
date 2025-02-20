require "bundler"
Bundler.require(:ci, :test)

require "minitest/test_task"

Minitest::TestTask.create

Minitest::TestTask.create(:test) do |t|
  t.libs << "domain"
  t.libs << "test"
  t.warning = false
  t.test_globs = ["test/**/*_test.rb"]
end

require "rubycritic/rake_task"
RubyCritic::RakeTask.new do |task|
  # Glob pattern to match source files. Defaults to FileList['.'].
  task.paths = FileList["domain/**/*.rb"]

  # You can pass all the options here in that are shown by "rubycritic -h" except for
  # "-p / --path" since that is set separately. Defaults to ''.
  task.options = "--format html --no-browser --path=./doc/rubycritic"

  # Defaults to false
  task.verbose = true

  # Fail the Rake task if RubyCritic doesn't pass. Defaults to true
  task.fail_on_error = true
end

require "rdoc/task"
RDoc::Task.new do |rdoc|
  rdoc.main = "README.md"
  rdoc.rdoc_files.include("README.md", "domain/**/*.rb")
  rdoc.rdoc_dir = "doc"
  rdoc.title = "the OmniApp"
end
task build_docs: %i[rdoc rubycritic]
task default: :test

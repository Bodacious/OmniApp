# frozen_string_literal: true

# Compiles the opal_node app into one JavaScript file, build/omni.js,
# for Node to run:
#
#   bundle exec ruby apps/opal_node/build.rb
#
# The bundle holds Opal's runtime, the domain (compiled from domain/,
# the same files the Ruby apps require), this app's own Ruby from app/,
# and the shared ERB templates from adapters/interface/erb/, compiled
# with Opal::ERB. The stack matrix and the shared stylesheet are
# embedded too, so the running app reads no files. bin/omni runs this
# before booting an opal_node stack.

require 'fileutils'
require 'opal'
require 'yaml'

ROOT = File.expand_path('../..', __dir__)
OUTPUT = File.join(__dir__, 'build', 'omni.js')

builder = Opal::Builder.new
builder.append_paths(File.join(ROOT, 'domain'), File.join(__dir__, 'app'))
builder.build('opal')

matrix = YAML.safe_load_file(File.join(ROOT, 'config', 'stack_matrix.yml'))
stylesheet = File.read(File.join(ROOT, 'adapters', 'interface', 'omni.css'))
builder.build_str(<<~RUBY, 'omni_node/embedded.rb')
  module OmniNode
    MATRIX = #{matrix.inspect}.freeze
    STYLESHEET = #{stylesheet.inspect}.freeze
  end
RUBY

# The shared templates. Opal::ERB turns each into Ruby that registers
# Template["omni/erb/<name>"]; Opal then compiles that like any file.
Dir[File.join(ROOT, 'adapters', 'interface', 'erb', '*.html.erb')].each do |path|
  name = "omni/erb/#{File.basename(path, '.html.erb')}"
  builder.build_str(Opal::ERB::Compiler.new(File.read(path), name).prepared_source, "#{name}.rb")
end

builder.build('main')

FileUtils.mkdir_p(File.dirname(OUTPUT))
File.write(OUTPUT, builder.to_s)
puts "Built #{OUTPUT.delete_prefix("#{ROOT}/")} (#{File.size(OUTPUT) / 1024} KB)"

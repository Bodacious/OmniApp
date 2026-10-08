# frozen_string_literal: true

require 'test_helper'
require 'prism'

##
# The rules that keep this codebase a demonstration of layered,
# domain-driven design. Behaviour lives on the structures it belongs
# to (aggregates, value objects, repositories), never in service
# objects: a process given a class of its own, whose one public method
# is a verb.
class ArchitectureTest < ActiveSupport::TestCase
  ROOT = File.expand_path('..', __dir__)
  IGNORED = %r{(\A|/)(node_modules|build|vendor|tmp|\.git)/}

  test 'no class or module is named as a service, use case, interactor or operation' do
    pattern = /^\s*(?:class|module)\s+(?:[\w:]+::)?(\w*(?:Service|UseCase|Interactor|Operation)s?)\b/
    names = Dir.glob('**/*.rb', base: ROOT).grep_v(IGNORED).flat_map do |path|
      File.read(File.join(ROOT, path), encoding: 'UTF-8').scan(pattern).flatten.map { |name| "#{path}: #{name}" }
    end

    assert_empty names, 'Put the behaviour on the aggregate, value object or repository it belongs to'
  end

  test 'no file or directory is named as a service, use case, interactor or operation' do
    pattern = %r{(\A|/|_)(services?|use_cases?|interactors?|operations?)(/|\.rb\z)}
    paths = Dir.glob('**/*', base: ROOT).grep_v(IGNORED).grep(pattern)

    assert_empty paths, 'Put the behaviour on the aggregate, value object or repository it belongs to'
  end

  test 'no class has a single verb, like call or perform, as its whole public interface' do
    verbs = %i[call perform execute run process handle invoke]
    offenders = Dir.glob('**/*.rb', base: ROOT).grep_v(IGNORED).flat_map do |path|
      classes = []
      collect = lambda do |node|
        classes << node if node.is_a?(Prism::ClassNode)
        node.compact_child_nodes.each { |child| collect.call(child) }
      end
      collect.call(Prism.parse_file(File.join(ROOT, path)).value)

      classes.filter_map do |klass|
        visibility = :public
        statements = klass.body.is_a?(Prism::StatementsNode) ? klass.body.body : []
        public_methods = statements.each_with_object([]) do |statement, names|
          if statement.is_a?(Prism::CallNode) && %i[public private protected].include?(statement.name) &&
             statement.arguments.nil?
            visibility = statement.name
          elsif statement.is_a?(Prism::DefNode) && (visibility == :public || statement.receiver)
            names << statement.name
          end
        end - [:initialize]
        next unless public_methods.size == 1 && verbs.include?(public_methods.first)

        "#{path}: #{klass.constant_path.slice}##{public_methods.first}"
      end
    end

    assert_empty offenders, 'A class that only does one thing is a process; model the structure it acts on instead'
  end

  test 'nothing is named after ports or adapters' do
    paths = Dir.glob('**/*', base: ROOT).grep_v(IGNORED).grep(%r{(\A|/)(ports|adapters)(/|\z)})
    modules = Dir.glob('**/*.rb', base: ROOT).grep_v(IGNORED).select do |path|
      File.read(File.join(ROOT, path), encoding: 'UTF-8').match?(/^\s*module\s+(?:[\w:]+::)?(Ports|Adapters)\b/)
    end

    assert_empty paths + modules, 'Name things for what they are: a repository, a hasher, infrastructure'
  end
end

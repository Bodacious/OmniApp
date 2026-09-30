# frozen_string_literal: true

require 'minitest'

module OmniWasm
  ##
  # Runs the domain's repository contract, the same
  # domain/test/support/todo_repository_contract.rb that CI runs
  # against the Sequel adapters, here in the browser against one of
  # this app's adapters, with Minitest from CRuby's own stdlib.
  class ContractRunner
    Result = Struct.new(:name, :passed, :message, :ms)
    CONTRACT = '/omni/domain/test/support/todo_repository_contract.rb'

    # Collects each test's result instead of printing it.
    class Collector < Minitest::AbstractReporter
      attr_reader :results

      def initialize
        super
        @results = []
      end

      def record(result)
        @results << Result.new(result.name, result.passed?, result.failure&.message, result.time * 1000)
      end
    end

    # +build_repository+ returns a fresh adapter each time it's called.
    def initialize(build_repository)
      @build_repository = build_repository
    end

    def run
      load_contract
      test_class = contract_test_class(@build_repository)
      collector = Collector.new
      test_class.runnable_methods.each do |method_name|
        collector.record(Minitest.run_one_method(test_class, method_name))
      end
      collector.results
    end

    private

    # The contract requires 'todo' by load path, as the unit tests do.
    def load_contract
      $LOAD_PATH.unshift('/omni/domain') unless $LOAD_PATH.include?('/omni/domain')
      require CONTRACT
    end

    def contract_test_class(build_repository)
      Class.new(Minitest::Test) do
        include TodoRepositoryContract

        def self.name = 'TodoRepositoryContract'
        def self.test_order = :sorted

        define_method(:repository) { @repository ||= build_repository.call }

        def setup = repository.clear
        def teardown = repository.clear
      end
    end
  end
end

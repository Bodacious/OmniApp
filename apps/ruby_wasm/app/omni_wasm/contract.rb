# frozen_string_literal: true

require 'minitest'

module OmniWasm
  ##
  # The domain's list repository contract as a test suite bound to one
  # of this app's repositories: the same
  # domain/test/support/list_repository_contract.rb that CI runs
  # against the Sequel repositories, here in the browser, with Minitest
  # from CRuby's own stdlib.
  class Contract
    Result = Struct.new(:name, :passed, :message, :ms)
    CONTRACT = '/omni/domain/test/support/list_repository_contract.rb'

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

    # @param build_repository [#call] returns a fresh ListRepository each time
    def initialize(build_repository)
      @build_repository = build_repository
    end

    # Each contract test's outcome against the repository, running them
    # in name order.
    #
    # @return [Array<Result>]
    def results
      load_contract
      test_class = contract_test_class(@build_repository)
      collector = Collector.new
      test_class.runnable_methods.each do |method_name|
        collector.record(Minitest.run_one_method(test_class, method_name))
      end
      collector.results
    end

    private

    # The contract requires 'model/list_repository' by load path, as the
    # unit tests do.
    def load_contract
      $LOAD_PATH.unshift('/omni/domain') unless $LOAD_PATH.include?('/omni/domain')
      require CONTRACT
    end

    def contract_test_class(build_repository)
      Class.new(Minitest::Test) do
        include ListRepositoryContract

        def self.name = 'ListRepositoryContract'
        def self.test_order = :sorted

        define_method(:list_repository) { @list_repository ||= build_repository.call }

        def setup = list_repository.clear
        def teardown = list_repository.clear
      end
    end
  end
end

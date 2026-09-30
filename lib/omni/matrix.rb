# frozen_string_literal: true

require 'yaml'
require_relative 'stack'

module Omni
  ##
  # Reads config/stack_matrix.yml: the axes, their values, and the
  # combinations excluded from the matrix (each with a reason).
  class Matrix
    PATH = File.expand_path('../../config/stack_matrix.yml', __dir__)
    AXES = %w[app persistence interface].freeze

    def self.load(path = PATH)
      new(YAML.safe_load_file(path))
    end

    attr_reader :axes, :exclusions

    def initialize(config)
      @axes = config.fetch('axes')
      @exclusions = config.fetch('exclusions', [])
      missing = AXES - axes.keys
      raise StackError, "stack_matrix.yml is missing axes: #{missing.join(', ')}" if missing.any?
    end

    def values(axis)
      axes.fetch(axis)
    end

    # Every valid cell, ordered by app, then persistence, then interface.
    def cells
      values('app').flat_map do |app|
        values('persistence').flat_map do |persistence|
          values('interface').map do |interface|
            Stack.new(app: app, persistence: persistence, interface: interface)
          end
        end
      end.reject { |stack| exclusion_for(stack) }
    end

    # The exclusion that rules this stack out, or nil if it's valid.
    def exclusion_for(stack)
      exclusions.find do |exclusion|
        AXES.all? { |axis| !exclusion.key?(axis) || exclusion[axis] == stack.public_send(axis) }
      end
    end

    ##
    # The stack selected by OMNI_APP, OMNI_PERSISTENCE and
    # OMNI_INTERFACE. There are no defaults: an unset or unknown value,
    # or an excluded combination, raises StackError saying what to set.
    def stack_from_env(env)
      selected = AXES.to_h { |axis| [axis, env_value(env, axis)] }
      stack = Stack.new(**selected.transform_keys(&:to_sym))

      exclusion = exclusion_for(stack)
      if exclusion
        raise StackError, "#{stack.label} is excluded from the matrix: #{exclusion.fetch('reason')}"
      end

      stack
    end

    private

    def env_value(env, axis)
      name = "OMNI_#{axis.upcase}"
      value = env[name].to_s
      known = values(axis)

      if value.empty?
        raise StackError, "#{name} is not set. Choose one of: #{known.join(', ')}"
      end
      unless known.include?(value)
        raise StackError, "#{name}=#{value} is not a known #{axis}. Choose one of: #{known.join(', ')}"
      end

      value
    end
  end
end

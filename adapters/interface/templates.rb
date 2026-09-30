# frozen_string_literal: true

module Adapters
  module Interface
    ##
    # The shared templates, one directory per value of the interface
    # axis. Each holds a single page template, index.html.<engine>.
    module Templates
      ROOT = __dir__

      class ConfigurationError < StandardError; end

      def self.names
        Dir.children(ROOT).select { |entry| File.exist?(File.join(ROOT, entry, "index.html.#{entry}")) }.sort
      end

      # The directory holding the named interface's templates.
      def self.directory(name)
        dir = File.join(ROOT, name)
        unless names.include?(name)
          raise ConfigurationError, "No templates for interface #{name.inspect}. Known: #{names.join(', ')}"
        end

        dir
      end

      def self.page(name)
        File.join(directory(name), "index.html.#{name}")
      end
    end
  end
end

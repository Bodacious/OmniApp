# frozen_string_literal: true

module CoreExtensions
  module String
    module Transformations
      refine ::String do
        def dasherize
          strip
            .gsub(/[^\w]+$/, '')
            .gsub(/[^\w]+/, '-')
            .downcase
        end
      end
    end
  end
end

module CoreExtensions
  module String
    module Transformations
      refine ::String do
        def dasherize
          strip
            .gsub(/[^\w]+\Z/, '')
            .gsub(/[^\w]+/, '-')
            .downcase
        end
      end
    end
  end
end
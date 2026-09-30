# frozen_string_literal: true

# The ruby_wasm app layer's entry point. CRuby itself is running in the
# browser, compiled to WebAssembly: public/boot.js mounted this repo's
# Ruby files into its filesystem and required this file. Everything
# from here on, the domain included, is Ruby.

require_relative 'omni_wasm/composition_root'
require_relative 'omni_wasm/ui/app'
require_relative 'omni_wasm/ui/dom'

persistence = OmniWasm::UI::Dom.query_param('persistence') || 'sqlite_memory'
OmniWasm::UI::App.new(OmniWasm::CompositionRoot.new(persistence)).start

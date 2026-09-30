# frozen_string_literal: true

# Serves the ruby_wasm app. Nothing here runs the domain: the browser
# downloads CRuby (compiled to WebAssembly), and this repo's Ruby
# files, and runs them itself. This only hands over files:
#
#   /                the page and its JS bootstrap (public/)
#   /omni.css        the stylesheet shared with the server-rendered apps
#   /vendor/...      the WebAssembly runtimes, from node_modules
#   /manifest.json   which Ruby files to mount into CRuby's filesystem
#   /src/<path>      those Ruby files, served straight from the repo

require 'json'
require 'rack'
require 'rack/files'

module OmniWasmServer
  ROOT = File.expand_path('../..', __dir__)
  PUBLIC = File.join(__dir__, 'public')
  NODE_MODULES = File.join(__dir__, 'node_modules')
  VENDOR_PACKAGES = %w[@ruby/3.4-wasm-wasi @ruby/wasm-wasi @bjorn3/browser_wasi_shim @sqlite.org/sqlite-wasm].freeze
  NO_CACHE = { 'cache-control' => 'no-cache' }.freeze

  # The Ruby the browser mounts: the whole domain, the domain's port
  # contract (so the page can run it), and this app's own code. Paths
  # are repo-relative and mounted under /omni, so require_relative
  # resolves exactly as it does on disk.
  def self.sources
    domain = Dir.glob('domain/**/*.rb', base: ROOT).reject { |path| path.start_with?('domain/test/') }
    contract = ['domain/test/support/todo_repository_contract.rb']
    app = Dir.glob('apps/ruby_wasm/app/**/*.rb', base: ROOT)
    (domain + contract + app).sort
  end

  Manifest = lambda do |_env|
    [200, NO_CACHE.merge('content-type' => 'application/json'), [JSON.generate('mount' => '/omni', 'files' => sources)]]
  end

  # Only the files in the manifest, never anything else in the repo.
  Sources = lambda do |env|
    path = env['PATH_INFO'].delete_prefix('/')
    next [404, { 'content-type' => 'text/plain' }, ['Not found']] unless sources.include?(path)

    [200, NO_CACHE.merge('content-type' => 'text/plain; charset=utf-8'), [File.read(File.join(ROOT, path))]]
  end

  SharedStylesheet = lambda do |_env|
    css = File.read(File.join(ROOT, 'adapters/interface/omni.css'))
    [200, NO_CACHE.merge('content-type' => 'text/css; charset=utf-8'), [css]]
  end

  # The four npm packages the page imports, and nothing else from
  # node_modules. They're pinned in package-lock.json, so cache them.
  class Vendor
    def initialize
      @files = Rack::Files.new(NODE_MODULES, 'cache-control' => 'public, max-age=86400')
    end

    def call(env)
      allowed = VENDOR_PACKAGES.any? { |package| env['PATH_INFO'].start_with?("/#{package}/") }
      return [404, { 'content-type' => 'text/plain' }, ['Not found']] unless allowed

      @files.call(env)
    end
  end

  class Public
    def initialize
      @files = Rack::Files.new(PUBLIC, NO_CACHE)
    end

    def call(env)
      env = env.merge('PATH_INFO' => '/index.html') if env['PATH_INFO'] == '/'
      @files.call(env)
    end
  end
end

unless Dir.exist?(File.join(OmniWasmServer::NODE_MODULES, '@ruby/3.4-wasm-wasi'))
  abort 'apps/ruby_wasm needs its npm packages. Run: npm ci --prefix apps/ruby_wasm'
end

use Rack::CommonLogger
map('/manifest.json') { run OmniWasmServer::Manifest }
map('/src') { run OmniWasmServer::Sources }
map('/vendor') { run OmniWasmServer::Vendor.new }
map('/omni.css') { run OmniWasmServer::SharedStylesheet }
run OmniWasmServer::Public.new

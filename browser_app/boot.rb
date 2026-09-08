# frozen_string_literal: true

require 'bundler/setup'
Bundler.require(:default, :browser)

require 'opal'

##
# Serves the HTML shell and compiles app/application.rb (plus the
# shared domain/) into a single JS bundle on every request, so editing
# any Opal source file takes effect on the next page load.
module BrowserApp
  ROOT = __dir__
  APP_DIR = File.expand_path('app', ROOT)
  DOMAIN_DIR = File.expand_path('../domain', ROOT)
  REPO_ROOT = File.expand_path('..', ROOT)
  INDEX_HTML = File.read(File.expand_path('public/index.html', ROOT))

  def self.call(env)
    if env['PATH_INFO'] == '/assets/application.js'
      [200, { 'content-type' => 'application/javascript; charset=utf-8' }, [javascript_bundle]]
    else
      [200, { 'content-type' => 'text/html; charset=utf-8' }, [INDEX_HTML]]
    end
  end

  def self.javascript_bundle
    builder = Opal::Builder.new
    builder.append_paths(APP_DIR, DOMAIN_DIR, REPO_ROOT)
    builder.build('opal')
    builder.build('application')
    builder.to_s
  end
end

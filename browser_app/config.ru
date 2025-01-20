require 'bundler'
Bundler.require

Opal.append_path(File.expand_path('../../core_app', __FILE__))

run Opal::Sprockets::Server.new { |s|

  s.append_path "app"  # Add the app directory to Opal's load path
  s.main = "main"      # Set the entry point file (app/main.rb)
  # use Rack::Static, urls: ["/"], root: "public", index: "index.html"
}

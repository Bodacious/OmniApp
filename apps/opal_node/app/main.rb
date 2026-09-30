# frozen_string_literal: true

# The opal_node app layer's entry point: Ruby, compiled by Opal into
# build/omni.js (see build.rb) and run by Node. It loads the same
# domain/ files the Ruby apps require, from the same path.

require 'omni_node/composition_root'
require 'omni_node/router'
require 'omni_node/http_server'

begin
  composition = OmniNode::CompositionRoot.boot(->(name) { OmniNode::Node.env(name) })
rescue OmniNode::StackError => e
  $stderr.puts "opal_node: #{e.message}"
  OmniNode::Node.exit(1)
end

OmniNode::HttpServer.new(OmniNode::Router.new(composition),
                         host: OmniNode::Node.env('HOST') || '127.0.0.1',
                         port: Integer(OmniNode::Node.env('PORT') || '9292')).start

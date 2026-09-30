# frozen_string_literal: true

# backtick_javascript: true

require 'omni_node/node'
require 'omni_node/router'

module OmniNode
  ##
  # Serves the Router over Node's http module. Reading the request body
  # is asynchronous (Node's 'data' and 'end' events), but once it's all
  # in, the router and the domain run synchronously to the end.
  class HttpServer
    def initialize(router, host:, port:)
      @router = router
      @host = host
      @port = port
    end

    def start
      handler = proc { |request, response| receive(request, response) }
      server = `#{Node.require_module('node:http')}.createServer(#{handler})`
      listening = proc { $stdout.puts "opal_node listening on http://#{@host}:#{@port}" }
      `#{server}.listen(#{@port}, #{@host}, #{listening})`
    end

    private

    def receive(request, response)
      chunks = []
      `#{request}.on('data', function (chunk) { #{chunks}.push(chunk); })`
      finished = proc { respond(request, response, `Buffer.concat(#{chunks}).toString('utf8')`) }
      `#{request}.on('end', #{finished})`
    end

    def respond(request, response, body)
      started = `Date.now()`
      verb = `#{request}.method`
      url = `new URL(#{request}.url, 'http://localhost')`
      path = `#{url}.pathname`
      result = begin
        @router.call(Request.new(verb, path, params(`#{url}.searchParams`), form(body)))
      rescue Exception => e # rubocop:disable Lint/RescueException -- JS errors too; keep serving
        $stderr.puts "#{e.class}: #{e.message}"
        Response.new(500, { 'content-type' => 'text/plain' }, 'Internal Server Error')
      end
      write(response, result)
      $stdout.puts "#{verb} #{path} #{result.status} #{`Date.now()` - started}ms"
    end

    # An application/x-www-form-urlencoded body, as a Hash.
    def form(body)
      params(`new URLSearchParams(#{body})`)
    end

    # URLSearchParams as a Hash of strings (the last value wins).
    def params(search_params)
      pairs = `Array.from(#{search_params}.entries())`
      pairs.to_h { |pair| [`#{pair}[0]`, `#{pair}[1]`] }
    end

    def write(response, result)
      result.headers.each { |name, value| `#{response}.setHeader(#{name}, #{value})` }
      `#{response}.statusCode = #{result.status}`
      `#{response}.end(#{result.body})`
    end
  end
end

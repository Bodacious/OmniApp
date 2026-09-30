# frozen_string_literal: true

# backtick_javascript: true

require 'json'

module OmniNode
  Request = Struct.new(:verb, :path, :query, :form)
  Response = Struct.new(:status, :headers, :body)

  ##
  # The HTTP contract every app layer honours, in plain Ruby: a Request
  # in, a Response out, one synchronous call into the domain per route.
  # The Node plumbing around it is in HttpServer.
  class Router
    TODO_ACTION = %r{\A/todos/([^/]+)/(complete|delete|tags)\z}
    UNTAG = %r{\A/todos/([^/]+)/tags/([^/]+)/delete\z}

    def initialize(composition)
      @composition = composition
    end

    def call(request)
      case [request.verb, request.path]
      when ['GET', '/'] then page(tag: request.query['tag'])
      when ['POST', '/todos'] then create(request.form['title'], request.form['tags'])
      when ['GET', '/health'] then json(@composition.health)
      when ['POST', '/__test__/reset'] then reset
      else todo_action(request)
      end
    end

    private

    def todo_service
      @composition.todo_service
    end

    def create(title, tags)
      todo_service.add(title, tags)
      redirect
    rescue InvalidInput => e
      page(error: e.message, status: 422)
    end

    def todo_action(request)
      return not_found unless request.verb == 'POST'

      if (match = UNTAG.match(request.path))
        change { todo_service.untag(decode(match[1]), decode(match[2])) }
      elsif (match = TODO_ACTION.match(request.path))
        id = decode(match[1])
        case match[2]
        when 'complete' then change { todo_service.complete(id) }
        when 'delete' then change { todo_service.delete(id) }
        when 'tags' then change { todo_service.tag(id, request.form['tags']) }
        end
      else
        not_found
      end
    end

    # Runs a use case on an existing todo, then back to the list.
    def change
      yield
      redirect
    rescue InvalidInput => e
      page(error: e.message, status: 422)
    rescue TodoService::NotFound
      text(404, 'No such todo')
    end

    def decode(segment)
      `decodeURIComponent(#{segment})`
    end

    # Mounted only in the test environment; otherwise it doesn't exist.
    def reset
      return not_found unless @composition.test_mode?

      @composition.reset!
      Response.new(204, {}, '')
    end

    def page(error: nil, tag: nil, status: 200)
      Response.new(status, { 'content-type' => 'text/html; charset=utf-8' }, @composition.render_page(error: error, tag: tag))
    end

    def redirect
      Response.new(303, { 'location' => '/' }, '')
    end

    def json(data)
      Response.new(200, { 'content-type' => 'application/json' }, data.to_json)
    end

    def not_found
      text(404, 'Not found')
    end

    def text(status, body)
      Response.new(status, { 'content-type' => 'text/plain; charset=utf-8' }, body)
    end
  end
end

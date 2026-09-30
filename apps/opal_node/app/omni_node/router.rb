# frozen_string_literal: true

require 'json'

module OmniNode
  Request = Struct.new(:verb, :path, :form)
  Response = Struct.new(:status, :headers, :body)

  ##
  # The HTTP contract every app layer honours, in plain Ruby: a Request
  # in, a Response out, one synchronous call into the domain per route.
  # The Node plumbing around it is in HttpServer.
  class Router
    TODO_ACTION = %r{\A/todos/([^/]+)/(complete|delete)\z}

    def initialize(composition)
      @composition = composition
    end

    def call(request)
      case [request.verb, request.path]
      when ['GET', '/'] then page
      when ['POST', '/todos'] then create(request.form['title'])
      when ['GET', '/health'] then json(@composition.health)
      when ['POST', '/__test__/reset'] then reset
      else todo_action(request)
      end
    end

    private

    def todo_list
      @composition.todo_list
    end

    def create(title)
      todo_list.add(title)
      redirect
    rescue Todo::Invalid => e
      page(error: e.message, status: 422)
    end

    def todo_action(request)
      match = TODO_ACTION.match(request.path)
      return not_found unless request.verb == 'POST' && match

      id = match[1]
      match[2] == 'complete' ? todo_list.complete(id) : todo_list.delete(id)
      redirect
    rescue TodoList::NotFound
      text(404, 'No such todo')
    end

    # Mounted only in the test environment; otherwise it doesn't exist.
    def reset
      return not_found unless @composition.test_mode?

      @composition.reset!
      Response.new(204, {}, '')
    end

    def page(error: nil, status: 200)
      Response.new(status, { 'content-type' => 'text/html; charset=utf-8' }, @composition.render_page(error: error))
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

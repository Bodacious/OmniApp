# frozen_string_literal: true

# backtick_javascript: true

require 'json'

module OmniNode
  Request = Struct.new(:verb, :path, :query, :form, :cookie)
  Response = Struct.new(:status, :headers, :body)

  ##
  # The HTTP contract every app layer honours, in plain Ruby: a Request
  # in, a Response out, and in between, synchronous calls on the
  # domain's aggregates and repositories. The routes are the Sinatra app's. The Node plumbing
  # around it is in HttpServer.
  class Router
    SEGMENT = '([^/]+)'
    ROUTES = [
      ['GET', '/health', :health],
      ['POST', '/__test__/reset', :reset],
      ['GET', '/sign_in', :sign_in_form],
      ['POST', '/sign_in', :sign_in],
      ['GET', '/sign_up', :sign_up_form],
      ['POST', '/sign_up', :sign_up],
      ['POST', '/sign_out', :sign_out],
      ['GET', '/', :show_lists],
      ['POST', '/lists', :create_list],
      ['GET', '/lists/:list_id', :show_list],
      ['POST', '/lists/:list_id/delete', :delete_list],
      ['POST', '/lists/:list_id/todos', :add_todo],
      ['POST', '/lists/:list_id/todos/:id/complete', :complete_todo],
      ['POST', '/lists/:list_id/todos/:id/tags', :tag_todo],
      ['POST', '/lists/:list_id/todos/:id/tags/:tag/delete', :untag_todo],
      ['POST', '/lists/:list_id/todos/:id/delete', :delete_todo]
    ].map { |verb, path, action| [verb, Regexp.new("\\A#{path.gsub(/:\w+/, SEGMENT)}\\z"), action] }.freeze

    def initialize(composition)
      @composition = composition
    end

    # The response the route matching +request+ gives, or a 404.
    #
    # @param request [Request]
    # @return [Response]
    def response_for(request)
      ROUTES.each do |verb, pattern, action|
        next unless verb == request.verb && (match = pattern.match(request.path))

        arguments = match.captures.map { |segment| decode(segment) }
        return Handler.not_found if arguments.include?(nil)

        return Handler.new(@composition, request).public_send(action, *arguments)
      end
      Handler.not_found
    end

    private

    # A path segment, percent-decoded; nil if it's malformed.
    def decode(segment)
      `decodeURIComponent(#{segment})`
    rescue Exception # rubocop:disable Lint/RescueException -- decodeURIComponent throws a JS URIError
      nil
    end

    ##
    # One request: who sent it, and what each route does with it. Who
    # is signed in comes from the signed session cookie (SessionCookie).
    class Handler
      HTML = { 'content-type' => 'text/html; charset=utf-8' }.freeze

      def self.not_found(message = 'Not found')
        Response.new(404, { 'content-type' => 'text/plain; charset=utf-8' }, message)
      end

      def initialize(composition, request)
        @composition = composition
        @request = request
      end

      def health
        Response.new(200, { 'content-type' => 'application/json' }, @composition.health.to_json)
      end

      # Mounted only in the test environment; otherwise it doesn't exist.
      def reset
        return Handler.not_found unless @composition.test_mode?

        @composition.reset!
        Response.new(204, {}, '')
      end

      # --- accounts

      def sign_in_form
        user ? redirect('/') : page('sign_in')
      end

      def sign_in
        start_session('sign_in') { users.account_for(param('email')).authenticate(param('password'), password_hasher) }
      end

      def sign_up_form
        user ? redirect('/') : page('sign_up')
      end

      def sign_up
        start_session('sign_up') do
          users.add(User.register(id: users.next_identity, email: param('email'), password: param('password'),
                                  hasher: password_hasher))
        end
      end

      def sign_out
        redirect('/sign_in', 'set-cookie' => session.sign_out)
      end

      # --- lists

      def show_lists
        signed_in { page('lists') }
      end

      def create_list
        signed_in do
          list = lists.save(List.new(id: lists.next_identity, owner_id: user.id, name: param('name')))
          redirect("/lists/#{list.id}")
        rescue InvalidInput => e
          page('lists', error: e.message, status: 422)
        end
      end

      def show_list(list_id)
        with_list(list_id) { |list| page('list', list: list, tag: @request.query['tag']) }
      end

      def delete_list(list_id)
        signed_in do
          found { lists.remove(lists.fetch(list_id, owner: user)) } || redirect('/')
        end
      end

      # --- todos on a list

      def add_todo(list_id)
        change(list_id) { |list| list.add(id: lists.next_identity, title: param('title'), tags: param('tags')) }
      end

      def complete_todo(list_id, id)
        change(list_id) { |list| list.complete(id) }
      end

      def tag_todo(list_id, id)
        change(list_id) { |list| list.tag(id, param('tags')) }
      end

      def untag_todo(list_id, id, tag)
        change(list_id) { |list| list.untag(id, tag) }
      end

      def delete_todo(list_id, id)
        change(list_id) { |list| list.remove(id) }
      end

      private

      def users
        @composition.users
      end

      def lists
        @composition.lists
      end

      def password_hasher
        @composition.password_hasher
      end

      def session
        @composition.session
      end

      # The signed-in User, or nil.
      def user
        return @user if defined?(@user)

        @user = users.find(session.user_id(@request.cookie))
      end

      def start_session(form)
        signed_in_user = yield
        redirect('/', 'set-cookie' => session.sign_in(signed_in_user.id))
      rescue InvalidInput => e
        page(form, error: e.message, email: param('email'), status: 422)
      end

      def signed_in
        user ? yield : redirect('/sign_in')
      end

      # Opens the signed-in user's list from the URL, or 404.
      def with_list(list_id)
        signed_in do
          list = nil
          found { list = lists.fetch(list_id, owner: user) } || yield(list)
        end
      end

      # Changes the open list, saves it, then goes back to it.
      def change(list_id)
        with_list(list_id) do |list|
          found do
            yield list
            lists.save(list)
          end || redirect("/lists/#{list.id}")
        rescue InvalidInput => e
          page('list', list: list, error: e.message, status: 422)
        end
      end

      # Runs the block, returning nil, or a 404 if it names a list or
      # todo the user doesn't have.
      def found
        yield
        nil
      rescue NotFound => e
        Handler.not_found(e.message)
      end

      # A form field, as a string or nil. Whether it's valid is for the
      # domain to judge.
      def param(name)
        @request.form[name]
      end

      def page(name, status: 200, **options)
        Response.new(status, HTML, @composition.render_page(name, user: user, **options))
      end

      def redirect(location, headers = {})
        Response.new(303, { 'location' => location }.merge(headers), '')
      end
    end
  end
end

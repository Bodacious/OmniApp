require 'test_helper'
require 'main'

class MainTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_it_loads_the_landing_page_with_ok
    get '/'
    assert_predicate last_response, :ok?
  end

  def test_post_to_lists_creates_a_new_list
    post '/lists', list: { name: "list-name" }
    assert_predicate last_response, :redirection?
    assert_equal "text/html", last_response.media_type
    assert last_response.headers['Location'].end_with?("/lists/1"),
           "Location header should include new list URL"
  end

  def test_it_loads_individual_list
    get '/lists/1'
    assert_predicate last_response, :ok?
    assert_equal "text/html", last_response.media_type
  end

  def test_it_creates_individual_list_item
    post '/lists/1/items', item: { name: "item-name" }
    assert_predicate last_response, :redirection?
    assert_equal "text/html", last_response.media_type
    assert last_response.headers['Location'].end_with?("/lists/1"),
           "Location header should include new list URL"
  end
end
require "test_helper"
require "main"
require "capybara"
require "capybara/dsl"

class MainTest < Minitest::Test
  # include Rack::Test::Methods
  include Capybara::DSL

  def setup
    Capybara.app = Sinatra::Application.new
  end

  def test_it_loads_the_landing_page
    visit "/"
    assert page.has_content? "My lists"
  end

  def test_user_creates_new_list
    visit "/"
    click_on "New list"

    fill_in :list_name, with: "list-name"
    click_on "Save"

    assert page.has_content?("list-name")
    # visit '/lists', list: { name: "list-name" }
    # assert_predicate last_response, :redirection?
    # assert_equal "text/html", last_response.media_type
    # assert last_response.headers['Location'].end_with?("/lists/1"),
    #        "Location header should include new list URL"
  end

  # def test_it_loads_individual_list
  #   get '/lists/1'
  #   assert_predicate last_response, :ok?
  #   assert_equal "text/html", last_response.media_type
  # end

  # def test_it_creates_individual_list_item
  #   post '/lists/1/items', item: { name: "item-name" }
  #   assert_predicate last_response, :redirection?
  #   assert_equal "text/html", last_response.media_type
  #   assert last_response.headers['Location'].end_with?("/lists/1"),
  #          "Location header should include new list URL"
  # end
end

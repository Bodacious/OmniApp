# frozen_string_literal: true

require 'app_helper'

class MainTest < Minitest::Test
  # include Rack::Test::Methods
  include Capybara::DSL

  def test_it_loads_the_landing_page
    visit '/'

    assert page.has_content? 'My lists'
  end

  def test_user_creates_new_list_and_adds_an_item
    visit '/'
    click_on 'New list'

    fill_in :'list[name]', with: 'list-name'
    click_on 'Save'

    assert_content('list-name')

    assert_equal '/lists/list-name', current_path

    click_on 'Add item'

    fill_in :'list_item[summary]', with: 'list-item-summary'
    click_on 'Save'

    assert_content('list-item-summary')
  end

  def test_user_creates_new_list_and_then_deletes_it
    visit '/'
    click_on 'New list'

    fill_in :'list[name]', with: 'list-name'
    click_on 'Save'

    assert_content('list-name')
    assert_current_path '/lists/list-name'

    click_on 'Delete list'

    assert_current_path '/'
    refute_content 'list-name'
  end

  def test_user_creates_new_list_item_and_then_deletes_it
    visit '/'
    click_on 'New list'

    fill_in :'list[name]', with: 'list-name'
    click_on 'Save'

    fill_in :'list_item[summary]', with: 'list-item-summary'
    click_on 'Save'

    assert_content 'list-item-summary'
    assert_current_path '/lists/list-name'

    click_on 'Remove'

    refute_content 'list-item-summary'
    assert_current_path '/lists/list-name'
  end
end

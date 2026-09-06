# frozen_string_literal: true

require 'app_helper'

class MainTest < Minitest::Test
  include Capybara::DSL

  def test_it_loads_the_landing_page
    visit '/'

    assert_content('My lists')
  end

  def test_user_creates_a_list_and_adds_an_item_on_the_in_memory_backend
    visit '/'

    fill_in 'new-list-name', with: 'Groceries'
    click_on 'New list'

    assert_content('Groceries')

    select_list('Groceries')
    fill_in 'new-item-summary', with: 'Milk'
    click_on 'Add item'

    assert_content('Milk')
  end

  def test_in_memory_backend_resets_after_reload
    visit '/'

    fill_in 'new-list-name', with: 'Groceries'
    click_on 'New list'

    assert_content('Groceries')

    visit '/'

    refute_content('Groceries')
  end

  def test_local_storage_backend_persists_across_reload
    visit '/'
    select 'Browser storage (persists across reloads)', from: 'backend-select'

    fill_in 'new-list-name', with: 'Chores'
    click_on 'New list'

    assert_content('Chores')

    visit '/'
    select 'Browser storage (persists across reloads)', from: 'backend-select'

    assert_content('Chores')
  end

  private

  def select_list(name)
    find(:css, '[data-action="select-list"]', text: name).click
  end
end

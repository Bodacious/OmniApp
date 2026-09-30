# frozen_string_literal: true

require 'capybara/cucumber'
require 'capybara/cuprite'
require 'rspec/expectations'
require_relative 'omni_stack'

# The specs never boot an app themselves. They drive a stack that is
# already running as its own process (Ruby or Node) over real HTTP, in
# a real headless Chrome. bin/omni-test boots the stack and sets
# OMNI_BASE_URL.
Capybara.run_server = false
Capybara.app_host = OmniStack.base_url
Capybara.default_max_wait_time = 5

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(app, window_size: [1200, 900],
                                     browser_options: { 'no-sandbox' => nil },
                                     process_timeout: 30, timeout: 15)
end
Capybara.default_driver = :cuprite
Capybara.javascript_driver = :cuprite

module TodoPage
  def testid(name)
    "[data-testid='#{name}']"
  end

  # The list item whose title is exactly +title+.
  def todo_item(title)
    find(testid('todo-item-title'), exact_text: title).ancestor(testid('todo-item'))
  end

  def add_todo(title)
    within(testid('todo-form')) do
      fill_in 'Title', with: title
      click_button 'Add todo'
    end
  end

  def complete_todo(title)
    within(todo_item(title)) { find(testid('todo-complete-button')).click }
  end

  def expect_completed(title)
    expect(page).to have_css("#{testid('todo-item')}[data-completed='true']", text: title)
    within(todo_item(title)) { expect(page).to have_no_css(testid('todo-complete-button')) }
  end
end
World(TodoPage)

# Every scenario starts from an empty list, on the stack we think we're
# testing. If /health disagrees with OMNI_*, the scenario fails rather
# than quietly testing the wrong stack.
Before do
  OmniStack.reset!
  OmniStack.verify_health!
end

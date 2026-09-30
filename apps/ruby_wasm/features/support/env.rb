# frozen_string_literal: true

require 'capybara/cucumber'
require 'capybara/cuprite'
require 'rspec/expectations'

# Drives the ruby_wasm app, already being served by bin/omni-wasm, in a
# real headless Chrome. bin/omni-wasm-test starts the server and sets
# OMNI_WASM_URL.
Capybara.run_server = false
Capybara.app_host = ENV.fetch('OMNI_WASM_URL') do
  raise 'OMNI_WASM_URL is not set. Run these specs with bin/omni-wasm-test.'
end
Capybara.default_max_wait_time = 10

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(app, window_size: [1360, 900],
                                     browser_options: { 'no-sandbox' => nil },
                                     process_timeout: 30, timeout: 60)
end
Capybara.default_driver = :cuprite

module WasmPage
  BOOT_TIMEOUT = 60

  def testid(name)
    "[data-testid='#{name}']"
  end

  def wait_for_boot
    expect(page).to have_css("body[data-omni-ready='true']", wait: BOOT_TIMEOUT)
  end

  def todo_item(title)
    find(testid('todo-item-title'), exact_text: title).ancestor(testid('todo-item'))
  end

  def add_todo(title)
    within(testid('todo-form')) do
      fill_in 'Title', with: title
      click_button 'Add todo'
    end
  end

  def todo_titles
    all(testid('todo-item-title')).map(&:text)
  end
end
World(WasmPage)

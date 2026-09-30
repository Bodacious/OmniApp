# frozen_string_literal: true

Given('the WebAssembly app has booted') do
  visit '/'
  wait_for_boot
  @boot_id = find('body')['data-boot-id']
end

When('I add a todo titled {string}') do |title|
  add_todo(title)
end

Given('I have added the todos {string}') do |title|
  add_todo(title)
  expect(page).to have_css(testid('todo-item-title'), exact_text: title)
end

Given('I have added the todos {string}, {string} and {string}') do |*titles|
  titles.each do |title|
    add_todo(title)
    expect(page).to have_css(testid('todo-item-title'), exact_text: title)
  end
end

When('I complete the todo titled {string}') do |title|
  within(todo_item(title)) { find(testid('todo-complete-button')).click }
end

Given('I have completed the todo titled {string}') do |title|
  within(todo_item(title)) { find(testid('todo-complete-button')).click }
  expect(page).to have_css("#{testid('todo-item')}[data-completed='true']", text: title)
end

When('I delete the todo titled {string}') do |title|
  within(todo_item(title)) { find(testid('todo-delete-button')).click }
end

When('I show the {word} todos') do |filter|
  find(testid("filter-#{filter}")).click
  expect(page).to have_css("#{testid("filter-#{filter}")}[aria-pressed='true']")
end

When('I switch persistence to {string}') do |persistence|
  find(testid("persistence-#{persistence}")).click
  expect(page).to have_css("#{testid('stack-badge')} [data-axis='persistence']", exact_text: persistence)
end

When('I run the port contract') do
  find(testid('run-contract')).click
end

When('I reload the page') do
  page.refresh
  wait_for_boot
end

Then('Ruby reports its platform as {string}') do |platform|
  expect(page).to have_css(testid('runtime-platform'), exact_text: platform)
end

Then('the stack badge shows {string}') do |stack|
  app, persistence, interface = stack.split(' / ')
  { 'app' => app, 'persistence' => persistence, 'interface' => interface }.each do |axis, value|
    expect(page).to have_css("#{testid('stack-badge')} [data-axis='#{axis}']", exact_text: value)
  end
  # Whitespace depends on layout (the badge is a flex row), not markup.
  expect(find(testid('stack-badge')).text.split.join(' ')).to eq(stack)
end

Then('I see the todos {string}') do |title|
  expect(page).to have_css(testid('todo-item'), count: 1)
  expect(todo_titles).to eq([title])
end

Then('I see the todos {string} and {string}') do |first, second|
  expect(page).to have_css(testid('todo-item'), count: 2)
  expect(todo_titles).to eq([first, second])
end

Then('the todo titled {string} is completed') do |title|
  expect(page).to have_css("#{testid('todo-item')}[data-completed='true']", text: title)
  within(todo_item(title)) { expect(page).to have_css(testid('todo-done-marker')) }
end

Then('the page was never reloaded') do
  expect(find('body')['data-boot-id']).to eq(@boot_id)
end

Then('I see the error {string}') do |message|
  expect(page).to have_css(testid('todo-error'), exact_text: message)
end

Then('I see that there is nothing to do') do
  expect(page).to have_css(testid('todo-empty'))
  expect(page).to have_no_css(testid('todo-item'))
end

Then('it says {string}') do |text|
  expect(page).to have_css(testid('todo-remaining'), exact_text: text)
end

Then('the inspector shows these calls for it, in order:') do |table|
  expected = table.hashes.map { |row| [row['layer'], row['call']] }
  # Match on the title attribute: it holds the exact call, where the
  # visible text collapses whitespace.
  expect(page).to(have_css("#{testid('trace-entry')}[data-layer='use_case']") { |entry| entry['title'] == expected.first.last })
  entries = all(testid('trace-entry')).map { |entry| [entry['data-layer'], entry['title']] }
  start = entries.index { |layer, call| layer == 'use_case' && call == expected.first.last }
  finish = (start + 1...entries.size).find { |index| entries[index].first == 'use_case' } || entries.size
  actual = entries[start...finish]
  expect(actual.size).to eq(expected.size)
  actual.zip(expected).each do |(layer, call), (expected_layer, expected_call)|
    expect([layer, call]).to match([expected_layer, start_with(expected_call)])
  end
end

Then('every contract test passes') do
  expect(page).to have_css(testid('contract-summary'))
  results = all(testid('contract-result'))
  expect(results).not_to be_empty
  # (Inside Capybara's DSL, `all` finds elements, so no `all` matcher here.)
  expect(results.map { |result| result['data-passed'] }.uniq).to eq(['true'])
  expect(find(testid('contract-summary')).text).to start_with("#{results.size}/#{results.size} passed")
end

When('I add a todo titled {string} tagged {string}') do |title, tags|
  add_todo(title, tags: tags)
end

When('I tag the todo titled {string} with {string}') do |title, tags|
  within(todo_item(title)) do
    find(testid('todo-tag-input')).set(tags)
    find(testid('todo-tag-submit')).click
  end
end

When('I remove the tag {string} from the todo titled {string}') do |tag, title|
  within(todo_item(title)) do
    find("#{testid('todo-tag')}[data-tag='#{tag}'] #{testid('todo-untag-button')}").click
  end
end

When('I filter by the tag {string}') do |tag|
  find("#{testid('tag-filter-link')}[data-tag='#{tag}']").click
end

When('I stop filtering by tag') do
  find(testid('tag-filter-clear')).click
  expect(page).to have_no_css(testid('tag-filter-clear'))
end

Then('the todo titled {string} has the tags {string}') do |title, tags|
  expected = tags.split(', ')
  expect(page).to have_css("#{testid('todo-item')}[data-todo-id] #{testid('todo-tag')}[data-tag='#{expected.last}']")
  item = todo_item(title)
  expect(item).to have_css(testid('todo-tag'), count: expected.size)
  expect(item.all(testid('todo-tag')).map { |tag| tag['data-tag'] }).to eq(expected)
end

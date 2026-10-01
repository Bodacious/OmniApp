# frozen_string_literal: true

# Lists and who owns them, through the same data-testid hooks on every
# stack.

When('I create a list named {string}') do |name|
  create_list(name)
end

Given('I have a list named {string} with a todo {string}') do |name, title|
  create_list(name)
  expect(page).to have_css(testid('list-title'), exact_text: name)
  add_todo(title)
  expect(page).to have_css(testid('todo-item-title'), exact_text: title)
end

Given('I remember the address of this list') do
  @remembered_path = page.current_path
end

When('I open the list {string}') do |name|
  visit '/'
  find(testid('list-link'), exact_text: name).click
end

When('I go back to my lists') do
  find(testid('back-to-lists')).click
end

When('I delete the list {string}') do |name|
  visit '/'
  item = find(testid('list-link'), exact_text: name).ancestor(testid('list-item'))
  within(item) { find(testid('list-delete-button')).click }
end

When('I visit the address I remembered') do
  visit @remembered_path
end

Then('I see that I have no lists') do
  expect(page).to have_css(testid('lists-empty'))
  expect(page).to have_no_css(testid('list-item'))
end

Then('I am looking at the list {string}') do |name|
  expect(page).to have_css(testid('list-title'), exact_text: name)
end

Then('I see the lists {string}') do |name|
  expect(page).to have_css(testid('list-item'), count: 1)
  expect(list_names).to eq([name])
end

Then('I see the lists {string} and {string}, in that order') do |first, second|
  expect(page).to have_css(testid('list-item'), count: 2)
  expect(list_names).to eq([first, second])
end

Then('I see that there is no such list') do
  expect(page).to have_content('No such list')
  expect(page.status_code).to eq(404)
end

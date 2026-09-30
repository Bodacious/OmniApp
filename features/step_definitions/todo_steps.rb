# frozen_string_literal: true

# These steps know the page only through its data-testid hooks and its
# visible labels, which every template on every stack emits. Nothing
# here branches on which stack is running.

Given('I open the todo list') do
  visit '/'
end

When('I add a todo titled {string}') do |title|
  add_todo(title)
end

Given('I have added a todo titled {string}') do |title|
  add_todo(title)
  expect(page).to have_css(testid('todo-item-title'), exact_text: title)
end

When('I complete the todo titled {string}') do |title|
  complete_todo(title)
end

Given('I have completed the todo titled {string}') do |title|
  complete_todo(title)
  expect_completed(title)
end

When('I delete the todo titled {string}') do |title|
  within(todo_item(title)) { find(testid('todo-delete-button')).click }
end

When('I reload the page') do
  page.refresh
end

Then('I see that there is nothing to do') do
  expect(page).to have_css(testid('todo-empty'))
  within(testid('todo-list')) { expect(page).to have_no_css(testid('todo-item')) }
end

Then('I see a todo titled {string}') do |title|
  within(testid('todo-list')) do
    expect(page).to have_css(testid('todo-item-title'), exact_text: title)
  end
end

Then("I don't see a todo titled {string}") do |title|
  within(testid('todo-list')) do
    expect(page).to have_no_css(testid('todo-item-title'), exact_text: title)
  end
end

Then('I see {int} todo(s)') do |count|
  within(testid('todo-list')) { expect(page).to have_css(testid('todo-item'), count: count) }
end

Then('I see the todos {string} and {string}, in that order') do |first, second|
  within(testid('todo-list')) do
    expect(page).to have_css(testid('todo-item'), count: 2)
    expect(all(testid('todo-item-title')).map(&:text)).to eq([first, second])
  end
end

Then('the todo titled {string} is completed') do |title|
  expect_completed(title)
end

Then('the todo titled {string} is not completed') do |title|
  expect(page).to have_css("#{testid('todo-item')}[data-completed='false']", text: title)
  within(todo_item(title)) { expect(page).to have_css(testid('todo-complete-button')) }
end

Then('I see the error {string}') do |message|
  expect(page).to have_css(testid('todo-error'), exact_text: message)
end

Then('the stack badge shows the configured stack') do
  within(testid('stack-badge')) do
    OmniStack.expected.each do |axis, value|
      expect(page).to have_css("[data-axis='#{axis}']", exact_text: value)
    end
  end
  # Whitespace depends on layout (the badge is a flex row), not markup.
  expect(find(testid('stack-badge')).text.split.join(' ')).to eq(OmniStack.expected.values.join(' / '))
end

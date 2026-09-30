# frozen_string_literal: true

# Tagging, through the same data-testid hooks every stack's templates
# emit. Tags are compared by their data-tag attribute, the normalised
# name, so these steps check what the domain did with the input.

When('I add a todo titled {string} tagged {string}') do |title, tags|
  add_todo(title, tags: tags)
end

Given('I have added a todo titled {string} tagged {string}') do |title, tags|
  add_todo(title, tags: tags)
  expect(page).to have_css(testid('todo-item-title'), exact_text: title)
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
end

Then('the todo titled {string} has the tags {string}') do |title, tags|
  expected = tags.split(', ')
  expect(page).to have_css(testid('todo-item-title'), exact_text: title)
  item = todo_item(title)
  expect(item).to have_css(testid('todo-tag'), count: expected.size)
  expect(tag_names(item)).to eq(expected)
end

Then('the tag filter lists {string}') do |listing|
  expected = listing.split(', ').map do |entry|
    name, count = entry.match(/\A(\S+) \((\d+)\)\z/).captures
    [name, count]
  end
  links = all(testid('tag-filter-link'))
  expect(links.map { |link| [link['data-tag'], link.find('.tag-filter__count').text] }).to eq(expected)
end

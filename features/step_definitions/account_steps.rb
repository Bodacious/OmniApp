# frozen_string_literal: true

# Accounts, through the same data-testid hooks and visible labels on
# every stack. Each scenario starts with an empty database (the reset in
# features/support/env.rb) and a browser with no session.

When('I sign up as {string} with password {string}') do |email, password|
  sign_up(email, password)
end

Given('I have signed up as {string} with password {string}') do |email, password|
  sign_up(email, password)
  expect(page).to have_css(testid('current-user'), exact_text: email)
end

Given('I am signed in as {string}') do |email|
  sign_up(email, default_password)
  expect(page).to have_css(testid('current-user'), exact_text: email)
end

When('I sign in as {string} with password {string}') do |email, password|
  sign_in(email, password)
end

When('I sign out') do
  sign_out
end

When('I visit my lists') do
  visit '/'
end

Then('the page shows I am signed in as {string}') do |email|
  expect(page).to have_css(testid('current-user'), exact_text: email)
end

Then('I am asked to sign in') do
  expect(page).to have_css(testid('sign-in-form'))
  expect(page).to have_no_css(testid('current-user'))
  expect(page).to have_current_path('/sign_in')
end

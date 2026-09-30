Feature: Managing todos
  One set of scenarios, run unchanged against every stack in the matrix.
  Each stack is a real server, driven over HTTP through a real browser.

  Background:
    Given I open the todo list

  Scenario: There is nothing to do at first
    Then I see that there is nothing to do

  Scenario: Adding a todo
    When I add a todo titled "Buy milk"
    Then I see a todo titled "Buy milk"
    And I see 1 todo

  Scenario: A blank title is rejected
    When I add a todo titled "   "
    Then I see the error "Title can't be blank"
    And I see that there is nothing to do

  Scenario: Completing a todo
    Given I have added a todo titled "Buy milk"
    And I have added a todo titled "Walk the dog"
    When I complete the todo titled "Buy milk"
    Then the todo titled "Buy milk" is completed
    And the todo titled "Walk the dog" is not completed

  Scenario: Deleting a todo
    Given I have added a todo titled "Buy milk"
    And I have added a todo titled "Walk the dog"
    When I delete the todo titled "Buy milk"
    Then I see a todo titled "Walk the dog"
    But I don't see a todo titled "Buy milk"
    And I see 1 todo

  Scenario: Todos persist across page reloads
    Given I have added a todo titled "Buy milk"
    And I have added a todo titled "Walk the dog"
    And I have completed the todo titled "Walk the dog"
    When I reload the page
    Then I see the todos "Buy milk" and "Walk the dog", in that order
    And the todo titled "Walk the dog" is completed

  Scenario: Titles are shown exactly as typed
    When I add a todo titled "Fish & <b>chips</b> for \"tea\""
    Then I see a todo titled "Fish & <b>chips</b> for \"tea\""

  Scenario: The stack badge shows the configured stack
    Then the stack badge shows the configured stack

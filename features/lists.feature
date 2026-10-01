Feature: Lists
  Users own lists, and each list keeps its own todos. A list that
  belongs to someone else doesn't exist, as far as you can tell.

  Background:
    Given I am signed in as "ada@example.com"

  Scenario: Creating a list opens it
    When I create a list named "Groceries"
    Then I am looking at the list "Groceries"
    When I go back to my lists
    Then I see the lists "Groceries"

  Scenario: Lists are kept in the order they were made
    When I create a list named "Groceries"
    And I create a list named "Work"
    And I visit my lists
    Then I see the lists "Groceries" and "Work", in that order

  Scenario: Each list has its own todos
    Given I have a list named "Groceries" with a todo "Buy milk"
    And I have a list named "Work" with a todo "File taxes"
    When I open the list "Groceries"
    Then I see a todo titled "Buy milk"
    But I don't see a todo titled "File taxes"

  Scenario: Deleting a list
    Given I have a list named "Groceries" with a todo "Buy milk"
    And I have a list named "Work" with a todo "File taxes"
    When I delete the list "Groceries"
    Then I see the lists "Work"

  Scenario: A blank list name is rejected
    When I create a list named "   "
    Then I see the error "Name can't be blank"
    And I see that I have no lists

  Scenario: Users only ever see their own lists
    Given I have a list named "Ada's secrets" with a todo "Hide the cake"
    And I remember the address of this list
    When I sign out
    And I am signed in as "bob@example.com"
    Then I see that I have no lists
    When I visit the address I remembered
    Then I see that there is no such list

Feature: Tagging todos
  Tags belong to the domain's model. Every stack gets the same rules:
  tags are normalised (lowercase, no leading #), must be letters,
  numbers and dashes, and a todo can have at most five.

  Background:
    Given I open the todo list

  Scenario: Adding a todo with tags
    When I add a todo titled "Buy milk" tagged "Errands, #Home"
    Then the todo titled "Buy milk" has the tags "errands, home"

  Scenario: Tagging an existing todo
    Given I have added a todo titled "Buy milk"
    When I tag the todo titled "Buy milk" with "urgent"
    Then the todo titled "Buy milk" has the tags "urgent"

  Scenario: Removing a tag
    Given I have added a todo titled "Buy milk" tagged "home, urgent"
    When I remove the tag "urgent" from the todo titled "Buy milk"
    Then the todo titled "Buy milk" has the tags "home"

  Scenario: Filtering by tag
    Given I have added a todo titled "Buy milk" tagged "home"
    And I have added a todo titled "File taxes" tagged "work"
    And I have added a todo titled "Call mum" tagged "home"
    Then the tag filter lists "home (2), work (1)"
    When I filter by the tag "home"
    Then I see the todos "Buy milk" and "Call mum", in that order
    When I stop filtering by tag
    Then I see 3 todos

  Scenario: A malformed tag is rejected
    When I add a todo titled "Buy milk" tagged "not ok!"
    Then I see the error "Tags can only use letters, numbers and dashes"
    And I see that there is nothing to do

  Scenario: A todo can have at most five tags
    Given I have added a todo titled "Busy" tagged "a, b, c, d, e"
    When I tag the todo titled "Busy" with "f"
    Then I see the error "A todo can have at most 5 tags"
    And the todo titled "Busy" has the tags "a, b, c, d, e"

  Scenario: Tags persist across page reloads
    Given I have added a todo titled "Buy milk" tagged "home"
    When I reload the page
    Then the todo titled "Buy milk" has the tags "home"

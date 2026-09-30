Feature: The todo app on CRuby compiled to WebAssembly
  The domain runs in the browser. CRuby 3.4, compiled to WebAssembly,
  loads the same domain/ files as the server apps, with its own require,
  and the page never reloads: the server only hands over files.

  Background:
    Given the WebAssembly app has booted

  Scenario: The browser is running CRuby compiled to WebAssembly
    Then Ruby reports its platform as "wasm32-wasi"
    And the stack badge shows "ruby_wasm / sqlite_memory / dom"

  Scenario: Adding, completing and deleting todos without a page load
    When I add a todo titled "Buy milk"
    And I add a todo titled "Walk the dog"
    And I complete the todo titled "Buy milk"
    And I delete the todo titled "Walk the dog"
    Then I see the todos "Buy milk"
    And the todo titled "Buy milk" is completed
    And the page was never reloaded

  Scenario: A blank title is rejected by the domain
    When I add a todo titled "   "
    Then I see the error "Title can't be blank"
    And I see that there is nothing to do

  Scenario: Filtering and counting
    Given I have added the todos "Buy milk", "Walk the dog" and "Write the demo script"
    And I have completed the todo titled "Walk the dog"
    Then it says "2 items left"
    When I show the completed todos
    Then I see the todos "Walk the dog"
    When I show the active todos
    Then I see the todos "Buy milk" and "Write the demo script"

  Scenario: The inspector shows each call across the ports
    When I add a todo titled "Buy milk"
    Then the inspector shows these calls for it, in order:
      | layer    | call                     |
      | use_case | TodoList#add("Buy milk") |
      | port     | IdGenerator#next_id      |
      | adapter  | crypto.randomUUID()      |
      | port     | TodoRepository#save      |
      | adapter  | SQL INSERT INTO todos    |

  Scenario Outline: The domain's port contract passes in the browser on every adapter
    When I switch persistence to "<persistence>"
    And I run the port contract
    Then every contract test passes

    Examples:
      | persistence          |
      | ruby_memory          |
      | sqlite_memory        |
      | sqlite_local_storage |

  Scenario: Switching adapters while the app runs
    Given I have added the todos "Kept in SQLite"
    When I switch persistence to "ruby_memory"
    Then I see that there is nothing to do
    And the stack badge shows "ruby_wasm / ruby_memory / dom"
    When I switch persistence to "sqlite_memory"
    Then I see the todos "Kept in SQLite"

  Scenario: SQLite in localStorage keeps todos across a reload
    Given I switch persistence to "sqlite_local_storage"
    And I have added the todos "Survives a reload"
    When I reload the page
    Then I see the todos "Survives a reload"
    And the stack badge shows "ruby_wasm / sqlite_local_storage / dom"

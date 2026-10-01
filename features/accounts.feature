Feature: Accounts
  Signing up and in are the domain's Accounts use cases. Each app layer
  remembers who is signed in its own way (a Rails session, a Sinatra
  cookie session, a signed cookie in Node); the rules are the same.

  Scenario: Signing up signs you in
    When I sign up as "ada@example.com" with password "correct horse"
    Then the page shows I am signed in as "ada@example.com"
    And I see that I have no lists

  Scenario: Signing out, and back in
    Given I have signed up as "ada@example.com" with password "correct horse"
    When I sign out
    Then I am asked to sign in
    When I sign in as "Ada@Example.com" with password "correct horse"
    Then the page shows I am signed in as "ada@example.com"

  Scenario: A wrong password is rejected
    Given I have signed up as "ada@example.com" with password "correct horse"
    And I sign out
    When I sign in as "ada@example.com" with password "wrong horse"
    Then I see the error "Email or password is incorrect"
    And I am asked to sign in

  Scenario: An unknown email gets the same answer
    When I sign in as "nobody@example.com" with password "correct horse"
    Then I see the error "Email or password is incorrect"

  Scenario: An email can only have one account
    Given I have signed up as "ada@example.com" with password "correct horse"
    And I sign out
    When I sign up as "ada@example.com" with password "another horse"
    Then I see the error "That email already has an account"

  Scenario: Passwords must be at least 8 characters
    When I sign up as "ada@example.com" with password "short"
    Then I see the error "Passwords must be at least 8 characters"

  Scenario: A malformed email is rejected
    When I sign up as "not an email" with password "correct horse"
    Then I see the error "Enter a valid email address"

  Scenario: You have to sign in to see lists
    When I visit my lists
    Then I am asked to sign in

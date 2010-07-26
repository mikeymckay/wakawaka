Feature: Index page
  As a wakawaka user I want to be able to see a list of all projects
  
  @javascript
  Scenario: Visit index page
    Given I am on "the home page"
    Then I should see "Welcome to Wakawaka"
    And I should see "using test_data"
    And I should see "mateme"
    And I should see "git://github.com/baobab/mateme.git"

  Scenario: New Project
    Given I am on "the home page"
    When I press "New Project"
    And I fill in "Project Name" with "mateme-jeff"
    And I fill in "GitURL" with "git://github.com/jeffrafter/mateme.git"
    And I press "Save"
    Then I should see "mateme-jeff"
    And I should see "git://github.com/baobab/mateme.git"

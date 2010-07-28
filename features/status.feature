Feature: Viewing a project status page
  As a member of the specification team
  I want to be able to see a status page for each project
  So that I can see how much of the specs are implemented

  Scenario: Valid project
    Given I am on "the home page"
    When I follow "capybara-demo"
    Then I should see "capybara-demo"
    And I should see "Mike McKay"
    And I should see "Added one more piece of README"
  
  Scenario: Invalid project
    Given I am on "the home page"
    When I press "New Project"
    And I fill in "Project Name" with "Bad project"
    And I fill in "GitURI" with "git://example.com/totally_invalid"
    And I press "Save"
    Then I should see "Bad project"
    And I should see "git://example.com/totally_invalid"
    And I should see "Loading git data..."
    And I wait 1 second
    And I should see "Error"

  Scenario: Complete Project
    Given I am on "the home page"
    When I follow "capybara-demo"
    Then I should see "100% of scenarios passing"
    

  Scenario: Partially Completed Project
  Scenario: Project with invalid specifications

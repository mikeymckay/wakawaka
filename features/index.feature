Feature: Index page
  As a wakawaka user I want to be able to see a list of all projects
  
  Scenario: Visit index page
    Given I am on "the home page"
    Then I should see "Welcome to Wakawaka"
    And I should see "project-loaded-from-fixture"

  Scenario: New Project
    Given I am on "the home page"
    When I press "New Project"
    And I fill in "Project Name" with "another-capybara-demo"
    And I fill in "GitURI" with "git://github.com/mikeymckay/sinatra-cucumber-capybara-envjs.git"
    And I press "Save"
    Then I should see "another-capybara-demo"
    And I should see "git://github.com/mikeymckay/sinatra-cucumber-capybara-envjs.git"
    And I should see "/var/www/wakawaka"
    And I should see "Mike McKay"

  Scenario: Delete a project
    Given I am on "the home page"
    Then I should see "project-loaded-from-fixture"
    When I follow "Delete" within "#project-loaded-from-fixture"
    Then I should not see "project-loaded-from-fixture"
  

@api @data @api_data
Feature: List data bags via the REST API
  In order to know what data bags exists programatically
  As a Developer
  I want to list all the data bags

  Scenario: List data bags when none have been created
    Given a 'registration' named 'bobo' exists
      And there are no data bags
     When I authenticate as 'bobo'
      And I 'GET' the path '/data' 
     Then the inflated response should be an empty array

  Scenario: List data bags when one has been created
    Given a 'registration' named 'bobo' exists
      And a 'data_bag' named 'users' exists
     When I authenticate as 'bobo'
      And I 'GET' the path '/data'
     Then the inflated response should include '^http://.+/data/users$'

  Scenario: List data bags when two have been created
    Given a 'registration' named 'bobo' exists
      And a 'data_bag' named 'users' exists
      And a 'data_bag' named 'rubies' exists
     When I authenticate as 'bobo'
      And I 'GET' the path '/data'
     Then the inflated response should be '2' items long
      And the inflated response should include '^http://.+/data/users$'
      And the inflated response should include '^http://.+/data/rubies$'

  Scenario: List data bags when you are not authenticated 
     When I 'GET' the path '/data' 
     Then I should get a '401 "Unauthorized"' exception


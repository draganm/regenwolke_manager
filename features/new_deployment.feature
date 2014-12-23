Feature: new deployment api

  Scenario: new deployment
    When new deployment has been posted
    Then regenwolke auton should have deploy_application step scheduled

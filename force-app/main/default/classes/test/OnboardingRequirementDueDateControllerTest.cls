/**
 * @description Tests for OnboardingRequirementDueDateController
 * @group Onboarding
 * @notes
 * - No SeeAllData
 * - Uses Test.startTest/stopTest
 * - Tests edge cases and valid scenarios
 */
@isTest
private class OnboardingRequirementDueDateControllerTest {
  @TestSetup
  static void setup() {
    TestOnboardingRequirementFactory.create(true);
  }

  @isTest
  static void testUpdateDueDate_withValidInputs() {
    Onboarding_Requirement__c requirement = [
      SELECT Id
      FROM Onboarding_Requirement__c
      LIMIT 1
    ];
    List<Id> requirementIds = new List<Id>{ requirement.Id };
    Date newDueDate = Date.today().addDays(5);
    String reason = 'Rep requested extension for compliance review';

    Test.startTest();
    OnboardingRequirementDueDateController.updateDueDate(
      requirementIds,
      newDueDate,
      reason
    );
    Test.stopTest();

    Onboarding_Requirement__c updated = [
      SELECT Due_Date__c, Due_Date_Override_Reason__c
      FROM Onboarding_Requirement__c
      WHERE Id = :requirement.Id
    ];
    System.assertEquals(
      newDueDate,
      updated.Due_Date__c,
      'Due date should be updated'
    );
    System.assertEquals(
      reason,
      updated.Due_Date_Override_Reason__c,
      'Reason should be stored'
    );
  }

  @isTest
  static void testUpdateDueDate_withNullRequirementIds() {
    Boolean thrown = false;
    Test.startTest();
    try {
      OnboardingRequirementDueDateController.updateDueDate(
        null,
        Date.today(),
        'Test reason'
      );
    } catch (Exception ex) {
      thrown = true;
    }
    Test.stopTest();
    System.assert(thrown, 'Expected exception for null requirementIds');
  }

  @isTest
  static void testUpdateDueDate_withEmptyRequirementIds() {
    Boolean thrown = false;
    Test.startTest();
    try {
      OnboardingRequirementDueDateController.updateDueDate(
        new List<Id>(),
        Date.today(),
        'Test reason'
      );
    } catch (Exception ex) {
      thrown = true;
    }
    Test.stopTest();
    System.assert(thrown, 'Expected exception for empty requirementIds');
  }

  @isTest
  static void testUpdateDueDate_withNullDueDate() {
    Onboarding_Requirement__c requirement = [
      SELECT Id
      FROM Onboarding_Requirement__c
      LIMIT 1
    ];
    Boolean thrown = false;
    Test.startTest();
    try {
      OnboardingRequirementDueDateController.updateDueDate(
        new List<Id>{ requirement.Id },
        null,
        'Test reason'
      );
    } catch (Exception ex) {
      thrown = true;
    }
    Test.stopTest();
    System.assert(thrown, 'Expected exception for null due date');
  }

  @isTest
  static void testUpdateDueDate_withBlankReason() {
    Onboarding_Requirement__c requirement = [
      SELECT Id
      FROM Onboarding_Requirement__c
      LIMIT 1
    ];
    Boolean thrown = false;
    Test.startTest();
    try {
      OnboardingRequirementDueDateController.updateDueDate(
        new List<Id>{ requirement.Id },
        Date.today(),
        ''
      );
    } catch (Exception ex) {
      thrown = true;
    }
    Test.stopTest();
    System.assert(thrown, 'Expected exception for blank reason');
  }

  @isTest
  static void testUpdateDueDate_withNullReason() {
    Onboarding_Requirement__c requirement = [
      SELECT Id
      FROM Onboarding_Requirement__c
      LIMIT 1
    ];
    Boolean thrown = false;
    Test.startTest();
    try {
      OnboardingRequirementDueDateController.updateDueDate(
        new List<Id>{ requirement.Id },
        Date.today(),
        null
      );
    } catch (Exception ex) {
      thrown = true;
    }
    Test.stopTest();
    System.assert(thrown, 'Expected exception for null reason');
  }
}

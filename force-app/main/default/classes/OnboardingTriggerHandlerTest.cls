@isTest
private class OnboardingTriggerHandlerTest {

    @isTest
    static void testAfterInsert() {
        // Arrange: Create related records
        Account acc = new Account(Name = 'Trigger Test Account');
        insert acc;

        // Create Onboarding__c record
        Onboarding__c onboarding = new Onboarding__c(
            Account__c = acc.Id
        );

        // Act: Insert onboarding record (which triggers the trigger)
        insert onboarding;

        // Assert: No unhandled exceptions = pass
        // Optionally, you could add asserts on any extra logic you add in the future.
    }

    @isTest
    static void testBeforeUpdate() {
        // Arrange: Create and insert onboarding
        Account acc = new Account(Name = 'Update Test Account');
        insert acc;
    
        Onboarding__c onboarding = new Onboarding__c(Account__c = acc.Id);
        insert onboarding;
    
        // Act: Fetch and verify status value
        Onboarding__c result = [
            SELECT Onboarding_Status__c
            FROM Onboarding__c
            WHERE Id = :onboarding.Id
        ];
    
        System.assertNotEquals(null, result.Onboarding_Status__c, 'Expected Onboarding_Status__c to be set by helper logic');
    
        // Modify onboarding to simulate update
        onboarding.Account__c = acc.Id;
    
        // Act: Update onboarding (trigger will fire again)
        update onboarding;
    }
    
}
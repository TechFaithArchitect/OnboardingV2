@isTest
public class RecipientGroupEmailOrchestratorTest {

    private static void setupRecipientGroupWithUser(Id vendorProgramId, Id userId) {
        Recipient_Group__c recipientGroup = TestDataFactory.createRecipientGroup(true, true);

        insert new Vendor_Program_Recipient_Group__c(
            Vendor_Program__c = vendorProgramId,
            Recipient_Group__c = recipientGroup.Id,
            Is_Active__c = true
        );

        insert new Recipient_Group_Member__c(
            Recipient_Group__c = recipientGroup.Id,
            Recipient_User__c = userId
        );
    }

    @isTest
    static void testGetEmails() {
        // CREATE DATA
        User standardUser = TestDataFactory.createStandardUser(true);
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createRootAndActiveChildCustomization(vendor, true);

        setupRecipientGroupWithUser(vendorProgram.Id, standardUser.Id);

        // ACTIVATE
        List<String> emails = RecipientGroupEmailOrchestrator.getEmails(vendorProgram.Id);

        // ASSERT
        System.assertEquals(1, emails.size(), 'Expected one email address');
        System.assertEquals(standardUser.Email, emails[0], 'Email should match the user');
    }

    @isTest
    static void testOrchestratorCallsService() {
        // CREATE DATA
        User user = TestDataFactory.createStandardUser(true);
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createRootAndActiveChildCustomization(vendor, true);

        setupRecipientGroupWithUser(vendorProgram.Id, user.Id);

        // ACTIVATE
        Test.startTest();
        List<String> emails = RecipientGroupEmailOrchestrator.getEmails(vendorProgram.Id);
        Test.stopTest();

        // ASSERT
        System.assertEquals(1, emails.size(), 'Orchestrator should return one email');
        System.assertEquals(user.Email, emails[0], 'Email should match the expected user');
    }
}
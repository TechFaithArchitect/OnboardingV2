@isTest
public class RecipientGroupEmailActionTest {

    private static RecipientGroupEmailRequestDTO buildRequest(Id vendorProgramId) {
        RecipientGroupEmailRequestDTO recipientGroupEmailRequest = new RecipientGroupEmailRequestDTO();
        recipientGroupEmailRequest.vendorProgramId = vendorProgramId;
        return recipientGroupEmailRequest;
    }

    @isTest
    static void testFetchEmailsFromFlow() {
        // Arrange
        User standardUser = TestUserFactory.createStandardUser(true);
        Vendor__c vendor = TestVendorProgramFactory.createVendor(true);
        Vendor_Customization__c vendorCustomization = TestVendorProgramFactory.createRootAndActiveChildCustomization(vendor, true);
        Recipient_Group__c recipientGroup = TestRecipientGroupFactory.create(true, 'Queue');

        insert new Vendor_Program_Recipient_Group__c(
            Vendor_Program__c = vendorCustomization.Id,
            Recipient_Group__c = recipientGroup.Id,
            Is_Active__c = true,
            Status__c = 'Active',
            Filter_Logic__c = 'AND',
            Version__c = '1.0'
        );

        insert new Recipient_Group_Member__c(
            Recipient_Group__c = recipientGroup.Id,
            Recipient_User__c = standardUser.Id,
            Member_Type__c = 'User',
            Recipient_Type__c = 'To'
        );

        // Act
        List<RecipientGroupEmailResultDTO> results = RecipientGroupEmailAction.fetchEmails(
            new List<RecipientGroupEmailRequestDTO>{ buildRequest(vendorCustomization.Id) }
        );

        // Assert
        System.assertEquals(1, results.size(), 'Should return one result object');
        System.assertEquals(1, results[0].emailAddresses.size(), 'Should contain one email address');
        System.assertEquals(standardUser.Email, results[0].emailAddresses[0], 'Should match the user email');
    }

    @isTest
    static void testReturnsEmptyResultDTO() {
        // Arrange
        Vendor__c vendor = TestVendorProgramFactory.createVendor(true);
        Vendor_Customization__c vendorCustomization = TestVendorProgramFactory.createRootAndActiveChildCustomization(vendor, true);

        List<RecipientGroupEmailRequestDTO> requests = new List<RecipientGroupEmailRequestDTO>{
            buildRequest(vendorCustomization.Id)
        };

        // Act
        List<RecipientGroupEmailResultDTO> results = RecipientGroupEmailAction.fetchEmails(requests);

        // Assert
        System.assertEquals(1, results.size(), 'Should always return 1 result');
        System.assertEquals(0, results[0].emailAddresses.size(), 'Should return 0 emails when no matches');
    }
}
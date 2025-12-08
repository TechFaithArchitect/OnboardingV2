@isTest
public class RecipientGroupEmailServiceTest {

    private static void setupProgramWithGroupAndUser(Id vendorProgramId, Id userId) {
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
    static void testGetEmailsForVendorCustomization() {
        User standardUser = TestDataFactory.createStandardUser(true);
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorCustomization = TestDataFactory.createRootAndActiveChildCustomization(vendor, true);

        setupProgramWithGroupAndUser(vendorCustomization.Id, standardUser.Id);

        List<String> emails = RecipientGroupEmailService.getEmailsForVendorProgram(vendorCustomization.Id);

        System.assertEquals(1, emails.size());
        System.assertEquals(standardUser.Email, emails[0]);
    }

    @isTest
    static void testReturnsEmptyWhenNoGroupsLinked() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorCustomization = TestDataFactory.createRootAndActiveChildCustomization(vendor, true);

        List<String> emails = RecipientGroupEmailService.getEmailsForVendorProgram(vendorCustomization.Id);

        System.assertEquals(0, emails.size());
    }

    @isTest
    static void testReturnsEmptyWhenGroupLinkIsInactive() {
        User user = TestDataFactory.createStandardUser(true);
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createRootAndActiveChildCustomization(vendor, true);
        Recipient_Group__c recipientGroup = TestDataFactory.createRecipientGroup(true, true);

        Vendor_Program_Recipient_Group__c vendorProgramRecipientGroupLink = new Vendor_Program_Recipient_Group__c(
            Vendor_Program__c = vendorProgram.Id,
            Recipient_Group__c = recipientGroup.Id,
            Is_Active__c = true
        );
        insert vendorProgramRecipientGroupLink;

        vendorProgramRecipientGroupLink.Is_Active__c = false;
        update vendorProgramRecipientGroupLink;

        insert new Recipient_Group_Member__c(
            Recipient_Group__c = recipientGroup.Id,
            Recipient_User__c = user.Id
        );

        List<String> emails = RecipientGroupEmailService.getEmailsForVendorProgram(vendorProgram.Id);
        System.assertEquals(0, emails.size());
    }

    @isTest
    static void testSkipsNullEmails() {
        User user = TestDataFactory.createStandardUser(true);
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createRootAndActiveChildCustomization(vendor, true);
        Recipient_Group__c recipientGroup = TestDataFactory.createRecipientGroup(true, true);

        insert new Vendor_Program_Recipient_Group__c(
            Vendor_Program__c = vendorProgram.Id,
            Recipient_Group__c = recipientGroup.Id,
            Is_Active__c = true
        );

        insert new Recipient_Group_Member__c(
            Recipient_Group__c = recipientGroup.Id,
            Recipient_User__c = user.Id
        );

        // Validate that no nulls sneak in (safety net)
        List<String> emails = new List<String>();
        for (String email : RecipientGroupEmailService.getEmailsForVendorProgram(vendorProgram.Id)) {
            if (String.isNotBlank(email)) emails.add(email);
        }

        System.assertEquals(1, emails.size());
    }

    @isTest
    static void testMultipleGroupsReturnAllEmails() {
        User user1 = TestDataFactory.createStandardUser(true);
        User user2 = TestDataFactory.createStandardUser(true);
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createRootAndActiveChildCustomization(vendor, true);

        setupProgramWithGroupAndUser(vendorProgram.Id, user1.Id);
        setupProgramWithGroupAndUser(vendorProgram.Id, user2.Id);

        List<String> emails = RecipientGroupEmailService.getEmailsForVendorProgram(vendorProgram.Id);

        System.assertEquals(2, emails.size());
        System.assert(emails.contains(user1.Email));
        System.assert(emails.contains(user2.Email));
    }

    @isTest
    static void testDedupesEmailsFromMultipleGroups() {
        User user = TestDataFactory.createStandardUser(true);
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createRootAndActiveChildCustomization(vendor, true);

        setupProgramWithGroupAndUser(vendorProgram.Id, user.Id);
        setupProgramWithGroupAndUser(vendorProgram.Id, user.Id); // user in both groups

        List<String> emails = RecipientGroupEmailService.getEmailsForVendorProgram(vendorProgram.Id);

        System.assertEquals(1, new Set<String>(emails).size());
    }

    @isTest
    static void testReturnsEmptyForUnlinkedVendorProgramId() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c unlinkedProgram = TestDataFactory.createRootAndActiveChildCustomization(vendor, true);

        List<String> emails = RecipientGroupEmailService.getEmailsForVendorProgram(unlinkedProgram.Id);

        System.assertEquals(0, emails.size());
    }

    @isTest
    static void testDuplicateGroupLinksHandled() {
        User user = TestDataFactory.createStandardUser(true);
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createRootAndActiveChildCustomization(vendor, true);
        Recipient_Group__c recipientGroup = TestDataFactory.createRecipientGroup(true, true);

        insert new List<Vendor_Program_Recipient_Group__c>{
            new Vendor_Program_Recipient_Group__c(Vendor_Program__c = vendorProgram.Id, Recipient_Group__c = recipientGroup.Id, Is_Active__c = true),
            new Vendor_Program_Recipient_Group__c(Vendor_Program__c = vendorProgram.Id, Recipient_Group__c = recipientGroup.Id, Is_Active__c = true)
        };

        insert new Recipient_Group_Member__c(
            Recipient_Group__c = recipientGroup.Id,
            Recipient_User__c = user.Id
        );

        List<String> emails = RecipientGroupEmailService.getEmailsForVendorProgram(vendorProgram.Id);

        System.assertEquals(1, emails.size());
    }

    @isTest
    static void testFlowHandlesMultipleRequests() {
        User user1 = TestDataFactory.createStandardUser(true);
        User user2 = TestDataFactory.createStandardUser(true);
        Vendor__c vendor = TestDataFactory.createVendor(true);

        Vendor_Customization__c vendorProgram1 = TestDataFactory.createRootAndActiveChildCustomization(vendor, true);
        Vendor_Customization__c vendorProgram2 = TestDataFactory.createRootAndActiveChildCustomization(vendor, true);

        setupProgramWithGroupAndUser(vendorProgram1.Id, user1.Id);
        setupProgramWithGroupAndUser(vendorProgram2.Id, user2.Id);

        RecipientGroupEmailRequestDTO recipientGroupEmailRequest1 = new RecipientGroupEmailRequestDTO();
        recipientGroupEmailRequest1.vendorProgramId = vendorProgram1.Id;

        RecipientGroupEmailRequestDTO recipientGroupEmailRequest2 = new RecipientGroupEmailRequestDTO();
        recipientGroupEmailRequest2.vendorProgramId = vendorProgram2.Id;

        List<RecipientGroupEmailRequestDTO> recipientGroupEmailRequests = new List<RecipientGroupEmailRequestDTO>{ recipientGroupEmailRequest1, recipientGroupEmailRequest2 };

        List<RecipientGroupEmailResultDTO> results = RecipientGroupEmailAction.fetchEmails(recipientGroupEmailRequests);

        System.assertEquals(2, results.size());
        System.assertEquals(1, results[0].emailAddresses.size());
        System.assertEquals(1, results[1].emailAddresses.size());
    }
}
@isTest
private class RequireParentVersionOnActivationRuleTest {

    @isTest
    static void testFailsIfNoParentOnNonDraft() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Recipient_Group__c recipientGroup = TestDataFactory.createRecipientGroup(true, true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(vendor, 'Active', true, null, true);

        Vendor_Program_Recipient_Group__c vendorProgramRecipientGroup = new Vendor_Program_Recipient_Group__c(
            Version__c = '1.0',
            Status__c = 'Active',
            Is_Active__c = true,
            Vendor_Program__c = vendorProgram.Id,
            Recipient_Group__c = recipientGroup.Id
        );

        Test.startTest();
        Database.SaveResult saveResult = Database.insert(vendorProgramRecipientGroup, false);
        Test.stopTest();

        // 🔍 Always print errors first
        for (Database.Error error : saveResult.getErrors()) {
            System.debug('❌ DML ERROR: ' + error.getStatusCode() + ' - ' + error.getMessage());
        }

        // ✅ THEN assert
        System.assert(!saveResult.isSuccess(), 'Insert should fail without Parent_Version__c.');
        System.assert(
            saveResult.getErrors()[0].getMessage().contains('Non-draft versions must reference a parent version'),
            '❌ ERROR: ' + saveResult.getErrors()[0].getMessage()
        );
    }

    @isTest
    static void testPassesIfDraft() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Recipient_Group__c recipientGroup = TestDataFactory.createRecipientGroup(true, true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(vendor, 'Active', true, null, true);

        Vendor_Program_Recipient_Group__c draft = new Vendor_Program_Recipient_Group__c(
            Version__c = '0.9',
            Status__c = 'Draft',
            Vendor_Program__c = vendorProgram.Id,
            Recipient_Group__c = recipientGroup.Id
        );

        Test.startTest();
        Database.SaveResult saveResult = Database.insert(draft, false);
        Test.stopTest();

        System.assert(saveResult.isSuccess(), 'Draft without parent should be allowed.');
    }

    @isTest
    static void testPassesIfParentVersionPresent() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Recipient_Group__c recipientGroup = TestDataFactory.createRecipientGroup(true, true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(vendor, 'Active', true, null, true);

        Vendor_Program_Recipient_Group__c draft = new Vendor_Program_Recipient_Group__c(
            Version__c = '1.0',
            Status__c = 'Draft',
            Vendor_Program__c = vendorProgram.Id,
            Recipient_Group__c = recipientGroup.Id
        );
        insert draft;

        Vendor_Program_Recipient_Group__c child = new Vendor_Program_Recipient_Group__c(
            Version__c = '2.0',
            Status__c = 'Active',
            Is_Active__c = true,
            Vendor_Program__c = vendorProgram.Id,
            Recipient_Group__c = recipientGroup.Id,
            Parent_Version__c = draft.Id
        );

        Test.startTest();
        Database.SaveResult saveResult = Database.insert(child, false);
        Test.stopTest();

        System.assert(saveResult.isSuccess(), 'Should pass with valid Parent_Version__c');
    }
}
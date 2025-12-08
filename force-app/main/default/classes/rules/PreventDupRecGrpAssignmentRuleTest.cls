@IsTest
private class PreventDupRecGrpAssignmentRuleTest {

    @IsTest
    static void testFailsWhenDuplicateAlreadyInDatabase() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Recipient_Group__c recipientGroup = TestDataFactory.createRecipientGroup(true, true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(vendor, 'Active', true, null, true);

        Vendor_Program_Recipient_Group__c existing = new Vendor_Program_Recipient_Group__c(
            Version__c = '1.0',
            Status__c = 'Active',
            Is_Active__c = true,
            Vendor_Program__c = vendorProgram.Id,
            Recipient_Group__c = recipientGroup.Id
        );
        insert existing;

        Vendor_Program_Recipient_Group__c duplicate = new Vendor_Program_Recipient_Group__c(
            Version__c = '2.0',
            Status__c = 'Active',
            Is_Active__c = true,
            Vendor_Program__c = vendorProgram.Id,
            Recipient_Group__c = recipientGroup.Id,
            Parent_Version__c = existing.Id
        );

        Test.startTest();
        Database.SaveResult saveResult = Database.insert(duplicate, false);
        Test.stopTest();

        System.assert(!saveResult.isSuccess(), 'Duplicate record should fail due to existing DB record.');
        System.assert(
            saveResult.getErrors()[0].getMessage().contains('already has this Recipient Group'),
            'Expected duplicate error from DB presence.'
        );
    }

    @IsTest
    static void testFailsOnInMemoryDuplicate() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Recipient_Group__c recipientGroup = TestDataFactory.createRecipientGroup(true, true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(vendor, 'Active', true, null, true);

        Vendor_Program_Recipient_Group__c vendorProgramRecipientGroup1 = new Vendor_Program_Recipient_Group__c(
            Version__c = '1.0',
            Status__c = 'Active',
            Is_Active__c = true,
            Vendor_Program__c = vendorProgram.Id,
            Recipient_Group__c = recipientGroup.Id
        );

        Vendor_Program_Recipient_Group__c vendorProgramRecipientGroup2 = new Vendor_Program_Recipient_Group__c(
            Version__c = '2.0',
            Status__c = 'Active',
            Is_Active__c = true,
            Vendor_Program__c = vendorProgram.Id,
            Recipient_Group__c = recipientGroup.Id
        );

        Test.startTest();
        Database.SaveResult[] saveResults = Database.insert(new List<Vendor_Program_Recipient_Group__c> { vendorProgramRecipientGroup1, vendorProgramRecipientGroup2 }, false);
        Test.stopTest();

        System.assert(saveResults[1].isSuccess() == false, 'Second record in same transaction should fail.');
        System.assert(
            saveResults[1].getErrors()[0].getMessage().contains('same transaction'),
            'Expected in-memory duplicate validation error.'
        );
    }
}
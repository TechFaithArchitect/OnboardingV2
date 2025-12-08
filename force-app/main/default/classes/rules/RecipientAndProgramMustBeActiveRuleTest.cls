@IsTest
private class RecipientAndProgramMustBeActiveRuleTest {

    @IsTest
    static void testFailsIfRecipientOrProgramInactive() {
        Vendor__c vendor = TestDataFactory.createVendor(true);

        Recipient_Group__c inactiveGroup = TestDataFactory.createRecipientGroup(false, true);
        Vendor_Customization__c parent = TestDataFactory.createVendorCustomization(vendor, 'Draft', false, null, true);
        Vendor_Customization__c inactiveProgram = TestDataFactory.createVendorCustomization(vendor, 'Active', false, parent.Id, true);

        Vendor_Program_Recipient_Group__c vendorProgramRecipientGroup = new Vendor_Program_Recipient_Group__c(
            Version__c = '1.0',
            Status__c = 'Active',
            Is_Active__c = true,
            Recipient_Group__c = inactiveGroup.Id,
            Vendor_Program__c = inactiveProgram.Id
        );

        Test.startTest();
        Database.SaveResult saveResult = Database.insert(vendorProgramRecipientGroup, false);
        Test.stopTest();

        System.assert(!saveResult.isSuccess(), 'Expected failure when Recipient Group or Program is inactive.');
        System.assert(
            saveResult.getErrors()[0].getMessage().contains('Recipient Group must be active') ||
            saveResult.getErrors()[0].getMessage().contains('Vendor Program must be active'),
            'Expected error about inactive Recipient Group or Program.'
        );
    }
}


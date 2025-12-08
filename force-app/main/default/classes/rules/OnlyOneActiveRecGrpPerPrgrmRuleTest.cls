@IsTest
private class OnlyOneActiveRecGrpPerPrgrmRuleTest {

    @IsTest
    static void testSecondActiveFailsDueToExistingActive() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Recipient_Group__c recipientGroup = TestDataFactory.createRecipientGroup(true, true);
        Vendor_Customization__c parent = TestDataFactory.createVendorCustomization(vendor, 'Draft', false, null, true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(vendor, 'Active', true, parent.Id, true);

        Vendor_Program_Recipient_Group__c version1 = new Vendor_Program_Recipient_Group__c(
            Version__c = '1.0',
            Status__c = 'Active',
            Is_Active__c = true,
            Recipient_Group__c = recipientGroup.Id,
            Vendor_Program__c = vendorProgram.Id
        );
        insert version1;

        Vendor_Program_Recipient_Group__c version2 = new Vendor_Program_Recipient_Group__c(
            Version__c = '2.0',
            Status__c = 'Active',
            Is_Active__c = true,
            Recipient_Group__c = recipientGroup.Id,
            Vendor_Program__c = vendorProgram.Id
        );

        Test.startTest();
        Database.SaveResult saveResult = Database.insert(version2, false);
        Test.stopTest();

        System.assert(!saveResult.isSuccess(), 'Expected second active version to be rejected.');
        System.assert(
            saveResult.getErrors()[0].getMessage().contains('Only one active'),
            'Expected error about only one active record per recipient group per program.'
        );
    }
}
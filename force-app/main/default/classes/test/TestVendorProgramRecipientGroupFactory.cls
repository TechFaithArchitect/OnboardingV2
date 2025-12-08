@isTest
public class TestVendorProgramRecipientGroupFactory {

    public static Vendor_Program_Recipient_Group__c create(Boolean doInsert) {
        Vendor_Customization__c vendorProgram = TestVendorProgramFactory.createVendorWithCustomization(doInsert).customization;
        Recipient_Group__c recipientGroup = TestRecipientGroupFactory.create(doInsert);

        Vendor_Program_Recipient_Group__c vendorProgramRecipientGroup = new Vendor_Program_Recipient_Group__c(
            Vendor_Program__c = vendorProgram.Id,
            Recipient_Group__c = recipientGroup.Id,
            Is_Active__c = true,
            Status__c = 'Active',
            Filter_Logic__c = 'AND',
            Version__c = '1.0'
        );

        if (doInsert) insert vendorProgramRecipientGroup;
        return vendorProgramRecipientGroup;
    }
}

@isTest
public class VendorProgramGrpMmbrTrgHndlrTest {

    @isTest
    static void testSingleTargetAllowed() {
        Vendor__c vendor = new Vendor__c(Name = 'Test Vendor', Active__c = true);
        insert vendor;

        Vendor_Program_Group__c vpg = new Vendor_Program_Group__c(
            Name = 'Test Group',
            Active__c = true,
            Logic_Type__c = 'AND',
            Label__c = 'Test Group Label'
        );
        insert vpg;

        Vendor_Customization__c customization1 = new Vendor_Customization__c(Vendor__c = vendor.Id);
        insert customization1;

        Vendor_Program_Group_Member__c member1 = new Vendor_Program_Group_Member__c(
            Vendor_Program_Group__c = vpg.Id,
            Required_Customization__c = customization1.Id,
            Is_Target__c = true,
            Active__c = true
        );

        Test.startTest();
        insert member1;
        Test.stopTest();
    }

    @isTest
    static void testSecondTargetFails() {
        Vendor__c vendor = new Vendor__c(Name = 'Test Vendor', Active__c = true);
        insert vendor;

        Vendor_Program_Group__c vpg = new Vendor_Program_Group__c(
            Name = 'Test Group',
            Active__c = true,
            Label__c = 'Test Group Label',
            Logic_Type__c = 'AND'
        );
        insert vpg;

        Vendor_Customization__c customization1 = new Vendor_Customization__c(Vendor__c = vendor.Id);
        Vendor_Customization__c customization2 = new Vendor_Customization__c(Vendor__c = vendor.Id);
        insert new List<Vendor_Customization__c>{ customization1, customization2 };

        Vendor_Program_Group_Member__c member1 = new Vendor_Program_Group_Member__c(
            Vendor_Program_Group__c = vpg.Id,
            Required_Customization__c = customization1.Id,
            Is_Target__c = true,
            Active__c = true
        );

        Vendor_Program_Group_Member__c member2 = new Vendor_Program_Group_Member__c(
            Vendor_Program_Group__c = vpg.Id,
            Required_Customization__c = customization2.Id,
            Is_Target__c = true,
            Active__c = true
        );

        Test.startTest();
        insert member1;
        Database.SaveResult result = Database.insert(member2, false);
        Test.stopTest();

        System.assertEquals(false, result.isSuccess(), 'Second member should fail due to duplicate target.');
        System.assert(
            result.getErrors()[0].getMessage().contains(Label.Vendor_Program_Group_Target_Message),
            'Expected error message to contain: ' + Label.Vendor_Program_Group_Target_Message
        );
    }
}
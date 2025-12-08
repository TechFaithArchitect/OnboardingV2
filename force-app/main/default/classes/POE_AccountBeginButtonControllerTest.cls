@isTest
public class POE_AccountBeginButtonControllerTest {
    @testSetup
    static void setupData() {
        UserRole userRole = [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName = 'Sales_Supervisor' LIMIT 1];
        User adminUser = [SELECT Id, UserRoleId FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        adminUser.UserRoleId = userRole.Id;
        adminUser.isActive = true;
        update adminUser;

        RecordType rtype = [
            SELECT Name, Id
            FROM RecordType
            WHERE sObjectType = 'Account' AND Name = 'Dealer' AND isActive = TRUE
            LIMIT 1
        ];

        System.runAs(adminUser) {
            Account testAcc = new Account(
                Name = 'Test Account',
                ShippingStreet = 'Test Street',
                POE_Dealer_Office_Email__c = 'DealerEmail@testorg1.com',
                P10_Invoice_Account__c = 'Example',
                recordTypeId = rtype.Id
            );
            insert testAcc;

            Contact userContact = new Contact(
                FirstName = 'test',
                LastName = 'test',
                AccountId = testAcc.Id,
                POE_Programs_Available__c = 'EarthLink;Windstream',
                POE_Retail_Programs__c = 'EarthLink;Windstream',
                POE_Event_Programs__c = 'EarthLink;Windstream',
                D2D_Programs__c = 'EarthLink',
                MDU_Programs_Available__c = 'Windstream'
            );
            insert userContact;

            Profile p = TestHelper.getGeneralProfile();
            User u = new User(
                Alias = 'standt',
                Email = '11052022standarduser@testorg.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'Testing',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = p.Id,
                ContactId = userContact.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                UserName = '11052022GDGstandarduser@testorg.com'
            );
            insert u;

            insert new POE_ProgramZipCode__c(Program__c = 'EarthLink', Zip_Code__c = '12345');
            insert new POE_ProgramZipCode__c(Program__c = 'Windstream', Zip_Code__c = '12345');
        }

    }

    @isTest
    static void testGetAvailablePrograms() {
        User testUser = [SELECT Id FROM User WHERE Username = '11052022GDGstandarduser@testorg.com' LIMIT 1];
        System.runAs(testUser) {
            Map<String, Object> inputMap = new Map<String, Object>();
            inputMap.put('zip', '12345');

            POE_AccountBeginButtonController.ResponseWrapper response = POE_AccountBeginButtonController.getAvailablePrograms(
                inputMap
            );
            System.assertNotEquals(null, response, 'No response returned');
            Map<String, Object> result = response.result;
            System.assertNotEquals(null, result, 'No result returned');
            Set<String> expectedZipPrograms = new Set<String>{ 'EarthLink', 'Windstream' };
            System.assertEquals(expectedZipPrograms, result.get('zipPrograms'), 'No zip code programs were returned');
        }
    }
}
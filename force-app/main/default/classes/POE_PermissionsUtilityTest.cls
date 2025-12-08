@isTest
public class POE_PermissionsUtilityTest {
    @TestSetup
    static void setup() {
        User adminUser = TestHelper.getAdminUser();
        UserRole userRole = [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName = 'Sales_Supervisor' LIMIT 1];
        adminUser.UserRoleId = userRole.Id;
        adminUser.isActive = true;

        RecordType rtype = [
            SELECT Name, Id
            FROM RecordType
            WHERE sObjectType = 'Account' AND Name = 'Dealer' AND isActive = TRUE
            LIMIT 1
        ];

        System.runAs(adminUser) {
            Account testAcc = new Account(
                Name = 'Test',
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
                POE_Functional_Role__c = 'Office Manager',
                POE_Representative_Type__c = 'Phone Sales'
            );
            insert userContact;

            Profile p = TestHelper.getGeneralProfile();
            User u = new User(
                Alias = 'standt',
                Email = 'POEProfileUtilityTest27052024@testorg.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'Testing',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = p.Id,
                ContactId = userContact.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                UserName = 'POEProfileUtilityTest27052024@testorg.com'
            );
            insert u;

            System.runAs(u) {
                PV_TestDataFactory.assignPermissionSetGroupToUser(true, u, POE_PermissionsUtility.OWNER_PSG);
            }
        }
    }

    @isTest
    static void userIsAgentOrOwnerTest() {
        User testUser = [
            SELECT Id, Profile.Name
            FROM User
            WHERE UserName = 'POEProfileUtilityTest27052024@testorg.com'
        ];

        System.runAs(testUser) {
            Test.startTest();
            POE_PermissionsUtility.UserRoleInformation result = POE_PermissionsUtility.userIsAgentOrOwner();
            Test.stopTest();

            Assert.isTrue(result.isOwner, 'The result was not true for an Owner user.');
        }
    }

    @isTest
    static void getPermissionsAndGroupsByNameTest() {
        Test.startTest();
        Map<String, Id> permSetsOrGroups = POE_PermissionsUtility.getPermissionsAndGroupsByName();
        Test.stopTest();

        Assert.isFalse(permSetsOrGroups.isEmpty(), 'No PermissionSets or PermissionSetGroups were retrieved.');
    }
}
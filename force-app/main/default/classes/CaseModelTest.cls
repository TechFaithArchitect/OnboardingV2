@isTest
public class CaseModelTest {
    @TestSetup
    static void makeData() {
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
                POE_Functional_Role__c = 'Office Manager'
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
        }
    }

    @isTest
    static void test_GetChuzoCases() {
        User testUser = [SELECT Id FROM User WHERE UserName = '11052022GDGstandarduser@testorg.com'];
        System.runAs(testUser) {
            List<Case> cases = new List<Case>();

            for (Integer i = 0; i < 10; i++) {
                Case newCase = new Case(
                    Status = 'New',
                    Subject = 'Test Case ' + i,
                    Type = 'Commissions',
                    Description = 'Test Description ' + i
                );
                cases.add(newCase);
            }

            insert cases;

            test.startTest();
            CaseModel.ResponseWrapper response = CaseModel.getChuzoCases();
            test.stopTest();

            List<Case> responseCases = (List<Case>) response.result.get('Cases');
            String agentId = (String) response.result.get('agentId');

            System.assertEquals(10, responseCases.size(), 'Should return 10 inserted cases');
            System.assertEquals(testUser.Id, agentId, 'Should return correct agent ID');
            System.assertEquals('Test Case 0', responseCases[0].Subject, 'Should return correct case data');
        }
    }

    @isTest
    static void test_GetChuzoCases_NoCases() {
        User testUser = [SELECT Id FROM User WHERE UserName = '11052022GDGstandarduser@testorg.com'];
        System.runAs(testUser) {
            test.startTest();
            CaseModel.ResponseWrapper response = CaseModel.getChuzoCases();
            test.stopTest();

            List<Case> responseCases = (List<Case>) response.result.get('Cases');
            String agentId = (String) response.result.get('agentId');

            System.assertEquals(0, responseCases.size(), 'Should return 0 cases when no cases exist');
            System.assertEquals(testUser.Id, agentId, 'Should return correct agent ID');
        }
    }
}
@isTest
public class POEIPStatisticValidatorTest {
    @TestSetup
    static void makeData() {
        User adminUser = TestHelper.getAdminUser();
        UserRole userRole = [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName = 'Sales_Supervisor' LIMIT 1];
        adminUser.UserRoleId = userRole.Id;
        adminUser.isActive = true;

        System.runAs(adminUser) {
            Account testAcc = new Account(
                Name = 'Test',
                ShippingStreet = 'Test Street',
                POE_Dealer_Office_Email__c = 'DealerEmail@testorg1.com'
            );
            insert testAcc;

            Contact userContact = new Contact(FirstName = 'test', LastName = 'test', AccountId = testAcc.Id);
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

            Fraud_Validation_Statistics__c fraud = new Fraud_Validation_Statistics__c();
            fraud.State__c = 'New York';
            fraud.Contact__c = userContact.Id;
            insert fraud;
        }
    }

    @isTest
    private static void POEIPStatisticValidatorTest() {
        String method = 'validateStatistic';
        String state = 'Buenos Aires';
        Contact cont = [SELECT Id FROM Contact LIMIT 1];
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        inputMap.put('ContactId', cont.Id);
        inputMap.put('State', state);
        Test.startTest();
        POEIPStatisticValidator validator = new POEIPStatisticValidator();
        validator.invokeMethod(method, inputMap, outMap, options);
        Test.stopTest();
        Fraud_Validation_Statistics__c fraud = [
            SELECT Id, IP_Fraud_Flag__c
            FROM Fraud_Validation_Statistics__c
            LIMIT 1
        ];
        System.assertEquals(true, fraud.IP_Fraud_Flag__c, 'Flag was not updated');
    }

    @isTest
    private static void testDifferentMethodName() {
        String method = 'validateStatisticTest';
        String state = 'Buenos Aires';
        Contact cont = [SELECT Id FROM Contact LIMIT 1];
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        inputMap.put('ContactId', cont.Id);
        inputMap.put('State', state);

        Test.startTest();
        POEIPStatisticValidator validator = new POEIPStatisticValidator();
        Boolean result = validator.invokeMethod(method, inputMap, outMap, options);
        Test.stopTest();

        System.assertEquals(false, result, 'testDifferentMethodName');
    }

    @isTest
    static void testInvokeMethodException() {
        String method = 'validateStatistic';
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        inputMap.put('ContactId', 1);

        Test.startTest();
        POEIPStatisticValidator validator = new POEIPStatisticValidator();
        Boolean result = validator.invokeMethod(method, inputMap, outMap, options);
        Test.stopTest();

        System.assertEquals(false, result, 'testInvokeMethodException');
    }
}
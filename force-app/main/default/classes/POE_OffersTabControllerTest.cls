@isTest
public class POE_OffersTabControllerTest {
    private static final String TEST_EMAIL = 'POEOffersTabControllerTest@test.com';
    private static final String TEST_FIRST_NAME = 'FirstName';
    private static final String TEST_LAST_NAME = 'LastName';

    @TestSetup
    static void setup() {
        RecordType rtype = [
            SELECT Name, Id
            FROM RecordType
            WHERE sObjectType = 'Account' AND Name = 'Dealer' AND isActive = TRUE
            LIMIT 1
        ];

        Account testAcc = new Account(
            Name = 'Test',
            ShippingStreet = 'Test Street',
            POE_Dealer_Office_Email__c = 'DealerEmail@testorg1.com',
            P10_Invoice_Account__c = 'Example',
            recordTypeId = rtype.Id
        );
        insert testAcc;

        Contact userContact = new Contact(
            FirstName = TEST_FIRST_NAME,
            LastName = TEST_LAST_NAME,
            AccountId = testAcc.Id,
            POE_Functional_Role__c = 'Office Manager'
        );
        insert userContact;

        Profile p = TestHelper.getGeneralProfile();
        User u = new User(
            Alias = 'standt',
            Email = TEST_EMAIL,
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            ContactId = userContact.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'POEOffersTabControllerTest@test.' + String.valueOf(Datetime.now().getTime()) + '.com'
        );
        insert u;
    }

    @isTest
    static void getAgentNameTest() {
        User u = [
            SELECT Id
            FROM User
            WHERE Email = :TEST_EMAIL
        ];

        System.runAs(u) {
            Test.startTest();
            POE_OffersTabController.ResponseWrapper response = POE_OffersTabController.getAgentName();
            Test.stopTest();

            Assert.areEqual(
                TEST_FIRST_NAME,
                (String) response.result.get('firstName'),
                'The firstName field did not match the expected value.'
            );
            Assert.areEqual(
                TEST_LAST_NAME,
                (String) response.result.get('lastName'),
                'The lastName field did not match the expected value.'
            );
        }
    }

    @isTest
    static void runException() {
        POE_OffersTabController.throwException = true;

        Test.startTest();
        try {
            POE_OffersTabController.ResponseWrapper response = POE_OffersTabController.getAgentName();
            System.assert(false, 'Should have thrown an exception');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Exception message was wrong');
        }
        Test.stopTest();
    }
}
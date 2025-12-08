@isTest
public class PV_TwilioIntegrationSchedulerTest {
    @isTest
    static void testScheduler() {
        Account testAccount = PV_TestDataFactory.createAccount('Test Account', true);
        Contact contact = PV_TestDataFactory.createContact('Test', 'Contact', true, testAccount);

        FSL_Settings__c fslSettings = new FSL_Settings__c(
            Default_Message_Log_Contact_Id__c = contact.Id
        );
        insert fslSettings;

        Test.setMock(HttpCalloutMock.class, new PV_TwilioIntegrationHandlerTest.MockTwilioResponse());

        Test.startTest();
        PV_TwilioIntegrationScheduler scheduler = new PV_TwilioIntegrationScheduler();
        String cronExp = '0 0 0/2 * * ? *';
        System.schedule('Test Twilio Scheduler', cronExp, scheduler);
        Test.stopTest();
    }
}
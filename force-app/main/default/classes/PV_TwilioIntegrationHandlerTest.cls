@isTest
public class PV_TwilioIntegrationHandlerTest {
    public static final String UNIQUE_PHONE_NUMBER = '+1 (987) 654-001';
    public static final String DUPLICATED_PHONE_NUMBER = '987654002';

    @testSetup
    static void makeData() {
        Account testAccount = PV_TestDataFactory.createAccount('Test Account', true);

        List<Contact> contacts = new List<Contact>();

        Contact contact1 = PV_TestDataFactory.createContact('Test', 'Contact1', false, testAccount);
        contact1.Phone = UNIQUE_PHONE_NUMBER;
        contacts.add(contact1);

        Contact contact2 = PV_TestDataFactory.createContact('Test', 'Contact2', false, testAccount);
        contact2.Phone = DUPLICATED_PHONE_NUMBER;
        contacts.add(contact2);

        Contact contact3 = PV_TestDataFactory.createContact('Test', 'Contact3', false, testAccount);
        contact3.Phone = DUPLICATED_PHONE_NUMBER;
        contacts.add(contact3);

        insert contacts;

        WorkType workType = PV_TestDataFactory.createWorkType('Test Work Type', true);

        User testUser = PV_TestDataFactory.createTechnicianUser(true, contact1);

        WorkOrder workOrder = PV_TestDataFactory.createWorkOrder(testUser, workType, false);
        workOrder.ContactId = contacts[0].Id;
        insert workOrder;

        FSL_Settings__c fslSettings = new FSL_Settings__c(
            Default_Message_Log_Contact_Id__c = contact1.Id
        );
        insert fslSettings;
    }

    @isTest
    static void executeTest() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockTwilioResponse());
        PV_TwilioIntegrationHandler handler = new PV_TwilioIntegrationHandler();
        System.enqueueJob(handler);
        Test.stopTest();

        List<Message_Log__c> messageLogs = [
            SELECT  Message_Id__c, From__c, To__c, Body__c, Status__c, Error_Code__c, Error_Message__c
            FROM    Message_Log__c
            WHERE   Message_Id__c IN ('SM00001', 'SM00002', 'SM00003', 'SM00004', 'SM00005', 'SM00006', 'SM00007')
        ];
        
        System.assertEquals(7, messageLogs.size(), 'There should be seven message logs inserted.');
    }

    public class MockTwilioResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);

            String responseBody = '{'
            + '  "messages": ['
            + '    {"sid": "SM00001", "from": "+1987654001", "to": "+1234567890", "body": "Test Message Received", "status": "received", "direction": "inbound"},'
            + '    {"sid": "SM00002", "from": "+1987654002", "to": "+1234567890", "body": "Test Message Sent", "status": "sent", "direction": "inbound"},'
            + '    {"sid": "SM00003", "from": "+1987654003", "to": "+1234567890", "body": "Test Message Delivered", "status": "delivered", "direction": "inbound"},'
            + '    {"sid": "SM00004", "from": "+1987654004", "to": "+1234567890", "body": "Test Message Failed", "status": "failed", "direction": "inbound"},'
            + '    {"sid": "SM00005", "from": "+1987654005", "to": "+1234567890", "body": "Test Message Failed", "status": "failed", "direction": "inbound", "error_code": 30001},'
            + '    {"sid": "SM00006", "from": "+1987654006", "to": "+1234567890", "body": "Test Message Undelivered", "status": "undelivered", "direction": "inbound"},'
            + '    {"sid": "SM00007", "from": "+1987654007", "to": "+1234567890", "body": "Test Message Unknown Status", "status": "unexpected_status", "direction": "inbound"}'
            + '  ],'
            + '  "next_page_uri": ""'
            + '}';

            response.setBody(responseBody);
            return response;
        }
    }
}
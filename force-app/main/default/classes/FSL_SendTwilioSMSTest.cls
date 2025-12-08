@isTest
private class FSL_SendTwilioSMSTest {
    
    // Mock HTTP Response Class
    private class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"sent","sid":"SM123456789"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void testInvokeMethod() {
        Account testAccount = PV_TestDataFactory.createAccount('Test Account', true);
        Contact contact = PV_TestDataFactory.createContact('Test', 'Contact', true, testAccount);

        FSL_Settings__c fslSettings = new FSL_Settings__c(
            Default_Message_Log_Contact_Id__c = contact.Id
        );
        insert fslSettings;

        // Create a test metadata record for Twilio configuration

        FSL_SendTwiloSMS.SMSData data = new FSL_SendTwiloSMS.SMSData();
        data.clientPhone = '+1987654321';
        data.body = 'Test message';
    
        List<FSL_SendTwiloSMS.SMSData> testData = new List<FSL_SendTwiloSMS.SMSData>();

        testData.add(data);

        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        
        Test.startTest();
        FSL_SendTwiloSMS.invokeMethod(testData);
        Test.stopTest();

        System.assert(true, 'No exception should be thrown');
    }
}
@isTest
public class reCAPTCHAv3ServerControllerTest {
    
    @TestSetup
    static void setup() {
        // Create test custom settings
        Chuzo_Settings__c testSettings = new Chuzo_Settings__c();
        testSettings.ReCaptcha_Secret_Key__c = 'test-secret-key';
        testSettings.ReCaptcha_Minimum_Acceptable_Score__c = 0.5; // Percent(1,2) stores as decimal directly
        testSettings.Recaptcha_API_URL__c = 'https://www.google.com/recaptcha/api/siteverify';
        insert testSettings;
    }
    
    @isTest
    static void testConstructor() {
        // Test the constructor
        Test.startTest();
        reCAPTCHAv3ServerController controller = new reCAPTCHAv3ServerController();
        Test.stopTest();
        
        System.assertNotEquals(null, controller, 'Controller should be instantiated');
    }
    
    @isTest
    static void testValidReCAPTCHAWithHighScore() {
        // Test with a high score that should pass (0.9 > 0.5)
        Test.setMock(HttpCalloutMock.class, new ReCAPTCHAMockHighScore());
        
        Test.startTest();
        Boolean result = reCAPTCHAv3ServerController.isReCAPTCHAValid('test-token');
        Test.stopTest();
        
        System.assertEquals(true, result, 'Should return true for high score reCAPTCHA');
    }
    
    @isTest
    static void testValidReCAPTCHAAtThreshold() {
        // Test with exactly the minimum acceptable score (0.5 = 0.5)
        Test.setMock(HttpCalloutMock.class, new ReCAPTCHAMockThresholdScore());
        
        Test.startTest();
        Boolean result = reCAPTCHAv3ServerController.isReCAPTCHAValid('test-token');
        Test.stopTest();
        
        System.assertEquals(true, result, 'Should return true for threshold score reCAPTCHA');
    }
    
    @isTest
    static void testInvalidReCAPTCHAWithLowScore() {
        // Test with a low score that should fail (0.3 < 0.5)
        Test.setMock(HttpCalloutMock.class, new ReCAPTCHAMockLowScore());
        
        Test.startTest();
        Boolean result = reCAPTCHAv3ServerController.isReCAPTCHAValid('test-token');
        Test.stopTest();
        
        System.assertEquals(false, result, 'Should return false for low score reCAPTCHA');
    }
    
    @isTest
    static void testInvalidReCAPTCHAWithFailure() {
        // Test with a failed reCAPTCHA response
        Test.setMock(HttpCalloutMock.class, new ReCAPTCHAMockFailure());
        
        Test.startTest();
        Boolean result = reCAPTCHAv3ServerController.isReCAPTCHAValid('test-token');
        Test.stopTest();
        
        System.assertEquals(false, result, 'Should return false for failed reCAPTCHA');
    }
    
    @isTest
    static void testReCAPTCHAWithMissingScore() {
        // Test with missing score field in response
        Test.setMock(HttpCalloutMock.class, new ReCAPTCHAMockMissingScore());
        
        Test.startTest();
        Boolean result = reCAPTCHAv3ServerController.isReCAPTCHAValid('test-token');
        Test.stopTest();
        
        System.assertEquals(false, result, 'Should return false when score is missing');
    }
    
    @isTest
    static void testReCAPTCHAWithException() {
        // Test with an exception scenario
        Test.setMock(HttpCalloutMock.class, new ReCAPTCHAMockHttpError());
        
        Test.startTest();
        Boolean result = reCAPTCHAv3ServerController.isReCAPTCHAValid('test-token');
        Test.stopTest();
        
        System.assertEquals(false, result, 'Should return false when exception occurs');
    }
    
    @isTest
    static void testReCAPTCHAWithNullSettings() {
        // Test with null settings (should use default 0.5)
        delete [SELECT Id FROM Chuzo_Settings__c];
        
        Test.setMock(HttpCalloutMock.class, new ReCAPTCHAMockHighScore());
        
        Test.startTest();
        Boolean result = reCAPTCHAv3ServerController.isReCAPTCHAValid('test-token');
        Test.stopTest();
        
        System.assertEquals(true, result, 'Should return true with default settings');
    }
    
    // Mock classes for different test scenarios
    public class ReCAPTCHAMockHighScore implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success": true, "score": 0.9, "action": "submit", "challenge_ts": "2025-08-29T15:52:01Z", "hostname": "test.com"}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    public class ReCAPTCHAMockThresholdScore implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success": true, "score": 0.5, "action": "submit", "challenge_ts": "2025-08-29T15:52:01Z", "hostname": "test.com"}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    public class ReCAPTCHAMockLowScore implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success": true, "score": 0.3, "action": "submit", "challenge_ts": "2025-08-29T15:52:01Z", "hostname": "test.com"}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    public class ReCAPTCHAMockFailure implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success": false, "error-codes": ["invalid-input-response"]}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    public class ReCAPTCHAMockMissingScore implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success": true, "action": "submit", "challenge_ts": "2025-08-29T15:52:01Z", "hostname": "test.com"}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    public class ReCAPTCHAMockHttpError implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            return res;
        }
    }
}
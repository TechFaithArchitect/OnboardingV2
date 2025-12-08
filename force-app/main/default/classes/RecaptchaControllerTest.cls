@isTest
public class RecaptchaControllerTest {

    @TestSetup
    static void setup() {
        Chuzo_Settings__c testSettings = new Chuzo_Settings__c();
        testSettings.Recaptcha_API_URL__c = 'test';
        insert testSettings;
    }

    @isTest
    static void testCaptchaValidation() {
        Test.setMock(HttpCalloutMock.class, new RecaptchaControllerTestMock());
        Test.startTest();
        Map<String, Object> response = RecaptchaController.validateCaptcha(null);
        Test.stopTest();

        Assert.isTrue((Boolean) response.get('success'), 'Response was not successful');
    }
}
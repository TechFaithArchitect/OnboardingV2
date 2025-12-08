@isTest
public with sharing class LimitMonitoringServiceTest {

    private static final String NO_NOTIFICATION_MESSAGE = 'No notification email was sent when the alert was expected.';

    @TestSetup
    static void setup() {
        Chuzo_Settings__c settings = new Chuzo_Settings__c(
            Limits_Alert_Emails__c = 'test@gmail.com'
        );
        insert settings;
    }

    @isTest
    static void checkLicenseUsageTest() {
        Test.startTest();
        LimitMonitoringService.usageAlertLimit = 0; // Lower the limit to always trigger email
        LimitMonitoringService.checkLicenseUsage();
        Integer endEmailInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        Assert.areEqual(1, endEmailInvocations, NO_NOTIFICATION_MESSAGE);
    }

    @isTest
    static void checkEmailLimitUsageTest() {
        Integer emailLimit = (Integer) (LimitMonitoringService.usageAlertLimit * 10);

        Test.startTest();
        for (Integer i = 0; i < emailLimit; i++) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String> {'test@gmail.com'});
            email.setSubject('test');
            email.setPlainTextBody('test');
    
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage> { email });
        }

        LimitMonitoringService.checkEmailLimitUsage();
        Integer endEmailInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        Assert.areEqual(emailLimit + 1, endEmailInvocations, NO_NOTIFICATION_MESSAGE);
    }

    @isTest
    static void checkApiCallUsageTest() {
        LimitMonitoringService.usageAlertLimit = (Decimal) 1 / Limits.getLimitCallouts();
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(URL.getOrgDomainUrl().toExternalForm());

        Test.setMock(HttpCalloutMock.class, new POE_ProvidersApexHttpCalloutMock());
        Test.startTest();
        HttpResponse res = new Http().send(req);
        LimitMonitoringService.checkApiCallUsage();
        Integer endEmailInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        Assert.areEqual(1, endEmailInvocations, NO_NOTIFICATION_MESSAGE);
    }

    @isTest
    static void checkPublicPageViewsTest() {
        Test.startTest();
        LimitMonitoringService.usageAlertLimit = 0; // Lower the limit to always trigger email
        LimitMonitoringService.checkPublicPageViews();
        Integer endEmailInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        Assert.areEqual(1, endEmailInvocations, NO_NOTIFICATION_MESSAGE);
    }

    @isTest
    static void checkFlowInterviewsTest() {
        Test.startTest();
        LimitMonitoringService.usageAlertLimit = 0; // Lower the limit to always trigger email
        LimitMonitoringService.checkFlowInterviews();
        Integer endEmailInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        Assert.areEqual(2, endEmailInvocations, NO_NOTIFICATION_MESSAGE);
    }

    @isTest
    static void checkWebToCaseUsageTest() {
        List<Case> testCases = new List<Case>();
        for (Integer i=0; i < 5; i++) {
            Case testCase = new Case(
                Status = 'New',
                Origin = 'Web'
            );
            testCases.add(testCase);
        }
        insert testCases;

        Test.startTest();
        LimitMonitoringService.checkWebToCaseUsage();
        Integer endEmailInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        Assert.areEqual(1, endEmailInvocations, NO_NOTIFICATION_MESSAGE);
    }

    @isTest
    static void checkStorageUsageTest() {
        Test.setMock(HttpCalloutMock.class, new LimitsCalloutMock());
        Test.startTest();
        LimitMonitoringService.checkStorageUsage();
        Integer endEmailInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        Assert.areEqual(2, endEmailInvocations, NO_NOTIFICATION_MESSAGE);
    }

    public class LimitsCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request) {
            Integer max = 10;
            Integer remaining = (Integer) (max * LimitMonitoringService.usageAlertLimit);
            LimitMonitoringService.LimitsData responseBody = new LimitMonitoringService.LimitsData();
            responseBody.DataStorageMB.Max = max;
            responseBody.DataStorageMB.Remaining = remaining;
            responseBody.FileStorageMB.Max = max;
            responseBody.FileStorageMB.Remaining = remaining;

            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody(JSON.serialize(responseBody));
            response.setStatusCode(200);
            return response;
        }
    }
}
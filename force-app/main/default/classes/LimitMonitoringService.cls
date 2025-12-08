public without sharing class LimitMonitoringService {

    private static final Integer WEB_TO_CASE_DAILY_LIMIT = Test.isRunningTest() ? 5 : 5000;
    private static final String USER_LICENSE_TEMPLATE = '{0}\n{1}: {2} of {3} used. ({4}%)';
    private static final String PUBLIC_PAGE_VIEWS_MASTER_LABEL = 'Maximum Public Experience Page Views';
    private static final String FLOW_INTERVIEWS_W_UI_MASTER_LABEL = 'Maximum Flow Interviews with UI per Month';
    private static final String FLOW_INTERVIEWS_WO_UI_MASTER_LABEL = 'Maximum Flow Interviews Without UI per Month';    
    private static final String LIMITS_ENDPOINT = '/services/data/v58.0/limits';

    private static List<TenantUsageEntitlement> usageEntitlements;
    public static Decimal usageAlertLimit = 0.8;

    public static void checkAndNotifyLimits() {
        checkStorageUsage();
        checkLicenseUsage();
        checkEmailLimitUsage();
        checkApiCallUsage();
        checkPublicPageViews();
        checkFlowInterviews();
        checkWebToCaseUsage();
    }
    
    private static void sendNotification(String subject, String message) {
        Chuzo_Settings__c settings = Chuzo_Settings__c.getOrgDefaults();
        if (String.isBlank(settings.Limits_Alert_Emails__c)) {
            return;
        }

        List<String> emails = new List<String>();
        if (settings.Limits_Alert_Emails__c.contains(',')) {
            emails = settings.Limits_Alert_Emails__c.split(',');
        } else {
            emails.add(settings.Limits_Alert_Emails__c);
        }

        Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
        emailMessage.setToAddresses(emails);
        emailMessage.setSubject(subject);
        emailMessage.setPlainTextBody(message);

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ emailMessage });
    }

    @TestVisible
    private static void checkLicenseUsage() {
        String notifMsg = '';
        for (UserLicense ul : [
            SELECT Id, Name, UsedLicenses, TotalLicenses, 
                   Status, MasterLabel, LicenseDefinitionKey 
            FROM UserLicense]
        ) {
            if (ul.TotalLicenses == 0) {
                continue;
            }
            
            Decimal ulUsage = (Decimal) ul.UsedLicenses / ul.TotalLicenses;
            if (ulUsage < usageAlertLimit) {
                continue;
            }

            if (String.isBlank(notifMsg)) {
                notifMsg = 'The following User Licenses have reached over ' + (usageAlertLimit * 100).setScale(0) + '% usage in your Salesforce org:';
            }

            notifMsg = String.format(USER_LICENSE_TEMPLATE, new List<Object> {
                notifMsg, ul.Name, ul.UsedLicenses, ul.TotalLicenses, (ulUsage * 100).setScale(1)
            });
        }

        if (String.isNotBlank(notifMsg)) {
            sendNotification('User License Limit Alert', notifMsg);
        }
    }

    @TestVisible
    private static void checkEmailLimitUsage() {
        Integer sentEmails = Limits.getEmailInvocations();
        Integer limitEmails = Limits.getLimitEmailInvocations();

        Decimal emailUsage = (Decimal) sentEmails / limitEmails;
        if (emailUsage >= usageAlertLimit) {
            sendNotification(
                'Email Limit Alert', 
                'Your Salesforce org has reached ' + (emailUsage * 100).setScale(1) + '% of its daily emails sent limit.'
            );
        }
    }

    @TestVisible
    private static void checkApiCallUsage() {
        Integer callouts = Limits.getCallouts();
        Integer limitCallouts = Limits.getLimitCallouts();

        Decimal calloutUsage = (Decimal) callouts / limitCallouts;
        if (calloutUsage >= usageAlertLimit) {
            sendNotification(
                'API Call Limit Alert', 
                'Your Salesforce org has reached ' + (calloutUsage * 100).setScale(1) + '% of its daily API call limit.'
            );
        }
    }

    @TestVisible
    private static void checkPublicPageViews() {
        if (usageEntitlements == null) {
            usageEntitlements = [
                SELECT Id, AmountUsed, CurrentAmountAllowed, MasterLabel 
                FROM TenantUsageEntitlement
            ];
        }

        for (TenantUsageEntitlement ue : usageEntitlements) {
            if (ue.CurrentAmountAllowed == 0 || ue.MasterLabel != PUBLIC_PAGE_VIEWS_MASTER_LABEL) {
                continue;
            }
            
            Decimal publicPageViewsUsage = (Decimal) ue.AmountUsed / ue.CurrentAmountAllowed;
            if (publicPageViewsUsage >= usageAlertLimit) {
                sendNotification(
                    'Public Page Views Limit Alert', 
                    'Your Salesforce org has reached ' + (publicPageViewsUsage * 100).setScale(1) + '% of its monthly allowed public page views.'
                );
            }
        }
    }

    @TestVisible
    private static void checkFlowInterviews() {
        if (usageEntitlements == null) {
            usageEntitlements = [
                SELECT Id, AmountUsed, CurrentAmountAllowed, MasterLabel 
                FROM TenantUsageEntitlement
            ];
        }

        for (TenantUsageEntitlement ue : usageEntitlements) {
            if (ue.CurrentAmountAllowed == 0 || ue.CurrentAmountAllowed == null || ue.AmountUsed == null) {
                continue;
            }

            Decimal ueUsage = (Decimal) ue.AmountUsed / ue.CurrentAmountAllowed;
            if (ue.MasterLabel == FLOW_INTERVIEWS_W_UI_MASTER_LABEL &&
                ueUsage >= usageAlertLimit
            ) {
                sendNotification(
                    'Flow Interviews with UI Limit Alert', 
                    'Your Salesforce org has reached ' + (ueUsage * 100).setScale(1) + '% of its monthly allowed flow interviews with UI.'
                );
            } else if (ue.MasterLabel == FLOW_INTERVIEWS_WO_UI_MASTER_LABEL && 
                       ueUsage >= usageAlertLimit
            ) {
                sendNotification(
                    'Flow Interviews Without UI Limit Alert', 
                    'Your Salesforce org has reached ' + (ueUsage * 100).setScale(1) + '% of its monthly allowed flow interviews without UI.'
                );
            }
        }
    }

    @TestVisible
    private static void checkWebToCaseUsage() {
        Integer todaysWebToCaseCount = [
            SELECT COUNT()
            FROM Case
            WHERE Origin = 'Web'
            AND CreatedDate = TODAY
        ];

        Decimal webToCaseDailyUsage = (Decimal) todaysWebToCaseCount / WEB_TO_CASE_DAILY_LIMIT;
        if (webToCaseDailyUsage >= usageAlertLimit) {
            sendNotification(
                'Web to Case Limit Alert', 
                'Your Salesforce org has reached ' + (webToCaseDailyUsage * 100).setScale(1) + '% of its daily allowed Web-to-Case records created.'
            );
        }
    }

    @TestVisible
    private static void checkStorageUsage() {
        String endpoint = URL.getOrgDomainUrl().toExternalForm() + LIMITS_ENDPOINT;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        HttpResponse res = new Http().send(req);

        if (res.getStatusCode() != 200) {
            return;
        }

        LimitsData limitsData = (LimitsData) JSON.deserialize(
            res.getBody(),
            LimitsData.class
        );

        Decimal dataStorageUsage = (Decimal) limitsData.DataStorageMB.Remaining / limitsData.DataStorageMB.Max;
        if (dataStorageUsage >= usageAlertLimit) {
            sendNotification(
                'Data Storage Limit Alert', 
                'Your Salesforce org has reached ' + (dataStorageUsage * 100).setScale(1) + '% of its allowed data storage.'
            );
        }

        Decimal fileStorageUsage = (Decimal) limitsData.FileStorageMB.Remaining / limitsData.FileStorageMB.Max;
        if (fileStorageUsage >= usageAlertLimit) {
            sendNotification(
                'Data Storage Limit Alert', 
                'Your Salesforce org has reached ' + (fileStorageUsage * 100).setScale(1) + '% of its allowed file storage.'
            );
        }
    }

    public class LimitsData {
        public StorageLimit DataStorageMB = new StorageLimit();
        public StorageLimit FileStorageMB = new StorageLimit();
    }

    public class StorageLimit {
        public Integer Max;
        public Integer Remaining;
    }
}
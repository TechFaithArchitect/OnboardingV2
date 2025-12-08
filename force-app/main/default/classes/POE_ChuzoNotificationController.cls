public without sharing class POE_ChuzoNotificationController {
    @AuraEnabled(cacheable=true)
    public static List<String> getActiveNotification() {
        List<String> messagesToDisplay = new List<String>();
        List<POE_ChuzoLoginNotification__mdt> activeNotifications = getChuzoLoginNotifications();
        if (!activeNotifications.isEmpty()) {
            List<String> userPrograms = getUserPrograms();
            userPrograms.add('all');
            for (POE_ChuzoLoginNotification__mdt loginNotification : activeNotifications) {
                List<String> notificationPrograms = loginNotification.Program__c.split(',');
                for (String notificationProgram : notificationPrograms) {
                    String notificationProgramTrimmed = notificationProgram.trim();
                    if (userPrograms.contains(notificationProgramTrimmed.toLowerCase())) {
                        messagesToDisplay.add(loginNotification.Message__c);
                        break;
                    }
                }
            }
        }
        return messagesToDisplay;
    }

    private static List<String> getUserPrograms() {
        List<String> programsAvailable = new List<String>();
        if (!Auth.CommunitiesUtil.isGuestUser()) {
            Id runningUserId = UserInfo.getUserId();
            User runningUser = [SELECT Id, ContactId FROM User WHERE Id = :runningUserId];
            List<Contact> partnerContactList = [
                SELECT
                    Id,
                    POE_Programs_Available__c,
                    POE_Event_Programs__c,
                    POE_Retail_Programs__c,
                    D2D_Programs__c,
                    POE_Blacklisted_Programs__c
                FROM Contact
                WHERE Id = :runningUser.ContactId
            ];
            if (!partnerContactList.isEmpty()) {
                Contact partnerContact = partnerContactList[0];
                List<String> allProgramsAvailable = new List<String>();
                if (!String.isBlank(partnerContact.POE_Programs_Available__c)) {
                    allProgramsAvailable.addAll(partnerContact.POE_Programs_Available__c.split(';'));
                }
                if (!String.isBlank(partnerContact.POE_Event_Programs__c)) {
                    allProgramsAvailable.addAll(partnerContact.POE_Event_Programs__c.split(';'));
                }
                if (!String.isBlank(partnerContact.POE_Retail_Programs__c)) {
                    allProgramsAvailable.addAll(partnerContact.POE_Retail_Programs__c.split(';'));
                }
                if (!String.isBlank(partnerContact.D2D_Programs__c)) {
                    allProgramsAvailable.addAll(partnerContact.D2D_Programs__c.split(';'));
                }
                List<String> blacklistedPrograms = String.isBlank(partnerContact.POE_Blacklisted_Programs__c)
                    ? new List<String>()
                    : partnerContact.POE_Blacklisted_Programs__c.split(';');
                for (String program : allProgramsAvailable) {
                    if (!blacklistedPrograms.contains(program)) {
                        if (program.toLowerCase().contains('spectrum')) {
                            programsAvailable.add('spectrum');
                        } else {
                            programsAvailable.add(program.toLowerCase());
                        }
                    }
                }
            }
        }
        return programsAvailable;
    }

    private static List<POE_ChuzoLoginNotification__mdt> getChuzoLoginNotifications() {
        if (Test.isRunningTest()) {
            POE_ChuzoLoginNotification__mdt customMetadata = new POE_ChuzoLoginNotification__mdt();
            customMetadata.Message__c = 'Test';
            customMetadata.Program__c = 'EarthLink';
            return new List<POE_ChuzoLoginNotification__mdt>{ customMetadata };
        }
        return [
            SELECT Message__c, Program__c
            FROM POE_ChuzoLoginNotification__mdt
            WHERE Active__c = TRUE AND Start_Date__c <= TODAY AND End_Date__c >= TODAY AND Program__c != NULL
            ORDER BY Start_Date__c DESC
        ];
    }
}
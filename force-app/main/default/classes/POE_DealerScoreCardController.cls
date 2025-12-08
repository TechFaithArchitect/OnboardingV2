public without sharing class POE_DealerScoreCardController {
    @testVisible
    private static Boolean throwException = false;

    @AuraEnabled(cacheable=false)
    public static void saveInteraction(Boolean isMaps) {
        try {
            if (throwException) {
                throw new CustomException();
            }

            User us = [SELECT Id, Profile.Name, ContactId FROM User WHERE Id = :UserInfo.getUserId()];
            List<POE_Interaction_Tracker__c> pastInt = [
                SELECT Id
                FROM POE_Interaction_Tracker__c
                WHERE Contact__c = :us.ContactId AND CreatedDate = TODAY
            ];
            POE_Interaction_Tracker__c interaction = new POE_Interaction_Tracker__c();
            if (us.Profile.Name != 'System Administrator') {
                interaction.Contact__c = us.ContactId;
                if (pastInt.isEmpty()) {
                    interaction.Action__c = 'First Interaction';
                } else if (isMaps == true) {
                    interaction.Action__c = 'Door To Door Page';
                } else if (isMaps == false) {
                    interaction.Action__c = 'Disposition Page';
                }
            }
            insert interaction;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static void saveFirstInteraction() {
        try {
            if (throwException) {
                throw new CustomException();
            }

            User us = [SELECT Id, Profile.Name, ContactId FROM User WHERE Id = :UserInfo.getUserId()];
            List<POE_Interaction_Tracker__c> pastInt = [
                SELECT Id
                FROM POE_Interaction_Tracker__c
                WHERE Contact__c = :us.ContactId AND CreatedDate = TODAY
            ];
            POE_Interaction_Tracker__c interaction = new POE_Interaction_Tracker__c();
            if (us.Profile.Name != 'System Administrator') {
                if (pastInt.isEmpty()) {
                    interaction.Contact__c = us.ContactId;
                    interaction.Action__c = 'First Interaction';
                    insert interaction;
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
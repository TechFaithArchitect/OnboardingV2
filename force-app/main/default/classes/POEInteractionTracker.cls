global without sharing class POEInteractionTracker implements vlocity_cmt.VlocityOpenInterface {
    global Boolean invokeMethod(
        String methodName,
        Map<String, Object> inputMap,
        Map<String, Object> outMap,
        Map<String, Object> options
    ) {
        Boolean result = true;
        try {
            User us = [SELECT Id, Profile.Name, ContactId FROM User WHERE Id = :UserInfo.getUserId()];
            List<POE_Interaction_Tracker__c> pastInt = [SELECT Id FROM POE_Interaction_Tracker__c WHERE Contact__c = :us.ContactId AND CreatedDate = TODAY];
            POE_Interaction_Tracker__c interaction = new POE_Interaction_Tracker__c();
            if (us.Profile.Name != 'System Administrator') {
                interaction.Contact__c = us.ContactId;
                if (pastInt.isEmpty()) {interaction.Action__c = 'First Interaction';}
                else {interaction.Action__c = 'Clicker Page';}
            }
            insert interaction;
        } catch (Exception e) {
            result = false;
        }
        return result;
    }
}
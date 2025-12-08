public class OnboardingTriggerHandler {

    public static void handle(List<Onboarding__c> newList, Map<Id, Onboarding__c> oldMap, Boolean isBefore, Boolean isAfter, Boolean isInsert, Boolean isUpdate) {
        if (isBefore && (isInsert || isUpdate)) {
            processStatusCalculation(newList, isInsert, isUpdate);
        }

        // Add other lifecycle logic here (e.g. after update, after insert, future use)
    }

    private static void processStatusCalculation(List<Onboarding__c> newList, Boolean isInsert, Boolean isUpdate) {
        Set<Id> onboardingIds = new Set<Id>();
        for (Onboarding__c ob : newList) {
            if (ob.Id != null) {
                onboardingIds.add(ob.Id);
            }
        }
    
        if (onboardingIds.isEmpty()) return;
    
        List<Onboarding__c> onboardingWithRelated = [
            SELECT Id, Assigned_Team__c,
                Background_Check__r.Status__c,
                Credit_Check__r.Status__c,
                Compliance__r.Status__c,
                Contract__c, Contract__r.Status, Contract__r.Contract_Type__c,
                Opportunity__c, Opportunity__r.StageName,
                ERP_Setup__r.Status__c
            FROM Onboarding__c
            WHERE Id IN :onboardingIds
        ];
    
        // Inject values from Trigger.new (like Assigned_Team__c) on update
        if (isUpdate) {
            Map<Id, Onboarding__c> newMap = new Map<Id, Onboarding__c>(newList);
            for (Onboarding__c enriched : onboardingWithRelated) {
                Onboarding__c input = newMap.get(enriched.Id);
                if (input != null) {
                    enriched.Assigned_Team__c = input.Assigned_Team__c;
                }
            }
        }
    
        // Write status back into Trigger.new (only for update)
        if (isUpdate) {
            Map<Id, Onboarding__c> newMap = new Map<Id, Onboarding__c>(newList);
            for (Onboarding__c enriched : onboardingWithRelated) {
                if (newMap.containsKey(enriched.Id)) {
                    newMap.get(enriched.Id).Onboarding_Status__c = enriched.Onboarding_Status__c;
                }
            }
        }
    }
}
global class RemoveOpportunitySensitiveDataBatch implements Database.Batchable<SObject>, Schedulable {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(
            [
                SELECT Id, POE_Credit_Card__c, POE_Sensitive_Data__c
                FROM Opportunity
                WHERE StageName != 'Closed Won' AND RecordType.Name = 'Standard Opportunity'
            ]
        );
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        List<Opportunity> toUpdate = new List<Opportunity>();

        for (Opportunity opp : (List<Opportunity>) scope) {
            if (!String.isBlank(opp.POE_Credit_Card__c) || !String.isBlank(opp.POE_Sensitive_Data__c)) {
                opp.POE_Credit_Card__c = null;
                opp.POE_Sensitive_Data__c = null;
                toUpdate.add(opp);
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    global void finish(Database.BatchableContext BC) {
        // Optional: Add logging or post-processing here
    }

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new RemoveOpportunitySensitiveDataBatch(), 200);
    }
}
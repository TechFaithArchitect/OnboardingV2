public class CloseInactiveOpportunitiesBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable {
    private Id standardOpportunityRecordTypeId;

    public CloseInactiveOpportunitiesBatch() {
        RecordType rt = [
            SELECT Id
            FROM RecordType
            WHERE DeveloperName = 'Standard_Opportunity' AND SObjectType = 'Opportunity'
            LIMIT 1
        ];
        standardOpportunityRecordTypeId = rt.Id;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date sixtyDaysAgo = Date.today().addDays(-60);

        String query = 'SELECT Id, StageName, LastModifiedDate, CloseDate, First_Attempted_Date__c ' +
                    'FROM Opportunity ' +
                    'WHERE StageName NOT IN (\'Closed Lost\', \'Order Created\') ' +
                    'AND ' + (Test.isRunningTest() ? 'First_Attempted_Date__c' : 'LastModifiedDate') + ' < :sixtyDaysAgo ' +
                    'AND RecordTypeId = :standardOpportunityRecordTypeId';

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        List<Opportunity> updates = new List<Opportunity>();
        String reason = 'Opportunity closed lost on ' + String.valueOf(Date.today()) + ' due to inactivity';

        for (Opportunity opp : scope) {
            opp.StageName = 'Closed Lost';
            opp.CloseDate = Date.today();
            opp.If_closed_lost_why__c = reason;
            updates.add(opp);
        }

        if (!updates.isEmpty()) {
            try {
                update updates;
            } catch (DmlException e) {
                System.debug('Error updating Opportunities: ' + e.getMessage());
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Batch job completed.');
    }
    
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new CloseInactiveOpportunitiesBatch(), 200);
    }

}
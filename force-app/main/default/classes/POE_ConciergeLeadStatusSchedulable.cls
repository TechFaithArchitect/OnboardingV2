public without sharing class POE_ConciergeLeadStatusSchedulable implements Schedulable {
    
    public void execute(SchedulableContext sc) {
        List<Id> leadIds = new List<Id>();
        Chuzo_Settings__c setting = Chuzo_Settings__c.getOrgDefaults();
        List<String> statuses = new List<String>();
        List<String> lostStatus = setting.Concierge_Lost_Status__c.split(';');
        statuses.addAll(lostStatus);
        List<String> wonStatus = setting.Concierge_Won_Status__c.split(';');
        statuses.addAll(wonStatus);

        for (Lead conciergeLead : [
            SELECT Id
            FROM Lead
            WHERE Concierge_External_Id__c != null
            AND Concierge_Status__c  NOT IN :statuses
        ]) {
            leadIds.add(conciergeLead.Id);
        }

        System.enqueueJob(new POE_ConciergeLeadStatusQueueable(leadIds));
    }
}
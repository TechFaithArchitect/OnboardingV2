public class POE_BatchMemberFlagValidation implements Database.Batchable<SObject>, Schedulable {
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id, Chuzo_Member__c  FROM Contact WHERE Account.RecordType.Name = 'Dealer']);
    }

    public void execute(Database.BatchableContext BC, List<SObject> scope) {
        Set<Id> contactIds = new Set<Id>();
        Map<Id, Contact> contactMap = new Map<Id, Contact>();

        for (SObject s : scope) {
            Contact c = (Contact) s;
            contactIds.add(c.Id);
            contactMap.put(c.Id, c);
        }

        Set<Id> activeChuzoMembers = new Set<Id>();
        for (NetworkMember nm : [
            SELECT Member.ContactId
            FROM NetworkMember
            WHERE Member.ContactId IN :contactIds AND Network.Name = 'POE' AND Member.IsActive = TRUE
        ]) {
            activeChuzoMembers.add(nm.Member.ContactId);
        }

        List<Contact> contactsToUpdate = new List<Contact>();
        for (Id cid : contactIds) {
            Contact c = contactMap.get(cid);
            Boolean shouldBeActive = activeChuzoMembers.contains(cid);

            if (c.Chuzo_Member__c != shouldBeActive) {
                c.Chuzo_Member__c = shouldBeActive;
                contactsToUpdate.add(c);
            }
        }

        if (!contactsToUpdate.isEmpty()) {
            try {
                update contactsToUpdate;
            } catch (Exception e) {
                System.debug('Error updating contacts: ' + e.getMessage());
            }
        }
    }

    public void finish(Database.BatchableContext BC) {
        // Optional: Add logging, chaining, or post-processing here
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new POE_BatchMemberFlagValidation());
    }
}
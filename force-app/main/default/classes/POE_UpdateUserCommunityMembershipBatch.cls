public class POE_UpdateUserCommunityMembershipBatch implements Database.Batchable<sObject>, Schedulable {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query;
        String chuzoId = [SELECT Id FROM Network WHERE Name = 'POE' LIMIT 1].Id;
        String fsId = [SELECT Id FROM Network WHERE Name = 'Field Service' LIMIT 1].Id;
        if (!Test.isRunningTest()) {
            query = 'SELECT Id, NetworkId, MemberId FROM NetworkMember WHERE NetworkId= :chuzoId OR NetworkId= :fsId LIMIT 15000000';
        } else {
            query = 'SELECT Id, NetworkId, MemberId FROM NetworkMember WHERE NetworkId= :chuzoId OR NetworkId= :fsId LIMIT 200';
        }
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        Map<String, String> communityByUserId = new Map<String, String>();
        Map<String, String> userIdByContactId = new Map<String, String>();
        List<NetworkMember> members = (List<NetworkMember>) scope;
        List<Contact> contactsToUpdate = new List<Contact>();
        String chuzoId = [SELECT Id FROM Network WHERE Name = 'POE' LIMIT 1].Id;
        String fsId = [SELECT Id FROM Network WHERE Name = 'Field Service' LIMIT 1].Id;

        for (NetworkMember member : members) {
            String network = '';
            if (member.NetworkId == chuzoId) {
                if (communityByUserId.containsKey(member.MemberId)) {
                    network = 'Both';
                } else {
                    network = 'Chuzo';
                }
            } else if (member.NetworkId == fsId) {
                if (communityByUserId.containsKey(member.MemberId)) {
                    network = 'Both';
                } else {
                    network = 'Field Service';
                }
            }
            if (network != '') {
                communityByUserId.put(member.MemberId, network);
            }
        }

        for (User u : [SELECT Id, ContactId FROM User WHERE Id IN :communityByUserId.keyset()]) {
            userIdByContactId.put(u.ContactId, u.Id);
        }

        for (Contact c : [
            SELECT Id, Chuzo_Member__c, FSL_Member__c
            FROM Contact
            WHERE Id IN :userIdByContactId.keyset()
        ]) {
            String experience = communityByUserId.get(userIdByContactId.get(c.Id));
            switch on experience {
                when 'Chuzo' {
                    c.Chuzo_Member__c = true;
                }
                when 'Field Service' {
                    c.FSL_Member__c = true;
                }
                when 'Both' {
                    c.Chuzo_Member__c = true;
                    c.FSL_Member__c = true;
                }
            }
            contactsToUpdate.add(c);
        }
        if (!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Job finished');
    }

    public void execute(SchedulableContext sc) {
        POE_UpdateUserCommunityMembershipBatch batchJob = new POE_UpdateUserCommunityMembershipBatch();
        Database.executeBatch(batchJob);
    }
}
public without sharing class NetworkMemberTriggerHelper {
    public void updateMembership(List<NetworkMember> members, Boolean positive) {
        String chuzoId = [SELECT Id FROM Network WHERE Name = 'POE' LIMIT 1].Id;
        String fsId = [SELECT Id FROM Network WHERE Name = 'Field Service' LIMIT 1].Id;
        Map<String, String> communityByUserId = new Map<String, String>();
        Map<String, String> userIdByContactId = new Map<String, String>();

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

        for (User u : [SELECT Id, ContactId, isActive FROM User WHERE Id IN :communityByUserId.keyset()]) {
            userIdByContactId.put(u.ContactId, u.Id);
            if (u.IsActive == false) {
                positive = false;
            }
        }
        if (!System.isBatch()) {
            updateContacts(communityByUserId, userIdByContactId, positive);
        }
    }

    @future
    public static void updateContacts(
        Map<String, String> communityByUserId,
        Map<String, String> userIdByContactId,
        Boolean positive
    ) {
        List<Contact> contactsToUpdate = new List<Contact>();
        for (Contact c : [
            SELECT Id, Chuzo_Member__c, FSL_Member__c
            FROM Contact
            WHERE Id IN :userIdByContactId.keyset()
        ]) {
            String experience = communityByUserId.get(userIdByContactId.get(c.Id));
            switch on experience {
                when 'Chuzo' {
                    c.Chuzo_Member__c = positive;
                }
                when 'Field Service' {
                    c.FSL_Member__c = positive;
                }
                when 'Both' {
                    c.Chuzo_Member__c = positive;
                    c.FSL_Member__c = positive;
                }
            }
            contactsToUpdate.add(c);
        }
        if (!contactsToUpdate.isEmpty()) {
            // Set DML options to bypass duplicate rule enforcement
            Database.DMLOptions dmlOpts = new Database.DMLOptions();
            dmlOpts.DuplicateRuleHeader.AllowSave = true;
            dmlOpts.DuplicateRuleHeader.RunAsCurrentUser = false;

            for (Contact c : contactsToUpdate) {
                c.setOptions(dmlOpts);
            }

            update contactsToUpdate;
        }
    }
}
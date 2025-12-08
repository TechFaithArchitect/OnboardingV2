public without sharing class OpportunitySharingService {
    // Method to create OpportunityShare records, called by Flow
    @InvocableMethod
    public static void shareOpportunityWithGroup(List<ShareInput> inputList) {
        List<OpportunityShare> shares = new List<OpportunityShare>();
        for (ShareInput input : inputList) {
            OpportunityShare oppShare = new OpportunityShare();
            oppShare.OpportunityId = input.recordId;
            oppShare.UserOrGroupId = input.groupId;
            oppShare.OpportunityAccessLevel = input.accessLevel; // 'Read' or 'Edit'
            shares.add(oppShare);
        }
        if (!shares.isEmpty()) {
            insert shares;
        }
    }
    // Input class to allow Flow to pass data to the Apex method
    public class ShareInput {
        @InvocableVariable
        public Id recordId;
        @InvocableVariable
        public Id groupId;
        @InvocableVariable
        public String accessLevel; // 'Read' or 'Edit'
    }
}
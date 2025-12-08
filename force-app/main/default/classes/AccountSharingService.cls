public class AccountSharingService {
    // Method to create AccountShare records, called by Flow
    @InvocableMethod
    public static void shareAccountWithGroup(List<ShareInput> inputList) {
        List<AccountShare> shares = new List<AccountShare>();
        for (ShareInput input : inputList) {
            AccountShare accShare = new AccountShare();
            accShare.AccountId = input.recordId;
            accShare.UserOrGroupId = input.groupId;
            accShare.AccountAccessLevel = input.accessLevel; // 'Read' or 'Edit'
            accShare.OpportunityAccessLevel = 'None';
            shares.add(accShare);
        }
        if (!shares.isEmpty()) {
            insert shares;
        }
    }
    // Input class to allow Flow to pass data to the Apex method
    public class ShareInput {
        @InvocableVariable
        public Id recordId; // Account Id
        @InvocableVariable
        public Id groupId; // Public Group Id
        @InvocableVariable
        public String accessLevel; // 'Read' or 'Edit'
    }
}
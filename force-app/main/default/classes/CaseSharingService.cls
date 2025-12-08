public without sharing class CaseSharingService {
    @InvocableMethod
    public static void shareCaseWithGroup(List<ShareInput> inputList) {
        List<CaseShare> shares = new List<CaseShare>();
        for (ShareInput input : inputList) {
            CaseShare caseSharing = new CaseShare();
            caseSharing.CaseId = input.recordId;
            caseSharing.UserOrGroupId = input.groupId;
            caseSharing.CaseAccessLevel = input.accessLevel; // 'Read' or 'Edit'
            shares.add(caseSharing);
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
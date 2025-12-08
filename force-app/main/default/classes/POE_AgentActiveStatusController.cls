public without sharing class POE_AgentActiveStatusController {
    @AuraEnabled(cacheable=true)
    public static ResponseWrapper getAgentStatus(String contactId) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            Boolean chuzo = false;
            Boolean fieldService = false;
            String userId = [SELECT Id, isOwner__c FROM User WHERE ContactId = :contactId AND isActive = TRUE LIMIT 1]
            .Id;
            for (NetworkMember member : [SELECT Network.Name FROM NetworkMember WHERE MemberId = :userId]) {
                if (member.Network.Name == 'POE') {
                    chuzo = true;
                }
                if (member.Network.Name == 'Field Service') {
                    fieldService = true;
                }
            }
            response.result = new Map<String, Object>{ 'chuzo' => chuzo, 'fieldService' => fieldService };
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class ResponseWrapper {
        @AuraEnabled
        public Map<String, Object> result;
    }
}
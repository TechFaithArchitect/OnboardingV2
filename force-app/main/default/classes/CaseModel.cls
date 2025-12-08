public without sharing class CaseModel {
    @AuraEnabled
    public static ResponseWrapper getChuzoCases() {
        try {
            ResponseWrapper response = new ResponseWrapper();

            User currentUser = [SELECT Id, AccountId, ContactId FROM User WHERE Id = :System.UserInfo.getUserId()];

            List<User> sameAccountUsers = [SELECT Id FROM User WHERE AccountId = :currentUser.AccountId];

            Set<Id> usersIds = new Set<Id>();

            for (User u : sameAccountUsers) {
                usersIds.add(u.Id);
            }

            List<Case> userCases = [
                SELECT
                    Id,
                    Case_URL__c,
                    CaseNumber,
                    Description,
                    LastModifiedDate,
                    Order__c,
                    POE_Case_Result__c,
                    POE_ICL_Rep_Name__c,
                    POE_ICLRep__c,
                    POE_Issue__c,
                    POE_Sub_Issue__c,
                    Status,
                    Subject,
                    Type
                FROM Case
                WHERE CreatedById IN :usersIds OR AccountId = :currentUser.AccountId
                ORDER BY LastModifiedDate DESC
            ];

            Map<String, Object> result = new Map<String, Object>{ 'agentId' => currentUser.Id, 'Cases' => userCases };

            response.result = result;

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
public without sharing class POE_ChuzoOpportunityListController {
    private static final String OFFICE_OPPORTUNITIES_VT = 'office';
    @TestVisible
    private static final String ALL_OPPORTUNITIES_VT = 'all';

    @AuraEnabled
    public static ResponseWrapper getOpportunities(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String viewType = (String) myData.get('viewType');
            String userId = System.UserInfo.getUserId();

            User currentUser = [SELECT Id, Contact.POE_Functional_Role__c, AccountId FROM User WHERE Id = :userId];

            String accountId = currentUser.AccountId;

            String query = 'SELECT Id, Name, Account.Name, StageName, CloseDate, Owner.Name FROM Opportunity';
            Boolean isOwner = (currentUser.Contact.POE_Functional_Role__c == 'Office Manager' ||
            currentUser.Contact.POE_Functional_Role__c == 'Sales Manager' ||
            currentUser.Contact.POE_Functional_Role__c == 'Team Lead');

            if (viewType == ALL_OPPORTUNITIES_VT && isOwner) {
                query += ' WHERE OwnerId = :userId OR Poe_Dealer__c = :accountId';
            } else if (viewType == OFFICE_OPPORTUNITIES_VT && isOwner) {
                query += ' WHERE Poe_Dealer__c = :accountId AND OwnerId != :userId';
            } else {
                query += ' WHERE OwnerId = :userId';
            }

            query += ' ORDER BY CreatedDate DESC';

            response.result = new Map<String, Object>{ 'opportunities' => Database.query(query) };
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper getAccountInformation(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String userId = System.UserInfo.getUserId();
            User currentUser = [SELECT Id, Contact.POE_Functional_Role__c, AccountId FROM User WHERE Id = :userId];
            String accountId = currentUser.AccountId;
            Boolean isOwner = (currentUser.Contact.POE_Functional_Role__c == 'Office Manager' ||
            currentUser.Contact.POE_Functional_Role__c == 'Sales Manager' ||
            currentUser.Contact.POE_Functional_Role__c == 'Team Lead');
            String filter = (String) myData.get('filter');
            Set<Id> completedSalesIds = new Set<Id>();

            // First, get the last 200 created accounts
            String accQuery = 'SELECT Id, CreatedDate, Name, PersonEmail, Phone, ShippingPostalCode FROM Account';
            if (isOwner) {
                accQuery += ' WHERE Owner.AccountId =:accountId';
            } else {
                accQuery += ' WHERE OwnerId = :userId';
            }

            if (filter != 'none') {
                String filterValue = '%' + filter + '%';
                accQuery +=
                    ' AND ( Name LIKE \'' +
                    filterValue +
                    '\' OR Phone LIKE \'' +
                    filterValue +
                    '\' OR PersonEmail LIKE \'' +
                    filterValue +
                    '\' OR ShippingPostalCode LIKE \'' +
                    filterValue +
                    '\' )';
            }

            accQuery += ' ORDER BY CreatedDate DESC LIMIT 200';

            List<Account> accounts = Database.query(accQuery);

            // Extract account IDs from the accounts we retrieved
            Set<Id> accountIds = new Set<Id>();
            for (Account acc : accounts) {
                accountIds.add(acc.Id);
            }

            // Now query opportunities only for the accounts we retrieved
            String oppQuery = 'SELECT Id, AccountId, StageName FROM Opportunity WHERE AccountId IN :accountIds';
            if (isOwner) {
                oppQuery += ' AND POE_Dealer__c = :accountId AND StageName = \'Order Created\'';
            } else {
                oppQuery += ' AND OwnerId = :userId AND StageName = \'Order Created\'';
            }

            for (Opportunity opp : Database.query(oppQuery)) {
                completedSalesIds.add(opp.AccountId);
            }

            System.debug(accQuery);

            response.result = new Map<String, Object>{ 'accounts' => accounts, 'completed' => completedSalesIds };
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
public without sharing class ConsentDisclaimerPageController {
    @AuraEnabled
    public static Map<String, Object> getLeadData(String recordId) {
        try {
            Map<String, Object> result;
            Opportunity opportunityData = [
                SELECT
                    Id,
                    Account.PersonEmail,
                    Account.Phone,
                    Account.FirstName,
                    Account.LastName,
                    OwnerId,
                    Account.Consent_to_Automated_Communications__c
                FROM Opportunity
                WHERE Id = :recordId
                LIMIT 1
            ];
            List<Lead> previousLeads = [
                SELECT Id
                FROM Lead
                WHERE Email = :opportunityData.Account.PersonEmail AND CreatedDate >= LAST_WEEK
            ];
            result = new Map<String, Object>{
                'hasPrevious' => !previousLeads.isEmpty(),
                'firstName' => opportunityData.Account.FirstName,
                'lastName' => opportunityData.Account.LastName,
                'phone' => opportunityData.Account.Phone,
                'email' => opportunityData.Account.PersonEmail,
                'owner' => opportunityData.OwnerId
            };
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, Object> updateConsent(String recordId) {
        try {
            Map<String, Object> result;
            Opportunity opportunityData = [
                SELECT Id, AccountId
                FROM Opportunity
                WHERE Id = :recordId
                LIMIT 1
            ];
            Account customer = [
                SELECT Id, Consent_to_Automated_Communications__c
                FROM Account
                WHERE Id = :opportunityData.AccountId
            ];

            if (!customer.Consent_to_Automated_Communications__c) {
                customer.Consent_to_Automated_Communications__c = true;
                update customer;
            }
            result = new Map<String, Object>{ 'customer' => customer };
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
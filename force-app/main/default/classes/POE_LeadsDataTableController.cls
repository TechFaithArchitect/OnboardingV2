public with sharing class POE_LeadsDataTableController {
    @AuraEnabled(cacheable=true)
    public static List<Lead> getLeads(String searchKey, String sortBy, String sortDirection) {
        Id profileId = UserInfo.getProfileId();

        String profileName = [SELECT Id, Name FROM Profile WHERE Id = :profileId].Name;
        String leadStatus = 'Closed Lost';
        String query = 'SELECT Name, Email, Phone, Status, LeadSource, Lead_Owner__c, Company,  OwnerId FROM Lead';
        if (searchKey != null && searchKey != '') {
            String key = '%' + searchKey + '%';

            query += ' WHERE Status != :leadStatus AND IsConverted = false AND Name LIKE ' + '\'' + key + '\'';
        } else {
            query += ' WHERE Status != :leadStatus AND IsConverted = false';
        }

        if (sortBy != null && sortDirection != null) {
            query += ' ORDER BY ' + sortBy + ' ' + sortDirection;
        }
        try {
            return Database.query(query);
        } catch (Exception e) {
            throw new AuraHandledException('An error occurred: ' + e.getMessage());
        }
    }
}
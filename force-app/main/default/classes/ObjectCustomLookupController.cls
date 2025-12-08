public without sharing class ObjectCustomLookupController {
    // Method to fetch lookup search result   
    @AuraEnabled(cacheable=true)
    public static list<sObject> fetchLookupData(string searchKey , string sObjectApiName, String additionalFilters, String additionalFields) {    
        try {
            List <sObject> returnList = new List <sObject>();
            String sWildCardText = '%' + searchKey + '%';
    
            String sQuery = 'SELECT Id, Name '; 
            if (additionalFields != null && additionalFields != '') {
                sQuery += ',' + additionalFields;
            }
            sQuery += ' FROM ' + sObjectApiName + ' WHERE Name LIKE :sWildCardText';
            if (additionalFilters != null && additionalFilters != ''){
                sQuery += ' AND ' + additionalFilters;
            }
            sQuery += ' LIMIT 5';
            for (sObject obj: database.query(sQuery)) {
                returnList.add(obj);
            }
            return returnList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }   
    
}
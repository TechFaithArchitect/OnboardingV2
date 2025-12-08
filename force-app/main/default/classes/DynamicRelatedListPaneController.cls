public without sharing class DynamicRelatedListPaneController {
    
    public static final String SELECT_SENTENCE = 'SELECT ';
    public static final String FROM_SENTENCE = ' FROM ';
    public static final String WHERE_SENTENCE = ' WHERE ';
    public static final String LIMIT_SENTENCE = ' LIMIT ';

    @AuraEnabled
    public static List<SObject> getRecordsByCriteria(Map<String, Object> myData){
        try {
            String parentRecordId = (String) myData.get('parentRecordId');
            String objectName = (String) myData.get('objectName');
            String filterCriteria = (String) myData.get('filterCriteria');
            String fieldList = (String) myData.get('fieldList');
            Decimal limitRecords = (Decimal) myData.get('limitRecords');
            List<String> fields = fieldList?.split(',');

            String searchQueryString = SELECT_SENTENCE + fieldList +
                                       FROM_SENTENCE + objectName +
                                       WHERE_SENTENCE + filterCriteria + '\'' + parentRecordId + '\'';
            if (limitRecords != null) {
                searchQueryString = searchQueryString + LIMIT_SENTENCE + limitRecords;
            }

            List<SObject> foundRecords = Database.query(searchQueryString);
            return foundRecords;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, Object> getParentRecordInfo(Id recordId) {
        try {
            Schema.DescribeSObjectResult sobjectDescribe = recordId.getSObjectType().getDescribe();
            String sobjectApiName = sobjectDescribe.getName();
            String query = 'SELECT Name FROM ' + sobjectApiName + ' WHERE Id = :recordId';
            List<SObject> sobjectList = Database.query(query);

            Map<String, Object> result = new Map<String, Object> {
                'sobjectPluralLabel' => sobjectDescribe.getLabelPlural(),
                'sobjectApiName' => sobjectDescribe.getName(),
                'parentRecordLabel' => sobjectList[0].get('Name')
            };

            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
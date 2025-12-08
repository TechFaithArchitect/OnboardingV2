public without sharing class POE_NewCaseOverrideController {

    private static final String OMMITTED_RECORD_TYPE = 'National_Retail_Store';
    
    @AuraEnabled(cacheable=true)
    public static List<RecordTypeWrapper> getCaseRecordTypes() {
        try {
            List<RecordTypeWrapper> recordTypeWrappers = new List<RecordTypeWrapper>();
            List<RecordType> caseRecordTypes = [
                SELECT Id, Description
                FROM RecordType 
                WHERE SobjectType = 'Case'
                ORDER BY Name ASC
            ];

            Schema.DescribeSObjectResult caseDescribeResult = Case.SObjectType.getDescribe();
            Map<Id, Schema.RecordTypeInfo> recordTypeInfosById = caseDescribeResult.getRecordTypeInfosById();
            for (RecordType caseRT : caseRecordTypes) {
                Schema.RecordTypeInfo caseRTInfo = recordTypeInfosById.get(caseRT.Id);
                if (!caseRTInfo.isActive() || !caseRTInfo.isAvailable() 
                    || caseRTInfo.getDeveloperName() == OMMITTED_RECORD_TYPE) {
                    continue;
                }

                RecordTypeWrapper recordTypeWrapper = new RecordTypeWrapper();
                recordTypeWrapper.objectApiName = caseDescribeResult.getName();
                recordTypeWrapper.recordTypeId = caseRT.Id;
                recordTypeWrapper.description = caseRT.Description;
                recordTypeWrapper.name = caseRTInfo.getName();
                recordTypeWrapper.isAvailable = caseRTInfo.isAvailable();
                recordTypeWrapper.isDefault = caseRTInfo.isDefaultRecordTypeMapping();

                recordTypeWrappers.add(recordTypeWrapper);
            }

            return recordTypeWrappers;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class RecordTypeWrapper {
        @AuraEnabled
        public String objectApiName;
        @AuraEnabled
        public String recordTypeId;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String description;
        @AuraEnabled
        public Boolean isAvailable;
        @AuraEnabled
        public Boolean isDefault;
    }
}
public without sharing class ErrorLogModel {
    @AuraEnabled
    public static Error_Log__c logError(ErrorLogWrapper error) {
        Error_Log__c errorLog = new Error_Log__c();

        try {
            errorLog.Type__c = error.type != null ? error.type : null;
            errorLog.Provider__c = error.provider != null ? error.provider : null;
            errorLog.Provider_Subtype__c = error.providerSubtype != null ? error.providerSubtype : null;
            errorLog.Tab__c = error.tab != null ? error.tab : null;
            errorLog.Component__c = error.component != null ? error.component : null;
            errorLog.Error__c = error.error != null ? error.error : null;
            errorLog.Endpoint__c = error.endpoint != null ? error.endpoint : null;
            errorLog.Request__c = error.request != null ? error.request : null;
            errorLog.Opportunity__c = error.opportunity != null ? error.opportunity : null;

            insert errorLog;

            return errorLog;
        } catch (Exception exc) {
            throw new AuraHandledException(exc.getMessage());
        }
    }

    @AuraEnabled
    public static Error_Log__c logPublicError(ErrorLogWrapper error) {
        String decryptedOppId = error.opportunity;
        try {
            decryptedOppId = POE_PublicRecordAccessUtility.decryptRecordId(error.opportunity);
        } catch (Exception e) {
            decryptedOppId = null;
        }

        error.opportunity = decryptedOppId;
        return ErrorLogModel.logError(error);
    }
}
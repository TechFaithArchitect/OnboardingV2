public with sharing class POE_RegExObtainer {
    @AuraEnabled(cacheable=true)
    public static ResponseWrapper getOnlyLettersRegEx() {
        try {
            ResponseWrapper res = new ResponseWrapper();

            POE_Chuzo_Regular_Expressions__mdt regex = POE_Chuzo_Regular_Expressions__mdt.getInstance('Only_Letters');

            res.result = new Map<String, Object>{ 'expression' => regex.RegEx__c, 'errorMessage' => regex.Error_Message__c };
            return res;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class ResponseWrapper {
        @AuraEnabled
        public Map<String, Object> result;
    }
}
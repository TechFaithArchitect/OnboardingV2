public with sharing class FooterChuzoController {
    @AuraEnabled(cacheable=true)
    public static Chuzo_Settings__c getManualPDFLinkCustomSetting(){
        try {
            Chuzo_Settings__c settings = Chuzo_Settings__c.getOrgDefaults();

            return settings;
        } catch (Exception e) { throw new AuraHandledException(e.getMessage()); }
    }
}
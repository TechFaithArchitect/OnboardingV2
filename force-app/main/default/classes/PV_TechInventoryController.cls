public with sharing class PV_TechInventoryController {
    private static final String FIELD_SERVICE_SITE_NAME = 'Field_Service1';

    @AuraEnabled(cacheable=true)
    public static string getTechProductUrl() {
        try {
            Site site = [SELECT Id FROM Site WHERE Name = :FIELD_SERVICE_SITE_NAME];
            SiteDetail siteDetail = [SELECT SecureURL FROM SiteDetail WHERE DurableId = :site.Id];
            return siteDetail.SecureURL
                + Label.PVTechProductURL;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
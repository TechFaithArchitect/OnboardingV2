public with sharing class EmailCatalogCMDTRepository {
    @TestVisible private static Map<String, Email_Template_Catalog__mdt> testMockCatalogs;

    public static void setMockCatalogs(Map<String, Email_Template_Catalog__mdt> mockCatalogs) {
        testMockCatalogs = mockCatalogs;
    }

    // 🔹 Get all existing CMDT records
    public static Map<String, Email_Template_Catalog__mdt> getAllEmailCatalogs() {
        if (Test.isRunningTest() && testMockCatalogs != null) {
            return testMockCatalogs;
        }

        Map<String, Email_Template_Catalog__mdt> result = new Map<String, Email_Template_Catalog__mdt>();
        for (Email_Template_Catalog__mdt rec : [
            SELECT DeveloperName__c, MasterLabel, Folder_Name__c,
                   Communication_Type__c, Active__c, Description__c
            FROM Email_Template_Catalog__mdt
        ]) {
            result.put(rec.DeveloperName__c, rec);
        }
        return result;
    }

    // 🔹 Build a Custom Metadata record
    public static Metadata.CustomMetadata buildCMDT(EmailTemplateDTO dto, Id jobId) {
        Metadata.CustomMetadata m = new Metadata.CustomMetadata();
        m.fullName = 'Email_Template_Catalog.' + dto.developerName;
        m.label = dto.name;
        m.values = new List<Metadata.CustomMetadataValue>();

        addValue(m, 'DeveloperName__c', dto.developerName);
        addValue(m, 'Folder_Name__c', dto.folder);
        addValue(m, 'Communication_Type__c', dto.commType);
        addValue(m, 'Active__c', dto.isActive);
        addValue(m, 'Description__c', dto.subject);
        addValue(m, 'Sync_Job_Id__c', String.valueOf(jobId));

        return m;
    }

    private static void addValue(Metadata.CustomMetadata m, String fieldName, Object value) {
        Metadata.CustomMetadataValue customMetadataValue = new Metadata.CustomMetadataValue();
        customMetadataValue.field = fieldName;
        customMetadataValue.value = value;
        m.values.add(customMetadataValue);
    }

    // 🔹 Bulk deploy CMDTs
    public static Id deployMetadata(List<Metadata.Metadata> records) {
        if (records == null || records.isEmpty()) return null;

        if (Test.isRunningTest()) {
            System.debug('⚠️ Skipping Metadata deployment during test context.');
            return [SELECT Id FROM User LIMIT 1].Id;  // You can sub this out with fakeAsyncId() if preferred
        }

        Metadata.DeployContainer container = new Metadata.DeployContainer();
        for (Metadata.Metadata m : records) {
            container.addMetadata(m);
        }

        return Metadata.Operations.enqueueDeployment(container, null);
    }

    // 🔹 Upsert CMDTs with diff check
    public static EmailSyncSummaryDTO upsertCMDTs(List<EmailTemplateDTO> dtos, Id jobId) {
        EmailSyncSummaryDTO summary = new EmailSyncSummaryDTO();
        if (dtos == null || dtos.isEmpty()) return summary;

        Map<String, Email_Template_Catalog__mdt> existing = getAllEmailCatalogs();
        Metadata.DeployContainer container = new Metadata.DeployContainer();
        Integer changedCount = 0;

        for (EmailTemplateDTO dto : dtos) {
            String key = dto.developerName;

            Boolean unchanged = existing.containsKey(key) &&
                existing.get(key).Folder_Name__c == dto.folder &&
                existing.get(key).Communication_Type__c == dto.commType &&
                existing.get(key).Active__c == dto.isActive &&
                existing.get(key).Description__c == dto.subject;

            if (unchanged) continue;

            Metadata.CustomMetadata cmdtRecord = buildCMDT(dto, jobId);
            container.addMetadata(cmdtRecord);
            changedCount++;
        }

        if (!container.getMetadata().isEmpty()) {
            Id asyncId = deployMetadata(container.getMetadata());
            summary.asyncOperationId = asyncId;
            summary.asyncOperationIdStr = String.valueOf(asyncId);
            summary.newCMDTCount = changedCount;

            System.debug('🚀 CMDT Upsert: ' + changedCount + ' records changed. Async ID: ' + asyncId);
        } else {
            System.debug('✅ No CMDT changes detected.');
        }

        return summary;
    }
}

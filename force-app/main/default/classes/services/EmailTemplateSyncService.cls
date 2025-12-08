public with sharing class EmailTemplateSyncService {

    // -------------------------------------
    // Config & Test Flags
    // -------------------------------------
    @TestVisible private static Boolean forceFail = false;
    private static final Integer BATCH_SIZE = 200;

    // -------------------------------------
    // Public Entry Point
    // -------------------------------------
    public EmailSyncSummaryDTO syncAllTemplates(Id jobId) {
        if (Test.isRunningTest() && forceFail) {
            throw new EmailSyncException('Forced failure in test');
        }

        Datetime startTime = Datetime.now();
        System.debug('🚀 [EmailTemplateSyncService] Starting sync at ' + startTime);

        EmailSyncSummaryDTO summary = new EmailSyncSummaryDTO();
        summary.jobId = jobId;
        summary.jobName = 'Email Template Sync';
        summary.manualRun = false;

        // Step 1️⃣ - Load source & destination data
        List<EmailTemplateDTO> templates = EmailTemplateRepository.getAllActiveTemplates();
        Map<String, Email_Template_Catalog__mdt> existingCMDTs = EmailCatalogCMDTRepository.getAllEmailCatalogs();
        Map<String, Communication_Template__c> existingComms = CommunicationTemplateRepository.getAllTemplates();

        // Step 2️⃣ - Compare and build worksets
        List<Metadata.CustomMetadata> newCmdts = new List<Metadata.CustomMetadata>();
        List<Communication_Template__c> inserts = new List<Communication_Template__c>();
        List<Communication_Template__c> updates = new List<Communication_Template__c>();

        for (EmailTemplateDTO dto : templates) {
            if (!existingCMDTs.containsKey(dto.developerName)) {
                newCmdts.add(EmailCatalogCMDTRepository.buildCMDT(dto, jobId));
                summary.newCMDTCount++;
            }

            if (existingComms.containsKey(dto.developerName)) {
                Communication_Template__c existing = existingComms.get(dto.developerName);
                if (dto.hasChanges(existing)) {
                    Communication_Template__c updated = dto.toSObject(existing);
                    updated.Sync_Job__c = jobId;
                    updates.add(updated);
                    summary.updatedCount++;
                }
            } else {
                Communication_Template__c newRec = dto.toSObject();
                newRec.Sync_Job__c = jobId;
                inserts.add(newRec);
                summary.insertedCount++;
            }
        }

        // Step 3️⃣ - Persist changes using retry-safe repository method
        if (!inserts.isEmpty()) CommunicationTemplateRepository.saveWithRetry(inserts, true);
        if (!updates.isEmpty()) CommunicationTemplateRepository.saveWithRetry(updates, false);

        // Step 4️⃣ - Deploy CMDT metadata
        if (!newCmdts.isEmpty()) {
            summary.asyncOperationId = EmailCatalogCMDTRepository.deployMetadata(newCmdts);
            System.debug('🧩 [CMDT] Deployment enqueued. Async ID: ' + summary.asyncOperationId);
        }

        // Step 5️⃣ - Compute duration
        summary.durationSeconds = (Datetime.now().getTime() - startTime.getTime()) / EmailSyncServiceConstants.MILLISECONDS_TO_SECONDS;
        System.debug('✅ [EmailTemplateSyncService] Completed: ' +
            'Inserted=' + summary.insertedCount + 
            ', Updated=' + summary.updatedCount +
            ', New CMDTs=' + summary.newCMDTCount +
            ', Duration=' + summary.durationSeconds + 's');

        return summary;
    }

    // -------------------------------------
    // Local Exception
    // -------------------------------------
    public class EmailSyncException extends Exception {}
}

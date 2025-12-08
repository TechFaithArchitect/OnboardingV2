public class OrgWideEmailSyncOrchestrator {
    public static void runFullSync(Boolean isManual) {
        Datetime start = Datetime.now();
        System.debug('Org-Wide Email Sync started at ' + start.format());

        Sync_Log__c logRec = UtilitiesSyncLogHelper.createLogRecord('Org-Wide Email Sync', isManual);

        try {
            EmailSyncSummaryDTO summary = OrgWideEmailSyncService.syncAll(logRec.Id);

            UtilitiesSyncLogHelper.updateLogRecord(logRec.Id, summary);
            System.debug('Org-Wide Sync completed: ' + summary.toString());

        } catch (Exception e) {
            UtilitiesSyncLogHelper.markFailed(logRec.Id, e);
            System.debug('Sync failed: ' + e.getMessage());
        }

        System.debug('Org-Wide Email Sync finished at ' + Datetime.now().format());
    }
}
public with sharing class EmailTemplateSyncJob implements Schedulable {

    public void execute(SchedulableContext ctx) {
        try {
            EmailTemplateSyncOrchestrator.run(false);
        } catch (Exception e) {
            System.debug('❌ Email Template Sync Job failed: ' + e.getMessage());
        }
    }
}
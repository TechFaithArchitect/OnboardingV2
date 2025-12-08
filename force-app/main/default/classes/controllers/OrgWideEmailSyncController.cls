public class OrgWideEmailSyncController implements Schedulable {
    public void execute(SchedulableContext ctx) {
        try {
            OrgWideEmailSyncOrchestrator.runFullSync(false);
        } catch (Exception e) {
            System.debug('Sync failed in controller: ' + e.getMessage());
        }
    }
}

public class OrgWideEmailSyncController implements Schedulable {
    public void execute(SchedulableContext ctx) {
        try {
            OrgWideEmailSyncOrchestrator.runFullSync(false);
        } catch (Exception ex) {
            System.debug('Sync failed in controller: ' + ex.getMessage());
        }
    }
}
public class EmailTemplateSyncController implements Schedulable {
    public void execute(SchedulableContext ctx) {
        try {
            EmailTemplateSyncOrchestrator.run(false);
        } catch (Exception ex) {
            System.debug('❌ Sync failed in controller: ' + ex.getMessage());
        }
    }
}
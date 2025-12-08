public class EmailTemplateSyncController implements Schedulable {
    public void execute(SchedulableContext ctx) {
        try {
            EmailTemplateSyncOrchestrator.run(false);
        } catch (Exception e) {
            System.debug('❌ Sync failed in controller: ' + e.getMessage());
        }
    }
}

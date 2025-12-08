global class FSL_DeleteDummyOrdersBatchScheduler implements Schedulable {
    global void execute(SchedulableContext SC) {
        FSL_DeleteDummyOrdersBatch batch = new FSL_DeleteDummyOrdersBatch();
        Database.executeBatch(batch, 200);
    }
}
global class PV_WorkTypeSRBatchScheduler implements Schedulable {
   global void execute(SchedulableContext sc) {
      PV_WorkTypeSRBatch b = new PV_WorkTypeSRBatch();
      Database.executeBatch(b);
   }
}
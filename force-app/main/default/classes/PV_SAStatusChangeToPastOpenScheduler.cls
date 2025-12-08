global class PV_SAStatusChangeToPastOpenScheduler implements Schedulable {
   global void execute(SchedulableContext sc) {
      PV_SAStatusChangeToPastOpenBatch b = new PV_SAStatusChangeToPastOpenBatch(); 
      Database.executeBatch(b);
       
   }
}
global class PV_SAStatusChangeToDispatchScheduler implements Schedulable {
   global void execute(SchedulableContext sc) {
      PV_SAStatusChangeToDispatchBatch b = new PV_SAStatusChangeToDispatchBatch(); 
      Database.executeBatch(b);
       
   }
}
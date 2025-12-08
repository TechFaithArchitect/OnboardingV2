global class PV_AssignChildTerritoryBatchScheduler implements Schedulable {
   global void execute(SchedulableContext sc) {
      PV_AssignChildTerritoryBatch b = new PV_AssignChildTerritoryBatch();
      Database.executeBatch(b);
   }
}
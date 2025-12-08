global class PV_SRCertStatusChangeBatchScheduler implements Schedulable{
 global void execute(SchedulableContext sc) {
      PV_SRCertificationStatusChangeBatch b = new PV_SRCertificationStatusChangeBatch(); 
      Database.executeBatch(b);    
   }
}
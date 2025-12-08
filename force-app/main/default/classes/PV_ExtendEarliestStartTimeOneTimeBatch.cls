global class PV_ExtendEarliestStartTimeOneTimeBatch implements Database.Batchable<sObject>, Schedulable {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        List<String> statusSA = Label.PV_SAStatus.split(',');
        
        String query = 
            'SELECT Id, EarliestStartTime ' +
            'FROM   ServiceAppointment ' +
            'WHERE  Status IN :statusSA ' +
            'AND    WorkType.Extended_Start_Time_Exclusion__c = false'
        ;

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<ServiceAppointment> serviceAppointments) {
        try {
            for (ServiceAppointment serviceAppointment : serviceAppointments) { 
                DateTime extendedDate = System.now().addDays(3);
                serviceAppointment.EarliestStartTime = DateTime.newInstance(extendedDate.date(), Time.newInstance(0, 0, 0, 0));
            }
            
            Database.update(serviceAppointments, false);
        } catch (Exception e) {
            ExceptionUtil.publishFSLException('Internal Error', 'FSL', PV_ExtendEarliestStartTimeOneTimeBatch.class.getName(), e.getMessage());
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        
    }
    global void execute(SchedulableContext sc) {
        PV_ExtendEarliestStartTimeOneTimeBatch batch = new PV_ExtendEarliestStartTimeOneTimeBatch(); 
        Database.executeBatch(batch);
    }
}
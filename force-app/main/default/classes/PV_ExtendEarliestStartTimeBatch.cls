global class PV_ExtendEarliestStartTimeBatch implements Database.Batchable<sObject>, Schedulable {
    
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
            Integer defaultExtendedDays = Integer.valueOf(PV_FSL_Config__mdt.getInstance('Add_Days').Value__c);

            for (ServiceAppointment serviceAppointment : serviceAppointments) { 
                DateTime extendedDate = serviceAppointment.EarliestStartTime.addDays(defaultExtendedDays);
                serviceAppointment.EarliestStartTime = extendedDate;
            }
            
            Database.update(serviceAppointments, false);
        } catch (Exception e) {
            ExceptionUtil.publishFSLException('Internal Error', 'FSL', PV_ExtendEarliestStartTimeBatch.class.getName(), e.getMessage());
        }
    }
    
    global void finish(Database.BatchableContext BC) {
    }
    
    global void execute(SchedulableContext sc) {
        PV_ExtendEarliestStartTimeBatch batch = new PV_ExtendEarliestStartTimeBatch(); 
        Database.executeBatch(batch);
    }
}
global class PV_SAStatusChangeToDispatchBatch implements Database.Batchable<sObject> {
    @testVisible private static Boolean throwException = false;
    public Map<String, Integer> vendorDaysBeforeUpdateMap = getVendorDaysBeforeUpdateMap();

    global Database.QueryLocator start(Database.BatchableContext BC) {
        vendorDaysBeforeUpdateMap = getVendorDaysBeforeUpdateMap();
        List<String> vendors = new List<String>(vendorDaysBeforeUpdateMap.keySet());
        
        String query = 
            'SELECT Id, Status, SchedStartTime, AppointmentNumber, FSSK__FSK_Work_Order__r.Vendor__c ' +
            'FROM   ServiceAppointment ' +
            'WHERE  Status = \'Scheduled\' ' +
            'AND    SchedStartTime <> null ' +
            'AND    FSSK__FSK_Work_Order__r.Vendor__c IN :vendors'
        ;

        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<ServiceAppointment> serviceAppointments) {
        try {
            List<ServiceAppointment> serviceAppointmentsToUpdate = new List<ServiceAppointment>();
            
            for (ServiceAppointment serviceAppointment : serviceAppointments) {
                Integer daysBeforeUpdate = vendorDaysBeforeUpdateMap.get(serviceAppointment.FSSK__FSK_Work_Order__r.Vendor__c);
                Datetime targetDatetime = serviceAppointment.SchedStartTime.addDays(-daysBeforeUpdate);

                if (Datetime.now() >= targetDatetime) {
                    serviceAppointment.Status = 'Dispatched';
                    serviceAppointmentsToUpdate.add(serviceAppointment);
                }
            }

            updateServiceAppointments(serviceAppointmentsToUpdate);
            
            if (Test.isRunningTest() && throwException) {
                throw new CustomException();
            }
        } catch (Exception e) {
            ExceptionUtil.publishFSLException('Internal Error', 'FSL', PV_SAStatusChangeToDispatchBatch.class.getName(), e.getMessage());
   		}
    }   
    
    global void finish(Database.BatchableContext BC) {
    }

    public static Map<String, Integer> getVendorDaysBeforeUpdateMap() {
        List<Dispatch_Update_Configuration__mdt> configs = Dispatch_Update_Configuration__mdt.getAll().values();
        Map<String, Integer> vendorDaysBeforeUpdate = new Map<String, Integer>();
        
        for (Dispatch_Update_Configuration__mdt config : configs) {
            vendorDaysBeforeUpdate.put(config.Vendor__c, Integer.valueOf(config.Days_Before_Update__c));
        }

        return(vendorDaysBeforeUpdate);
    }

    public static void updateServiceAppointments(List<ServiceAppointment> serviceAppointmentsToUpdate) {
        List<Database.SaveResult> saveResults = Database.update(serviceAppointmentsToUpdate, false);
        String firstErrorType = null;
        String firstErrorRecordId = null;
        
        for (Database.SaveResult sr : saveResults) {
            if (!sr.isSuccess() && !sr.getErrors().isEmpty()) {
                Database.Error firstError = sr.getErrors()[0];
                firstErrorType = firstError.getStatusCode() + ': ' + firstError.getMessage();
                firstErrorRecordId = sr.getId();
                break;
            }
        }
        
        if ((firstErrorType != null) || (Test.isRunningTest() && throwException)) {
            String errorMessage = 'Record ID: ' + firstErrorRecordId + ' - Error Type: ' + firstErrorType;
            ExceptionUtil.publishFSLException('Internal Error', 'FSL', PV_SAStatusChangeToDispatchBatch.class.getName(), errorMessage);
        }
    }
}
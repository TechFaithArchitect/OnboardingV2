global class PV_SAStatusChangeToPastOpenBatch implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        //DIRECTV,T-Mobile
        List<String> vendorTypes = Label.PV_VendorTypes.split(',');
        
        //collect the batches of records to be passed to execute
        return Database.getQueryLocator([SELECT Id,Status,SchedStartTime,AppointmentNumber,FSSK__FSK_Work_Order__C
                                         FROM ServiceAppointment 
                                         WHERE SchedStartTime=YESTERDAY AND (Status ='Enroute' OR Status ='Dispatched' OR Status ='Acknowledge' OR Status ='Onsite') AND FSSK__FSK_Work_Order__r.Vendor__c IN:vendorTypes]);
        
    }
    
    global void execute(Database.BatchableContext BC, List<ServiceAppointment> SAList) {
        try {
            // process each batch of records default size is 200
            for(ServiceAppointment sa : SAList) {        
                // Update the ServiceAppointment Status 
                sa.Status = 'Past Open';
            }
            // Update the ServiceAppointment Record
            update SAList;
            
        } catch (Exception ex) {
            ExceptionUtil.publishException('PV_SAStatusChangeToPastOpenBatch.execute', ex.getLineNumber(), ex.getMessage(), ex.getStackTraceString());
        }
    }   
    
    global void finish(Database.BatchableContext BC) {
        
    }
}
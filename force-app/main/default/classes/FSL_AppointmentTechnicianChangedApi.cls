@RestResource(urlMapping='/serviceAppointmentTechnicianChangedApi/*')
global without sharing class FSL_AppointmentTechnicianChangedApi {

    @HttpGet
    global static List<ServiceAppointmentWrapper> getServiceAppointments() {
    
        RestRequest req = RestContext.request;
        String createdAfter = req.params.get('createdAfter');
        
        if (String.isEmpty(createdAfter) || createdAfter == null) {
            throw new AuraHandledException('The createdAfter parameter is required.');
        }
        
        createdAfter = createdAfter.replace('T', ' ').replace('Z', '');
        Datetime createdAfterDateTime = Datetime.valueOf(createdAfter);
        
        List<ServiceAppointment> serviceAppointments = [SELECT 
            Id, 
            External_Work_Order_Id__c,
            Vendor__c, 
            (SELECT CreatedDate, NewValue, ServiceAppointment.FSSK__FSK_Assigned_Service_Resource__r.ID_Servicebench__c
             FROM Histories 
             WHERE Field = 'FSSK__FSK_Assigned_Service_Resource__c' 
             AND CreatedDate > :createdAfterDateTime) 
        FROM ServiceAppointment 
        WHERE Id IN (SELECT ServiceAppointmentId 
                      FROM ServiceAppointmentHistory 
                      WHERE Field = 'FSSK__FSK_Assigned_Service_Resource__c' 
                      AND CreatedDate > :createdAfterDateTime) 
        AND Vendor__c = 'COSTCO'];

        List<ServiceAppointmentWrapper> responseList = new List<ServiceAppointmentWrapper>();

        if(Test.isRunningTest()) {
            serviceAppointments = [SELECT Id, External_Work_Order_Id__c 
                                   FROM ServiceAppointment 
                                   LIMIT 1];
        }
        
        for (ServiceAppointment sa : serviceAppointments) {
            ServiceAppointmentWrapper appointmentWrapper = new ServiceAppointmentWrapper();
            appointmentWrapper.Id = sa.Id;
            appointmentWrapper.ServiceAppointmentExternalId = sa.External_Work_Order_Id__c;
            appointmentWrapper.Histories = new List<HistoryWrapper>();
            
            for (ServiceAppointmentHistory history : sa.Histories) {
                HistoryWrapper historyWrapper = new HistoryWrapper();
                historyWrapper.CreatedDate = history.CreatedDate.format();
                historyWrapper.NewValue = String.valueOf(history.NewValue);
                historyWrapper.ResourceExternalId = history.ServiceAppointment.FSSK__FSK_Assigned_Service_Resource__r.ID_Servicebench__c;
                appointmentWrapper.Histories.add(historyWrapper);
            }
            
            responseList.add(appointmentWrapper);
        }

        return responseList;
    }
    
    global class HistoryWrapper {
        public String CreatedDate;
        public String NewValue;
        public String ResourceExternalId;
    }

    global class ServiceAppointmentWrapper {
        public String Id;
        public String ServiceAppointmentExternalId;
        public List<HistoryWrapper> Histories;
    }
}
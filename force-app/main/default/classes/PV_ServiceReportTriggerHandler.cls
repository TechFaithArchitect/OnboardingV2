public class PV_ServiceReportTriggerHandler {
    public static void handleAfterInsert(List<ServiceReport> newServiceReportList) {

        Map<Id, Id> contenVersionWorkOrderMap = new Map<Id, Id>();
        List<Id> templateIdList = new List<Id>();
        Map<Id, String> serviceReportLayoutMap = new Map<Id, String>();
        Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>();
        Map<Id, ServiceAppointment> serviceAppointmentMap = new Map<Id, ServiceAppointment>();
        List<ContentVersion> updatedContentVersion = new List<ContentVersion>();

        for (ServiceReport serviceReport : newServiceReportList) {
            contenVersionWorkOrderMap.put(serviceReport.ContentVersionDocumentId, serviceReport.ParentId);
            templateIdList.add(serviceReport.Template);
        }

        List<WorkOrder> workOrderList = [SELECT Id, External_WO_Id__c FROM WorkOrder WHERE Id IN :contenVersionWorkOrderMap.values()];
        for (WorkOrder workOrderMapping : workOrderList) {
            workOrderMap.put(workOrderMapping.Id, workOrderMapping);
        }

        List<ServiceAppointment> serviceAppointmentList = [
            SELECT  Id, FSSK__FSK_Work_Order__r.External_WO_Id__c
            FROM    ServiceAppointment 
            WHERE   Id IN :contenVersionWorkOrderMap.values()
        ];

        for (ServiceAppointment serviceAppointmentMapping : serviceAppointmentList) {
            serviceAppointmentMap.put(serviceAppointmentMapping.Id, serviceAppointmentMapping);
        }
        
        List<ServiceReportlayout> serviceReportLayoutList = [
            SELECT  Id, DeveloperName
            FROM    ServiceReportlayout
            WHERE   Id IN :templateIdList
        ];

        for (ServiceReportLayout serviceReportLayout : serviceReportLayoutList) {
            serviceReportLayoutMap.put(serviceReportLayout.Id, serviceReportLayout.DeveloperName);
        }

        for (ServiceReport serviceReport : newServiceReportList) {
            ContentVersion contentVersion = new ContentVersion();
            Schema.SObjectType objectType = serviceReport.ParentId.getSObjectType();
            String objectName = objectType.getDescribe().getName();

            if (objectName == 'WorkOrder') {
                contentVersion.Title = workOrderMap.get(serviceReport.ParentId).External_WO_Id__c + '_' + serviceReportLayoutMap.get(serviceReport.Template);
            } else if (objectName == 'ServiceAppointment') {
                String relatedExternalWorkOrderId = serviceAppointmentMap.get(serviceReport.ParentId).FSSK__FSK_Work_Order__r.External_WO_Id__c;
                contentVersion.Title = relatedExternalWorkOrderid + '_' + serviceReportLayoutMap.get(serviceReport.Template);
            }

            contentVersion.Id = serviceReport.ContentVersionDocumentId;
            updatedContentVersion.add(contentVersion);
        }
        update updatedContentVersion;
    }
}
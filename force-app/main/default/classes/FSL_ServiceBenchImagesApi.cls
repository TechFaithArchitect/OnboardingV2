@RestResource(urlMapping='/serviceBenchImagesApi/*')
global without sharing class FSL_ServiceBenchImagesApi {

    @HttpGet
    global static void getNewImages() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String createdAfter = req.params.get('createdAfter');

        if (String.isEmpty(createdAfter)) {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf('Missing required parameters: createdAfter');
            return;
        }

        createdAfter = createdAfter.replace('T', ' ').replace('Z', '');
        Datetime createdAfterDateTime = Datetime.valueOf(createdAfter);

        Map<Id, Datetime> contentDocCreatedDateMap = new Map<Id, Datetime>();
        Map<Id, Id> contentDocIdMap = new Map<Id, Id>();

        for(ContentVersion content : [SELECT Id, ContentDocumentId, CreatedDate
                                      FROM ContentVersion 
                                      WHERE CreatedDate >= :createdAfterDateTime]) {
            contentDocCreatedDateMap.put(content.ContentDocumentId, content.CreatedDate);
            contentDocIdMap.put(content.ContentDocumentId, content.Id);
        }

        List<ResponseWrapper> responseList = new List<ResponseWrapper>();

        if (!contentDocCreatedDateMap.isEmpty()) {
            List<ContentDocumentLink> documentLinks = [
                SELECT ContentDocumentId, LinkedEntityId, 
                TYPEOF LinkedEntity 
                    WHEN WorkOrder THEN Id, External_WO_Id__c , Vendor__c 
                    WHEN ServiceAppointment THEN ParentRecordId, External_Work_Order_Id__c, Vendor__c 
                END  
                FROM ContentDocumentLink
                WHERE ContentDocumentId IN :contentDocCreatedDateMap.keySet()
            ];
        
            for (ContentDocumentLink cdl : documentLinks) {
                if (cdl.LinkedEntityId != null && cdl.LinkedEntity instanceof WorkOrder) {
                    WorkOrder wo = (WorkOrder) cdl.LinkedEntity; 
                    if (wo.External_WO_Id__c != null && wo.Vendor__c == 'COSTCO') {
                        responseList.add(new ResponseWrapper(
                            contentDocIdMap.get(cdl.ContentDocumentId),
                            contentDocCreatedDateMap.get(cdl.ContentDocumentId).format(),
                            wo.External_WO_Id__c,
                            wo.Id
                        ));
                    }
                }
                if (cdl.LinkedEntityId != null && cdl.LinkedEntity instanceof ServiceAppointment) {
                    ServiceAppointment sa = (ServiceAppointment) cdl.LinkedEntity; 
                    if (sa.External_Work_Order_Id__c != null && sa.Vendor__c == 'COSTCO') {
                        responseList.add(new ResponseWrapper(
                            contentDocIdMap.get(cdl.ContentDocumentId),
                            contentDocCreatedDateMap.get(cdl.ContentDocumentId).format(),
                            sa.External_Work_Order_Id__c,
                            sa.ParentRecordId
                        ));
                    }
                }
            }
        }
	 	
        res.addHeader('Content-Type', 'application/json');
        res.responseBody = Blob.valueOf(JSON.serialize(responseList));
    }

    global class ResponseWrapper {
        public String contentVersionId;
        public String createdDate;
        public String workOrderExternalId;
        public String worOrderId;

        public ResponseWrapper(String contentDocumentId, String createdDate, String workOrderExternalId, String workOrderId) {
            this.contentVersionId = contentDocumentId;
            this.createdDate = createdDate;
            this.workOrderExternalId = workOrderExternalId;
            this.worOrderId = workOrderId;
        }
    }
}
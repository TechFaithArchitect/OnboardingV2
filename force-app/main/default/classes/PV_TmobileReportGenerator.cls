public class PV_TmobileReportGenerator {
    private final WorkOrder record;
    private Blob pdfContent;
    public List<ContentVersion> relatedImages { get; private set; }
    public String tmoNumber { get; private set; }
    
    
    public PV_TmobileReportGenerator(ApexPages.StandardController stdController) {
        this.record = (WorkOrder)stdController.getRecord();
        Set<Id> contentDocumentIds = new Set<Id>();
        tmoNumber = [SELECT External_WO_Id__c FROM WorkOrder WHERE Id =:record.Id].External_WO_Id__c;
        for(ContentDocumentLink link : [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :record.Id]) {
            contentDocumentIds.add(link.ContentDocumentId);
        }
        relatedImages = [SELECT Id FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentIds AND FileType IN ('JPG', 'PNG','JPEG')];
        
    }
}
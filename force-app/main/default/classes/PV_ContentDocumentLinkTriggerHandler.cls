/**
* @description       : Handler Class for PV_ContentDocumentLinkTrigger & PV_ContentDocumentTrigger
* @author            : Impaqtive DevTeam
* @group             :
* @last modified on  : 13-05-2024
* @last modified by  : Impaqtive DevTeam
* Modifications Log
* Ver   Date         Author            Modification
* 1.0                           Initial Version
**/
public class PV_ContentDocumentLinkTriggerHandler {
    
    public static void handleBeforeInsert (List<ContentDocumentLink> contDoc){
        for(ContentDocumentLink cdl :contDoc){ 
            if(cdl.LinkedEntityId!=null && cdl.LinkedEntityId.getsobjecttype().toString()=='WorkOrder'){
                cdl.Visibility = 'AllUsers';
            }
        }
    }
    public static void handleAfterInsert (List<ContentDocumentLink> contDoc){
        try{
            List<ContentVersion> relatedImages = new List<ContentVersion>();
             List<ContentDocument> conDoc = new List<ContentDocument>();
            Map<Id,String> fileName = new Map<Id,String>();
            Set<Id> contentDocumentIds = new Set<Id>();
            for(ContentDocumentLink cdl:contDoc){
                if(cdl.LinkedEntityId!=null && cdl.LinkedEntityId.getsobjecttype().toString()=='WorkOrder'){
                    contentDocumentIds.add(cdl.ContentDocumentId);
                    system.debug('content docs:'+cdl);
                    
                }
            }
            system.debug('related images:'+fileName);
            relatedImages = [SELECT Id,ContentDocumentId,FirstPublishLocationId FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentIds AND FileType IN ('JPG', 'PNG','JPEG')];
            conDoc = [select id,Title from ContentDocument where id IN :contentDocumentIds];
            for(ContentDocument cd : conDoc){
                
                fileName.put(cd.Id,cd.Title);
            }
            system.debug('file name:'+fileName);
            List<All_Images__c> imgList = new List<All_Images__c>();

            FSL_Settings__c fslSettings = FSL_Settings__c.getInstance();

            for(ContentVersion cv:relatedImages){
                All_Images__c obj = new All_Images__c();
                obj.Work_Order__c = cv.FirstPublishLocationId;
                //obj.VersionId__c = 'https://perfectvisionpoe--impdev.sandbox.file.force.com/sfc/servlet.shepherd/version/renditionDownload?rendition=ORIGINAL_Jpg&versionId='+cv.Id;
                obj.ImageURL__c = fslSettings.Document_URL__c+cv.Id;
                obj.Content_Document_Id__c = cv.ContentDocumentId;
                obj.File_Name__c = fileName.get(cv.ContentDocumentId);
                imgList.add(obj);
            }
            insert imgList;
        }
        catch (Exception ex) {
            ExceptionUtil.publishException('PV_ContentDocumentLinkTriggerHandler.handleBeforeInsert', ex.getLineNumber(), ex.getMessage(), ex.getStackTraceString());
        }
    }
    public static void handleBeforeDelete (List<ContentDocument> contDoc){
        try{
            Set<Id> contentDocumentToDelIds = new Set<Id>();
            Set<Id> contentDocumentLinkIdes = new Set<Id>();
            List<All_Images__c> imgToDelList = new List<All_Images__c>();
            List<ContentDocumentLink> relatedObj = new List<ContentDocumentLink>();
            for(ContentDocument cdl:contDoc){
                contentDocumentToDelIds.add(cdl.Id);
            }
            relatedObj = [SELECT Id,ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN :contentDocumentToDelIds]; 
            for(ContentDocumentLink cdl:relatedObj){
                if(cdl.LinkedEntityId!=null && cdl.LinkedEntityId.getsobjecttype().toString()=='WorkOrder'){
                    contentDocumentLinkIdes.add(cdl.ContentDocumentId);
                }
            }
            imgToDelList = [SELECT id,Content_Document_Id__c,Work_Order__c FROM All_Images__c WHERE Content_Document_Id__c IN:contentDocumentLinkIdes];
            if(!imgToDelList.isEmpty()){
                delete imgToDelList;
            }
        }
        catch (Exception ex) {
            ExceptionUtil.publishException('PV_ContentDocumentLinkTriggerHandler.handleBeforeInsert', ex.getLineNumber(), ex.getMessage(), ex.getStackTraceString());
        }
    }  
}
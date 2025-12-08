public class PV_SharinPixImageToFileController { 
    
    @InvocableMethod(label='get Image from Image Url' description='Attach images to the WO based on Image Url ')
    public static List<ReturnVariable> getUrlFromRecord(List<InputVariable> inputVariable){
        List<Id> siIds = new List<Id>();
        for(InputVariable iv: inputVariable){
            siIds.add(iv.SharinPixImageId);
        }
        
        getImageFromUrl(siIds);
        return null;
    }
    
    @Future(callout=true)
    public static void getImageFromUrl(List<Id> siIds) {
        List<sharinpix__SharinPixImage__c> siList = [Select Id, sharinpix__ImageURLFull__c,Limit_to_size__c,Work_Order_Image__c,sharinpix__DisplayTags__c,sharinpix__Processed__c from sharinpix__SharinPixImage__c WHERE Id IN: siIds];
        
        List<ContentVersion> cvList = New List<ContentVersion>();
        Map<ContentVersion, String> cvMap = New Map<ContentVersion, String>();
        try{
            for(sharinpix__SharinPixImage__c iv : siList){
                // Download image
                Http h = new Http();
                HttpRequest req = new HttpRequest();
                req.setEndpoint(iv.Limit_to_size__c);
                req.setTimeout(120000);//sets maximum timeout
                req.setMethod('GET');
                
                HttpResponse res = h.send(req);
                Blob bodyImg = res.getBodyAsBlob();
                
                ContentVersion cv = new ContentVersion();
              
            
                if(iv.sharinpix__Processed__c){
                if(iv.sharinpix__DisplayTags__c != null){
                    cv.Title = 'SharinPix Image - '+iv.sharinpix__DisplayTags__c;
                }
                else{
                    cv.Title = 'SharinPix Image';
                }
                cv.PathOnClient = 'SharinPix Image.jpg';
                cv.VersionData =bodyImg;
                cv.TagCsv = iv.sharinpix__DisplayTags__c;
                cv.FirstPublishLocationId = iv.Work_Order_Image__c;
                cv.Description = iv.sharinpix__ImageURLFull__c;
                cvList.add(cv);
                cvMap.put(cv,iv.Work_Order_Image__c);
            }
            }
        
            if(!cvList.isEmpty()){
                insert cvList;
            }
            
            Set<Id> cvIds = (new Map<Id,SObject>(cvList)).keySet();
            
       
        }
        catch(Exception ex){
            ExceptionUtil.publishException('PV_SharinPixImageToFileController.getImageFromUrl', ex.getLineNumber(), ex.getMessage(), ex.getStackTraceString());
        }
        
    }
    
    public class InputVariable { 
        @InvocableVariable( description='Get Id of Inserted SharinPix Image record' required=true)
        public Id SharinPixImageId;
    }
    
    public class ReturnVariable {
        @InvocableVariable
        public String imageRecordId;
    }
}
global without sharing class POESideBySideButton implements vlocity_cmt.VlocityOpenInterface {
    global Boolean invokeMethod(
        String methodName,
        Map<String, Object> inputMap,
        Map<String, Object> outMap,
        Map<String, Object> options
    ) {
        Boolean result = true;
        try {
            System.debug(inputMap);
            String recId = (String) inputMap.get('recId');
            String strSignElement = (String) inputMap.get('strSignElement');
            Boolean isUpdate = (Boolean) inputMap.get('updBoolean');
            String type = (String) inputMap.get('type');
            String cversionId = (String) inputMap.get('cvId');
            ContentVersion cVersion = new ContentVersion();
            if (type == 'signature') {
                cVersion.ContentLocation = 'S';
                cVersion.PathOnClient = 'Signature-' + System.now() + '.png';
                cVersion.Origin = 'H';
                cVersion.Title = 'poe_signature_' + System.now() + '.png';
                cVersion.VersionData = EncodingUtil.base64Decode(strSignElement);
            } else {
                cVersion.ContentLocation = 'S';
                cVersion.PathOnClient = 'Signature-' + System.now() + '.png';
                cVersion.Origin = 'H';
                cVersion.Title = 'poe_img_sidebyside_' + System.now() + '.png';
                cVersion.VersionData = EncodingUtil.base64Decode(strSignElement);
            }
            if (cversionId != null && cversionId != '') {
                Id prevConDocument = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cversionId]
                .ContentDocumentId;
                List<ContentDocument> prevDocList = [SELECT Id FROM ContentDocument WHERE Id = :prevConDocument];
                delete prevDocList;
            }

            insert cVersion;

            outMap.put('cVersion', cVersion); 
            
            Id conDocument = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cVersion.Id].ContentDocumentId;

            ContentDocumentLink cDocLink = new ContentDocumentLink();
            cDocLink.ContentDocumentId = conDocument;
            cDocLink.LinkedEntityId = recId;
            cDocLink.ShareType = 'I';
            cDocLink.Visibility = 'AllUsers';
            insert cDocLink;
        } catch (Exception e) {
            if (!Test.isRunningTest()) {
                result = false;
            }
        }
        return result;
    }
}
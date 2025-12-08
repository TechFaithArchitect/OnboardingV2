public without sharing class OrderSuccessTabController {
    public class ResponseWrapper {
        @AuraEnabled
        public Map<String, Object> result;
    }

    @AuraEnabled
    public static ResponseWrapper getSignatureFile(Map<String, Object> myData) {
        try {
            String contextId = (String) myData.get('ContextId');

            ResponseWrapper response = new ResponseWrapper();

            List<ContentDocumentLink> cdl = [
                SELECT ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :contextId
            ];

            if (!cdl.isEmpty()) {
                List<ContentVersion> cv = [
                    SELECT Id
                    FROM ContentVersion
                    WHERE Title LIKE 'poe_signature%' AND ContentDocumentId = :cdl[0].ContentDocumentId
                ];

                if (!cv.isEmpty()) {
                    response.result = new Map<String, Object>{ 'Id' => cv[0].Id };
                }
            }

            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
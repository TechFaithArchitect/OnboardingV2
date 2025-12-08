public without sharing class FilePreviewController {
    @AuraEnabled(cacheable=true)
    public static ResponseWrapper getRelatedFilesByRecordId(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String libraryName = (String) myData.get('libraryName');
            ContentWorkspace lib = [
                SELECT Id, Name, Description 
                FROM ContentWorkspace 
                WHERE Name = :libraryName 
                LIMIT 1
            ];

            // Get record file IDs
            List<ContentDocumentLink> files = [
                SELECT ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :lib.Id
            ];
            List<ID> fileIDs = new List<ID>();
            for (ContentDocumentLink docLink : files) {
                fileIDs.add(docLink.ContentDocumentId);
            }

            Map<Id, ContentVersion> versionsByDocId = new Map<Id, ContentVersion>();
            for (ContentVersion docLink : [
                SELECT ContentDocumentId, Title, Id
                FROM ContentVersion
                WHERE ContentDocumentId IN :fileIDs
            ]) {
                versionsByDocId.put(docLink.ContentDocumentId, docLink);
            }

            response.result = new Map<String, Object> {
                'Documents' => versionsByDocId.values()
            };
            return response;
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class ResponseWrapper {
        @AuraEnabled
        public Map<String, Object> result;
    }
}
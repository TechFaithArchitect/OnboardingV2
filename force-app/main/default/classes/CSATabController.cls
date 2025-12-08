public without sharing class CSATabController {
    @AuraEnabled
    public static ResponseWrapper saveFile(Map<String, Object> myData) {
        ResponseWrapper response = new ResponseWrapper();
        Map<String, Object> result = new Map<String, Object>();
        String title = (String) myData.get('title');
        String base64string = (String) myData.get('fileContents');
        String orderId = (String) myData.get('orderId');
        Blob fileContents = EncodingUtil.base64Decode(base64string);

        ContentVersion version = new ContentVersion(
            Title = title,
            VersionData = fileContents,
            pathOnClient = title,
            ContentLocation = 'S',
            Origin = 'H'
        );

        try {
            insert version;
            version = [SELECT Id, ContentDocumentId, VersionData FROM ContentVersion WHERE Id = :version.Id];

            ContentDocumentLink documentLink = new ContentDocumentLink(
                ContentDocumentId = version.ContentDocumentId,
                LinkedEntityId = orderId,
                ShareType = 'V',
                Visibility = 'AllUsers'
            );

            insert documentLink;

            response.result = new Map<String, Object>{
                'error' => false,
                'documentId' => version.ContentDocumentId,
                'contentVersionId' => version.Id,
                'versionDataBlob' => EncodingUtil.base64Encode(version.VersionData)
            };

            return response;
        } catch (Exception exc) {
            throw new AuraHandledException(exc.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper sendCSAFormEmail(Map<String, Object> myData) {
        ResponseWrapper response = new ResponseWrapper();
        Map<String, Object> result = new Map<String, Object>();
        String firstName = (String) myData.get('firstName');
        String lastName = (String) myData.get('lastName');
        String btn = (String) myData.get('btn');
        String documentId = (String) myData.get('documentId');
        String contentVersionId = (String) myData.get('contentVersionId');

        List<String> emailToAddresses = new List<String>{ Label.Frontier_CSA_Email };
        List<String> emailCcAddresses = new List<String>{ Label.Frontier_PV_CSA_Email };

        try {
            OrgWideEmailAddress orgWideEmail = [
                SELECT Id
                FROM OrgWideEmailAddress
                WHERE Address = 'no-reply@chuzo.com'
            ];
            Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
            emailMessage.setOrgWideEmailAddressId(orgWideEmail.Id);
            emailMessage.setToAddresses(emailToAddresses);
            emailMessage.setCcAddresses(emailCcAddresses);
            String subject = 'CSA ' + btn + ' ' + firstName + ' ' + lastName;
            emailMessage.setSubject(subject);
            emailMessage.setHtmlBody('');
            emailMessage.setSaveAsActivity(false);
            emailMessage.setEntityAttachments(new List<String>{ contentVersionId });

            Messaging.SendEmailResult emailResult = Messaging.sendEmail(
                new List<Messaging.SingleEmailMessage>{ emailMessage }
            )[0];

            System.debug('emailResult: ' + emailResult);
            response.result = new Map<String, Object>{ 'error' => !emailResult.isSuccess() };
            if (!emailResult.isSuccess()) {
                response.result.put('errorMessage', emailResult.getErrors()[0].getMessage());
            }

            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class ResponseWrapper {
        @AuraEnabled
        public Map<String, Object> result;
    }
}
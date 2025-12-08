public class EmailCommSendRequestDTO {
    @AuraEnabled public Id contactId;
    @AuraEnabled public Id onboardingId;
    @AuraEnabled public Id accountId;
    @AuraEnabled public Id communicationTemplateId;

    // Email content
    @AuraEnabled public String emailTemplateId;
    @AuraEnabled public String subject;
    @AuraEnabled public String htmlBody;
    @AuraEnabled public String textBody;

    // Recipients
    @AuraEnabled public String toAddress;
    @AuraEnabled public List<String> toAddressList;
    @AuraEnabled public List<String> ccAddressList;
    @AuraEnabled public List<String> bccAddressList;

    // Sender
    @AuraEnabled public String senderType;
    @AuraEnabled public Id orgWideEmailAddressId;

    // Template merge context
    @AuraEnabled public Id recipientId;
    @AuraEnabled public Id relatedRecordId;

    // Attachments
    @AuraEnabled public List<Id> attachmentIds;

    // Logging
    @AuraEnabled public Boolean logSync = false;
}
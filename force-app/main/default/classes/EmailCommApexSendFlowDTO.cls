public class EmailCommApexSendFlowDTO {
    @AuraEnabled public Id contactId;
    @AuraEnabled public Id onboardingId;
    @AuraEnabled public Id accountId;
    @AuraEnabled public Id communicationTemplateId;

    @AuraEnabled public String emailTemplateId;
    @AuraEnabled public String subject;
    @AuraEnabled public String htmlBody;
    @AuraEnabled public String textBody;

    @AuraEnabled public String toAddress;
    @AuraEnabled public List<String> toAddressList;
    @AuraEnabled public List<String> ccAddressList;
    @AuraEnabled public List<String> bccAddressList;

    @AuraEnabled public String senderType;
    @AuraEnabled public Id orgWideEmailAddressId;

    @AuraEnabled public Id recipientId;
    @AuraEnabled public Id relatedRecordId;

    @AuraEnabled public List<Id> attachmentIds;

    @AuraEnabled public Boolean logSync;
}
public with sharing class EmailCommLogHelper {
    public static Email_Communication_Log__c buildLogFromRequest(EmailCommSendRequestDTO req) {
        return new Email_Communication_Log__c(
            Contact__c = req.contactId,
            Onboarding__c = req.onboardingId,
            Account__c = req.accountId,
            Communication_Template__c = req.communicationTemplateId,
            To_Address__c = req.toAddress,
            Subject__c = req.subject,
            HTML_Body__c = req.htmlBody,
            Text_Body__c = req.textBody,
            Sent_At__c = DateTime.now(),
            Sent_By__c = UserInfo.getUserId(),
            Sent_Via__c = 'Flow',
            Status__c = 'Sent'
        );
    }
}
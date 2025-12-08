@isTest
public class TestEmailCommLogFactory {

    public static Email_Communication_Log__c create(
        EmailCommSendRequestDTO emailCommSendRequestDTO,
        Boolean doInsert,
        Integer daysAgo
    ) {
        Email_Communication_Log__c emailCommLog = new Email_Communication_Log__c(
            Contact__c = emailCommSendRequestDTO.contactId,
            Onboarding__c = emailCommSendRequestDTO.onboardingId,
            Account__c = emailCommSendRequestDTO.accountId,
            Communication_Template__c = emailCommSendRequestDTO.communicationTemplateId,
            To_Address__c = emailCommSendRequestDTO.toAddress,
            Subject__c = emailCommSendRequestDTO.subject,
            HTML_Body__c = emailCommSendRequestDTO.htmlBody,
            Text_Body__c = emailCommSendRequestDTO.textBody,
            Sent_At__c = DateTime.now().addDays(-daysAgo),
            Sent_By__c = UserInfo.getUserId(),
            Sent_Via__c = 'Flow',
            Status__c = 'Sent'
        );

        if (doInsert) {
            insert emailCommLog;
            if (daysAgo > 0) {
                Test.setCreatedDate(emailCommLog.Id, DateTime.now().addDays(-daysAgo));
            }
        }

        return emailCommLog;
    }
}

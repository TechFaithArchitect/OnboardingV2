/**
 * Service for sending email communications
 * Uses strategy pattern to support different sender types without modification (OCP compliant)
 */
public with sharing class EmailCommSenderService {
    @TestVisible private static EmailCommSendResultDTO testResultOverride;

    public static EmailCommSendResultDTO sendEmail(EmailCommSendRequestDTO req) {
        if (Test.isRunningTest() && testResultOverride != null) {
            return testResultOverride;
        }

        try {
            // === Validate and Get Sender Strategy ===
            String senderType = String.isBlank(req.senderType) ? 'CurrentUser' : req.senderType;
            
            EmailSenderStrategy senderStrategy;
            try {
                senderStrategy = EmailSenderStrategyFactory.getStrategy(senderType);
            } catch (IllegalArgumentException e) {
                return new EmailCommSendResultDTO('Failed', null, e.getMessage());
            }
            
            // Validate request for this sender type
            String validationError = senderStrategy.validate(req);
            if (validationError != null) {
                return new EmailCommSendResultDTO('Failed', null, validationError);
            }

            // === Build Email Message ===
            Messaging.SingleEmailMessage mail = EmailMessageBuilder.build(req);

            // === Apply Sender Strategy ===
            senderStrategy.applySender(mail, req);

            // === Attachments ===
            if (req.attachmentIds != null && !req.attachmentIds.isEmpty()) {
                mail.setFileAttachments(EmailAttachmentService.getAttachments(req.attachmentIds));
            }

            // === Send Email ===
            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

            if (!results[0].isSuccess()) {
                return new EmailCommSendResultDTO(
                    'Failed',
                    null,
                    results[0].getErrors()[0].getMessage()
                );
            }

            // === Lookup EmailMessage Id (if available) ===
            Id emailMessageId;
            if (req.recipientId != null) {
                emailMessageId = EmailMessageRepository.findMatchingEmailMessage(
                    req.toAddress, 
                    req.subject, 
                    UserInfo.getUserId()
                );
            }

            return new EmailCommSendResultDTO('Success', emailMessageId, null);

        } catch (Exception e) {
            return new EmailCommSendResultDTO('Exception', null, e.getMessage());
        }
    }
}

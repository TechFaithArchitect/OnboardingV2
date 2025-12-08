public class EmailMessageBuilder {
    public static Messaging.SingleEmailMessage build(EmailCommSendRequestDTO req) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setSaveAsActivity(true);

        if (String.isNotBlank(req.emailTemplateId)) {
            mail.setTemplateId(req.emailTemplateId);
            mail.setTargetObjectId(req.recipientId);
            if (req.relatedRecordId != null) mail.setWhatId(req.relatedRecordId);
            mail.setUseSignature(false);
        } else {
            mail.setToAddresses(
                String.isNotBlank(req.toAddress)
                    ? new List<String>{ req.toAddress }
                    : req.toAddressList
            );
            mail.setSubject(req.subject);
            mail.setHtmlBody(req.htmlBody);
            mail.setPlainTextBody(req.textBody);
        }

        if (req.recipientId != null) mail.setTargetObjectId(req.recipientId);
        if (req.relatedRecordId != null) mail.setWhatId(req.relatedRecordId);

        if (req.ccAddressList != null) mail.setCcAddresses(req.ccAddressList);
        if (req.bccAddressList != null) mail.setBccAddresses(req.bccAddressList);

        return mail;
    }
}

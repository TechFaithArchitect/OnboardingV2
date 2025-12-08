/**
 * Email sender strategy for OrgWide sender type
 * Configures the email to use an org-wide email address
 */
public with sharing class OrgWideSenderStrategy implements EmailSenderStrategy {
    
    public void applySender(Messaging.SingleEmailMessage mail, EmailCommSendRequestDTO req) {
        mail.setOrgWideEmailAddressId(req.orgWideEmailAddressId);
    }
    
    public String validate(EmailCommSendRequestDTO req) {
        if (req.orgWideEmailAddressId == null) {
            return 'Org-Wide Email Address ID is required when senderType is "OrgWide".';
        }
        return null;
    }
}


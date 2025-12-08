/**
 * Email sender strategy for CurrentUser sender type
 * No special configuration needed - uses current user as sender
 */
public with sharing class CurrentUserSenderStrategy implements EmailSenderStrategy {
    
    public void applySender(Messaging.SingleEmailMessage mail, EmailCommSendRequestDTO req) {
        // CurrentUser is the default - no special configuration needed
        // The email will be sent from the current user automatically
    }
    
    public String validate(EmailCommSendRequestDTO req) {
        // CurrentUser sender type has no special validation requirements
        return null;
    }
}
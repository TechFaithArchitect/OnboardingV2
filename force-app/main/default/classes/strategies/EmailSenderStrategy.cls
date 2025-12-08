/**
 * Strategy interface for email sender types
 * Follows Open/Closed Principle - new sender types can be added without modifying existing code
 */
public interface EmailSenderStrategy {
    /**
     * Applies sender-specific configuration to an email message
     * @param mail The email message to configure
     * @param req The email request containing sender information
     */
    void applySender(Messaging.SingleEmailMessage mail, EmailCommSendRequestDTO req);
    
    /**
     * Validates that the request has all required fields for this sender type
     * @param req The email request to validate
     * @return Error message if validation fails, null if valid
     */
    String validate(EmailCommSendRequestDTO req);
}


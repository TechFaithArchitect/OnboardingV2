public with sharing class EmailMessageRepository {
    
    /**
     * Finds the most recent EmailMessage matching the given criteria.
     * Used to lookup the EmailMessage ID after sending an email.
     *
     * @param toAddress Partial or full email address to match
     * @param subject Email subject to match
     * @param createdById User ID who created the email (defaults to current user)
     * @return EmailMessage ID if found, null otherwise
     */
    public static Id findMatchingEmailMessage(String toAddress, String subject, Id createdById) {
        if (String.isBlank(toAddress) || String.isBlank(subject)) {
            return null;
        }

        if (createdById == null) {
            createdById = UserInfo.getUserId();
        }

        List<EmailMessage> matches = [
            SELECT Id 
            FROM EmailMessage 
            WHERE CreatedById = :createdById
            AND ToAddress LIKE :('%' + toAddress + '%')
            AND Subject = :subject
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        
        return matches.isEmpty() ? null : matches[0].Id;
    }
}


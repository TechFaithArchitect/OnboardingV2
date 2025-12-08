/**
 * Service for logging email communications
 * Centralizes logging logic to eliminate duplication
 */
public with sharing class EmailCommLoggerService {
    
    /**
     * Logs an email communication immediately (synchronously)
     * @param emailCommSendRequestDTO The email request to log
     */
    public static void logImmediately(EmailCommSendRequestDTO emailCommSendRequestDTO) {
        log(emailCommSendRequestDTO);
    }
    
    /**
     * Core logging method used by both immediate and async logging
     * Checks for duplicates, builds log record, and inserts it
     * @param emailCommSendRequestDTO The email request to log
     */
    public static void log(EmailCommSendRequestDTO emailCommSendRequestDTO) {
        if (emailCommSendRequestDTO == null) {
            return;
        }
        
        // Check for duplicates
        if (EmailCommDedupeUtil.isDuplicate(emailCommSendRequestDTO)) {
            return;
        }

        // Build log record from request
        Email_Communication_Log__c emailCommLog = EmailCommLogHelper.buildLogFromRequest(emailCommSendRequestDTO);
        
        // Insert log via repository
        EmailCommLogRepository.insertLog(emailCommLog);
    }
}

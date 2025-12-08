/**
 * Queueable class for asynchronous email communication logging
 * Uses shared logging logic from EmailCommLoggerService
 */
public with sharing class EmailCommLoggerQueueable implements Queueable {
    private EmailCommSendRequestDTO emailCommSendRequestDTO;

    public EmailCommLoggerQueueable(EmailCommSendRequestDTO emailCommSendRequestDTO) {
        this.emailCommSendRequestDTO = emailCommSendRequestDTO;
    }

    public void execute(QueueableContext context) {
        // Delegate to shared logging service
        EmailCommLoggerService.log(emailCommSendRequestDTO);
    }
}

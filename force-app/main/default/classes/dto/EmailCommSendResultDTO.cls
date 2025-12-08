public class EmailCommSendResultDTO {
    @InvocableVariable public Id emailMessageId;
    @InvocableVariable public String status;
    @InvocableVariable public String errorMessage;

    public EmailCommSendResultDTO() {}

    public EmailCommSendResultDTO(String status, Id emailMessageId, String errorMessage) {
        this.status = status;
        this.emailMessageId = emailMessageId;
        this.errorMessage = errorMessage;
    }
}
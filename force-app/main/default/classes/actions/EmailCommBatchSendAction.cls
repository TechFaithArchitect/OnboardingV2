public with sharing class EmailCommBatchSendAction {
    @InvocableMethod
    public static List<EmailCommSendResultDTO> execute(List<EmailCommSendWrapper> wrappers) {
        List<EmailCommSendResultDTO> results = new List<EmailCommSendResultDTO>();
        for (EmailCommSendWrapper wrapper : wrappers) {
            for (EmailCommSendRequestDTO dto : wrapper.payloads) {
                results.add(EmailSendAndLogOrchestrator.orchestrateSendAndLog(dto));
            }
        }
        return results;
    }
}
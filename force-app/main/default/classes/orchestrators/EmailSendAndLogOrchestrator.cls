public class EmailSendAndLogOrchestrator {

    public static EmailCommSendResultDTO orchestrateSendAndLog(EmailCommSendRequestDTO req) {
        EmailCommSendResultDTO result = EmailCommSenderService.sendEmail(req);
        log(req);
        return result;
    }

    public static List<EmailCommSendResultDTO> orchestrateBulk(List<EmailCommSendRequestDTO> requests) {
        List<EmailCommSendResultDTO> results = new List<EmailCommSendResultDTO>();
        for (EmailCommSendRequestDTO req : requests) {
            results.add(orchestrateSendAndLog(req));
        }
        return results;
    }

    private static void log(EmailCommSendRequestDTO req) {
        if (req.logSync) {
            EmailCommLoggerService.logImmediately(req);
        } else {
            System.enqueueJob(new EmailCommLoggerQueueable(req));
        }
    }
}

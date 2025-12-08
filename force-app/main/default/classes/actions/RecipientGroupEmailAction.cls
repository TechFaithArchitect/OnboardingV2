public class RecipientGroupEmailAction {
    @InvocableMethod(label='Get Emails from Vendor Program Recipient Group')
    public static List<RecipientGroupEmailResultDTO> fetchEmails(List<RecipientGroupEmailRequestDTO> requests) {
        List<RecipientGroupEmailResultDTO> results = new List<RecipientGroupEmailResultDTO>();

        for (RecipientGroupEmailRequestDTO req : requests) {
            List<String> emails = RecipientGroupEmailOrchestrator.getEmails(req.vendorProgramId);
            results.add(new RecipientGroupEmailResultDTO(emails));
        }

        return results;
    }
}

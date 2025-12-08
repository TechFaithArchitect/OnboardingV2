public class RecipientGroupEmailOrchestrator {
    public static List<String> getEmails(Id vendorProgramId) {
        return RecipientGroupEmailService.getEmailsForVendorProgram(vendorProgramId);
    }
}
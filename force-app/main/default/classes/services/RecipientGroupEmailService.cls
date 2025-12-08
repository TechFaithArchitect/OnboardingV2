public class RecipientGroupEmailService {
    public static List<String> getEmailsForVendorProgram(Id vendorProgramId) {
        return RecipientGroupUtil.getEmailsFromVendorProgram(vendorProgramId);
    }
}

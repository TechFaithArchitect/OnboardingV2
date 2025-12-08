public class ContactOwnerRulesHandler {
    public static void applyAuthorizationRules(List<Contact> contacts) {
        for (Contact con : contacts) {
            if (con.Principal_Owner__c == true) {
                con.Owner__c = true;
                con.Add_to_Agreements__c = true;
            } else if (con.Owner__c == true) {
                con.Add_to_Agreements__c = true;
            }
            // Else: Do nothing, Authorized_Signer__c can be true or false... change add_to_Agreements__c only to Authorized_Signer__c in next environment
        }
    }
}
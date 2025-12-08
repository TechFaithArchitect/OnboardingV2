public class ContactPrincipalOwnerTriggerHandler {
    public static void checkPrincipalOwnerLimit(List<Contact> newContacts, Map<Id, Contact> oldMap) {
        Set<Id> accountIds = new Set<Id>();

        // Collect Account IDs where the checkbox is being set to TRUE
        for (Contact con : newContacts) {
            if (con.Principal_Owner__c == true) {
                if (con.AccountId != null) {
                    // Check if value was previously false or it's a new record
                    if (oldMap == null || oldMap.get(con.Id)?.Principal_Owner__c != true) {
                        accountIds.add(con.AccountId);
                    }
                }
            }
        }

        if (accountIds.isEmpty()) return;

        // Query existing Principal Owners in those Accounts
        Map<Id, List<Contact>> principalOwnersByAccount = new Map<Id, List<Contact>>();
        for (Contact c : [
            SELECT Id, AccountId
            FROM Contact
            WHERE AccountId IN :accountIds
              AND Principal_Owner__c = TRUE
        ]) {
            if (!principalOwnersByAccount.containsKey(c.AccountId)) {
                principalOwnersByAccount.put(c.AccountId, new List<Contact>());
            }
            principalOwnersByAccount.get(c.AccountId).add(c);
        }

        for (Contact con : newContacts) {
            if (con.Principal_Owner__c == true && accountIds.contains(con.AccountId)) {
                List<Contact> existing = principalOwnersByAccount.get(con.AccountId);
                Integer count = existing == null ? 0 : existing.size();

                // Allow if it's the same record updating itself
                Boolean isAlreadyPrincipal = oldMap != null && oldMap.containsKey(con.Id) &&
                                             oldMap.get(con.Id).Principal_Owner__c == true;

                if (count > 0 && !isAlreadyPrincipal) {
                    con.addError(Label.Principal_Owner_Conflict);
                }
            }
        }
    }
}
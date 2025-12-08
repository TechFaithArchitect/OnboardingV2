public with sharing class AccountTriggerHandler {
    public static void beforeInsert(List<Account> newList) {
        LeadAssignmentService.assignOwnersForAccounts(newList);
    }

    public static void beforeUpdate(List<Account> newList, Map<Id, Account> oldMap) {
        if (newList == null || newList.isEmpty() || oldMap == null) {
            return;
        }

        List<Account> toProcess = new List<Account>();
        for (Account acc : newList) {
            Account oldRecord = oldMap.get(acc.Id);
            if (oldRecord == null) {
                continue;
            }
            if (postalChanged(acc.BillingPostalCode, oldRecord.BillingPostalCode)) {
                toProcess.add(acc);
            }
        }

        if (!toProcess.isEmpty()) {
            LeadAssignmentService.assignOwnersForAccounts(toProcess);
        }
    }

    private static Boolean postalChanged(String currentPostal, String oldPostal) {
        return (currentPostal == null && oldPostal != null)
            || (currentPostal != null && oldPostal == null)
            || (currentPostal != oldPostal);
    }
}

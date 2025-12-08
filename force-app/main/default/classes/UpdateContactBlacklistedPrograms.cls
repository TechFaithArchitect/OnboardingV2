public with sharing class UpdateContactBlacklistedPrograms {
    @InvocableMethod(
        label='Update Contacts Blacklisted Programs'
        description='Updates Blacklisted Programs to match the Account value.'
    )
    public static void updateContacts(List<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return;
        }

        Map<Id, List<String>> accountProgramsMap = new Map<Id, List<String>>();

        for (Account acc : [SELECT Id, Blacklisted_Programs__c FROM Account WHERE Id IN :accountIds]) {
            if (String.isNotBlank(acc.Blacklisted_Programs__c)) {
                accountProgramsMap.put(acc.Id, acc.Blacklisted_Programs__c.split(';'));
            }
        }
        if (accountProgramsMap.isEmpty()) {
            return;
        }

        List<Contact> contactsToUpdate = new List<Contact>();

        for (Contact c : [
            SELECT
                Id,
                AccountId,
                POE_Blacklisted_Programs__c,
                D2D_Programs__c,
                POE_Event_Programs__c,
                POE_Programs_Available__c,
                POE_Retail_Programs__c
            FROM Contact
            WHERE AccountId IN :accountIds
        ]) {
            if (accountProgramsMap.containsKey(c.AccountId)) {
                c.POE_Blacklisted_Programs__c = addValuesToMultiPickList(
                    accountProgramsMap.get(c.AccountId),
                    String.isBlank(c.POE_Blacklisted_Programs__c) ? '' : c.POE_Blacklisted_Programs__c
                );
                if (c.POE_Blacklisted_Programs__c.contains('Charter/Spectrum')) {
                    c.POE_Blacklisted_Programs__c = c.POE_Blacklisted_Programs__c.replace('Charter/Spectrum', 'Spectrum API');
                }
                c.D2D_Programs__c = removeValuesFromMultiPickList(
                    accountProgramsMap.get(c.AccountId),
                    String.isBlank(c.D2D_Programs__c) ? '' : c.D2D_Programs__c
                );
                c.POE_Event_Programs__c = removeValuesFromMultiPickList(
                    accountProgramsMap.get(c.AccountId),
                    String.isBlank(c.POE_Event_Programs__c) ? '' : c.POE_Event_Programs__c
                );
                c.POE_Programs_Available__c = removeValuesFromMultiPickList(
                    accountProgramsMap.get(c.AccountId),
                    String.isBlank(c.POE_Programs_Available__c) ? '' : c.POE_Programs_Available__c
                );
                c.POE_Retail_Programs__c = removeValuesFromMultiPickList(
                    accountProgramsMap.get(c.AccountId),
                    String.isBlank(c.POE_Retail_Programs__c) ? '' : c.POE_Retail_Programs__c
                );
                contactsToUpdate.add(c);
            }
        }

        if (!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
        }
    }

    public static String addValuesToMultiPickList(List<String> addedValues, String currentValues) {
        if (addedValues == null || addedValues.isEmpty()) {
            return currentValues;
        }

        Set<String> mergedSet = new Set<String>(currentValues.split(';'));
        mergedSet.addAll(addedValues);

        return String.join(new List<String>(mergedSet), ';');
    }

    public static String removeValuesFromMultiPickList(List<String> removedValues, String currentValues) {
        if (removedValues == null || removedValues.isEmpty()) {
            return currentValues;
        }

        if (removedValues.contains('Charter/Spectrum') && currentValues.contains('Spectrum API')) {
            removedValues.add('Spectrum API');
        }

        Set<String> currentSet = new Set<String>(currentValues.split(';'));
        currentSet.removeAll(removedValues);

        return String.join(new List<String>(currentSet), ';');
    }
}
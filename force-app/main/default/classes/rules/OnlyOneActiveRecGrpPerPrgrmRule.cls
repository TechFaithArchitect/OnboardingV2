public class OnlyOneActiveRecGrpPerPrgrmRule implements OnboardingAppValidationRule {
    public void validate(List<SObject> newRecords, Map<Id, SObject> oldMap) {
        List<Vendor_Program_Recipient_Group__c> newList = (List<Vendor_Program_Recipient_Group__c>) newRecords;

        Set<Id> programIds = new Set<Id>();
        Set<Id> newIds = new Set<Id>();

        for (Vendor_Program_Recipient_Group__c rec : newList) {
            if (rec.Id != null) {
                newIds.add(rec.Id);
            }
            if (rec.Vendor_Program__c != null) {
                programIds.add(rec.Vendor_Program__c);
            }
        }

        Map<Id, Integer> activeCountByProgram = new Map<Id, Integer>();
        if (!programIds.isEmpty()) {
            List<Vendor_Program_Recipient_Group__c> existingActive;
            if (newIds.isEmpty()) {
                existingActive = [
                    SELECT Id, Vendor_Program__c
                    FROM Vendor_Program_Recipient_Group__c
                    WHERE (Is_Active__c = true OR Status__c = 'Active')
                    AND Vendor_Program__c IN :programIds
                ];
            } else {
                existingActive = [
                    SELECT Id, Vendor_Program__c
                    FROM Vendor_Program_Recipient_Group__c
                    WHERE (Is_Active__c = true OR Status__c = 'Active')
                    AND Vendor_Program__c IN :programIds
                    AND Id NOT IN :newIds
                ];
            }

            for (Vendor_Program_Recipient_Group__c rec : existingActive) {
                Integer count = activeCountByProgram.containsKey(rec.Vendor_Program__c)
                    ? activeCountByProgram.get(rec.Vendor_Program__c)
                    : 0;
                activeCountByProgram.put(rec.Vendor_Program__c, count + 1);
            }
        }

        Map<Id, Integer> seenActiveByProgram = new Map<Id, Integer>();
        for (Vendor_Program_Recipient_Group__c rec : newList) {
            if (rec.Vendor_Program__c == null) {
                continue;
            }

            Boolean willBeActive = rec.Is_Active__c == true || rec.Status__c == 'Active';
            if (!willBeActive) {
                continue;
            }

            Id programId = rec.Vendor_Program__c;
            Integer existingCount = activeCountByProgram.containsKey(programId)
                ? activeCountByProgram.get(programId)
                : 0;
            Integer seenCount = seenActiveByProgram.containsKey(programId)
                ? seenActiveByProgram.get(programId)
                : 0;

            if (existingCount + seenCount >= 1) {
                rec.addError('Only one active Recipient Group is allowed per Vendor Program.');
            }

            seenActiveByProgram.put(programId, seenCount + 1);
        }
    }
}
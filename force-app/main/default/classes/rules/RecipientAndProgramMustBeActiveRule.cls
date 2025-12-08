public class RecipientAndProgramMustBeActiveRule implements OnboardingAppValidationRule {
    public void validate(List<SObject> newRecords, Map<Id, SObject> oldMap) {
        List<Vendor_Program_Recipient_Group__c> newList = (List<Vendor_Program_Recipient_Group__c>) newRecords;

        Set<Id> groupIds = new Set<Id>();
        Set<Id> programIds = new Set<Id>();

        for (Vendor_Program_Recipient_Group__c rec : newList) {
            if (rec.Is_Active__c) {
                if (rec.Recipient_Group__c != null) groupIds.add(rec.Recipient_Group__c);
                if (rec.Vendor_Program__c != null) programIds.add(rec.Vendor_Program__c);
            }
        }

        Map<Id, Recipient_Group__c> recipientGroups = new Map<Id, Recipient_Group__c>(
            [SELECT Id, Is_Active__c FROM Recipient_Group__c WHERE Id IN :groupIds]
        );
        Map<Id, Vendor_Customization__c> programs = new Map<Id, Vendor_Customization__c>(
            [SELECT Id, Active__c FROM Vendor_Customization__c WHERE Id IN :programIds]
        );

        for (Vendor_Program_Recipient_Group__c rec : newList) {
            if (!rec.Is_Active__c) continue;

            if (rec.Recipient_Group__c != null) {
                Recipient_Group__c recipientGroup = recipientGroups.get(rec.Recipient_Group__c);
                if (recipientGroup == null || !recipientGroup.Is_Active__c) {
                    rec.addError('Recipient Group must be active before this record can be activated.');
                }
            }
            if (rec.Vendor_Program__c != null) {
                Vendor_Customization__c program = programs.get(rec.Vendor_Program__c);
                if (program == null || !program.Active__c) {
                    rec.addError('Vendor Program must be active before this record can be activated.');
                }
            }
        }
    }
}
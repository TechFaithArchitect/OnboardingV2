global class OnboardingContractTypeUpdater implements Database.Batchable<SObject> {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, RecordType.Name, Retailer_Type__c, Contract_Type__c
            FROM Contract
            WHERE Contract_Type__c = NULL
              AND RecordType.Name IN ('NDA', 'New Dealer Application (DOM)')
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Contract> scope) {
        for (Contract c : scope) {
            if (c.RecordType.Name == 'NDA') {
                c.Contract_Type__c = 'NDA';
            } else if (c.RecordType.Name == 'New Dealer Application (DOM)') {
                c.Contract_Type__c = (c.Retailer_Type__c == 'New customer with Chuzo App') ?
                    'Program Base Application - with Chuzo' :
                    'Program Base Application - without Chuzo';
            }
            c.Temp_Only_Run_Via_New_Flows__c = true;
        }
        update scope;
    }

    global void finish(Database.BatchableContext bc) {}
}
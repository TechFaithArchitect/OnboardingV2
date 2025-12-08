public without sharing class POE_SaveACIStatistics {
    @AuraEnabled(cacheable=false)
    public static void initialSave(String recordId, Decimal latitude, Decimal longitude) {
        List<POE_ACI_Statistic__c> aciList = new List<POE_ACI_Statistic__c>();
        POE_ACI_Statistic__c newACI = new POE_ACI_Statistic__c();
        try {
            aciList = [
                SELECT Id, Point_of_Disposition__latitude__s, Point_of_Disposition__longitude__s
                FROM POE_ACI_Statistic__c
                WHERE Opportunity__c = :recordId
            ];

            if (aciList.isEmpty()) {
                newACI.Statistics_Date__c = System.now();
                newACI.Opportunity__c = recordId;
                newACI.Point_of_Disposition__latitude__s = latitude;
                newACI.Point_of_Disposition__longitude__s = longitude;
                insert newACI;
            } else {
                newACI = aciList[0];
                if (
                    aciList[0].Point_of_Disposition__longitude__s == null || aciList[0].Point_of_Disposition__latitude__s == null
                ) {
                    newACI.Point_of_Disposition__latitude__s = latitude;
                    newACI.Point_of_Disposition__longitude__s = longitude;
                    update newACI;
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static List<Order> getData(String recordId) {
        List<Order> orders = new List<Order>();
        try {
            orders = [
                SELECT Id
                FROM Order
                WHERE OpportunityId = :recordId AND (Status = 'Pending Installation' OR Status = 'Activated')
            ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return orders;
    }
}
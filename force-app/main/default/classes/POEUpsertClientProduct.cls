global without sharing class POEUpsertClientProduct implements vlocity_cmt.VlocityOpenInterface {
    global Boolean invokeMethod(
        String methodName,
        Map<String, Object> inputMap,
        Map<String, Object> outMap,
        Map<String, Object> options
    ) {
        Boolean result = true;
        try {
            String productName = (String) inputMap.get('Name');
            List<POE_ClientProduct__c> prods = [SELECT Id, Name FROM POE_ClientProduct__c WHERE Name = :productName];
            if (prods.isEmpty()) {
                POE_ClientProduct__c prod = new POE_ClientProduct__c();
                prod.Name = productName;
                prod.Unit_Price__c = (Decimal) inputMap.get('UnitPrice');
                prod.Code__c = (String) inputMap.get('Code');
                prod.Family__c = (String) inputMap.get('Family');
                prod.Description__c = (String) inputMap.get('Description');
                insert prod;
                outMap.put('ProductName', prod.Name);
            } else {
                List<POE_ClientProduct__c> updateOp = new List<POE_ClientProduct__c>();
                for (POE_ClientProduct__c pr : prods) {
                    pr.Unit_Price__c = (Decimal) inputMap.get('UnitPrice');
                    pr.Description__c = (String) inputMap.get('Description');
                    updateOp.add(pr);
                    outMap.put('ProductName', pr.Name);
                }
                update updateOp;
            }
        } catch (Exception e) {
            result = false;
        }
        return result;
    }
}
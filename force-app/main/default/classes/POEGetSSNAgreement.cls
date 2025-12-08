global without sharing class POEGetSSNAgreement implements vlocity_cmt.VlocityOpenInterface {
    global Boolean invokeMethod(
        String methodName,
        Map<String, Object> inputMap,
        Map<String, Object> outMap,
        Map<String, Object> options
    ) {
        Boolean result = true;

        try {
            if ('getOpportunity'.equalsIgnoreCase(methodName)) {
                getOpportunity(inputMap, outMap, options);
            } else {
                result = false;
            }
        } catch (Exception e) {
            result = false;
        }
        return result;
    }

    public void getOpportunity(Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        String recordId = (String) options.get('recordId');
        Opportunity opp = [SELECT POE_SSN_Agreement__c, POE_Program__c FROM Opportunity WHERE Id = :recordId LIMIT 1];
        outMap.put('Opportunity', opp);
    }
}
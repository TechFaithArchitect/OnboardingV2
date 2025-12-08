global without sharing class POEIPStatisticValidator implements vlocity_cmt.VlocityOpenInterface {
    
    global Boolean invokeMethod(
        String methodName,
        Map<String, Object> inputMap,
        Map<String, Object> outMap,
        Map<String, Object> options
    ) {
        Boolean result = true;

        try {
            if ('validateStatistic'.equalsIgnoreCase(methodName)) {
                validateStatistic(inputMap, outMap, options);
            } else {
                result = false;
            }
        } catch (Exception e) {
            result = false;
        }
        return result;
    }

    public void validateStatistic(
        Map<String, Object> inputMap,
        Map<String, Object> outMap,
        Map<String, Object> options
    ) {
        List<Fraud_Validation_Statistics__c> toUpdate = new List<Fraud_Validation_Statistics__c>();
        String contactId = (String) inputMap.get('ContactId');
        String state = (String) inputMap.get('State');
        Boolean toFlag = false;
        List<Fraud_Validation_Statistics__c> validations = new List<Fraud_Validation_Statistics__c>();
        Date d = System.today();
        Datetime dt = Datetime.newInstance(d, Time.newInstance(0, 0, 0, 0));
        String dayOfWeek = dt.format('EEEE');

        if (dayOfWeek == 'Monday') {
            validations = [
                SELECT Id, State__c, IP_Fraud_Flag__c
                FROM Fraud_Validation_Statistics__c
                WHERE CreatedDate >= LAST_N_DAYS:3 AND Contact__c = :contactId
            ];
        } else {
            validations = [
                SELECT Id, State__c, IP_Fraud_Flag__c
                FROM Fraud_Validation_Statistics__c
                WHERE CreatedDate >= LAST_N_DAYS:1 AND Contact__c = :contactId
            ];
        }
        for (Fraud_Validation_Statistics__c val : validations) {
            if (val.State__c != state) {
                toFlag = true;
            }
        }
        if (toFlag == true) {
            for (Fraud_Validation_Statistics__c val : validations) {
                val.IP_Fraud_Flag__c = true;
                toUpdate.add(val);
            }
            update toUpdate;
        }
    }
}
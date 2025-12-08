global without sharing class POEinsertPCICreditCheck implements vlocity_cmt.VlocityOpenInterface {
    global Boolean invokeMethod(
        String methodName,
        Map<String, Object> inputMap,
        Map<String, Object> outMap,
        Map<String, Object> options
    ) {
        Boolean result = true;

        try {
            if (methodName.equals('updateCreditCheckSSN')) {
                Opportunity oppToUpdate = new Opportunity(
                    Id = String.valueOf(options.get('oppId')),
                    POE_Ssn__c = String.valueOf(options.get('ssn')),
                    POE_Birthdate__c = Date.valueOf(String.valueOf(options.get('birthdate')))
                );

                update oppToUpdate;
            } else if (methodName.equals('updateCreditCheckDL')) {
                Opportunity oppToUpdate = new Opportunity(
                    Id = String.valueOf(options.get('oppId')),
                    POE_Driver_s_License_Number__c = String.valueOf(options.get('dlNumber')),
                    POE_DL_State__c = String.valueOf(options.get('dlState')),
                    POE_DL_Expiration_Date__c = Date.valueOf(String.valueOf(options.get('dlExpirationDate'))),
                    POE_Birthdate__c = Date.valueOf(String.valueOf(options.get('birthdate')))
                );

                update oppToUpdate;
            }
        } catch (Exception e) {
            result = false;
        }

        return result;
    }
}
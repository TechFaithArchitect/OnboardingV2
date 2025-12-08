global without sharing class POEinsertPCICheckout implements vlocity_cmt.VlocityOpenInterface {
    global Boolean invokeMethod(
        String methodName,
        Map<String, Object> inputMap,
        Map<String, Object> outMap,
        Map<String, Object> options
    ) {
        Boolean result = true;

        try {
            if (methodName.equals('updateCheckout')) {
                Opportunity oppToUpdate = new Opportunity(
                    Id = String.valueOf(options.get('oppId')),
                    POE_CC_FirstName__c = String.valueOf(options.get('firstName')),
                    POE_CC_LastName__c = String.valueOf(options.get('lastName')),
                    POE_CC_CreditCardType__c = String.valueOf(options.get('type')),
                    POE_CC_CreditCardNumber__c = String.valueOf(options.get('number')),
                    POE_CC_ExpirationMonth__c = String.valueOf(options.get('expirationMonth')),
                    POE_CC_ExpirationYear__c = String.valueOf(options.get('expirationYear')),
                    POE_CC_Ccv__c = String.valueOf(options.get('cvv')),
                    POE_CC_Zipcode__c = String.valueOf(options.get('zipCode')),
                    POE_Credit_Card_Name__c = String.valueOf(options.get('name'))
                );

                update oppToUpdate;
            }
        } catch (Exception e) {
            result = false;
        }

        return result;
    }
}
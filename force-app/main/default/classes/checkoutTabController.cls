public without sharing class checkoutTabController {
    @AuraEnabled
    public static ResponseWrapper getCreditCardTypes() {
        try {
            ResponseWrapper response = new ResponseWrapper();
            List<Credit_Card_Types__mdt> ccTypes = [
                SELECT Id, Label, DeveloperName
                FROM Credit_Card_Types__mdt
                WHERE Id != ''
                ORDER BY Label ASC
            ];
            response.result = new Map<String, Object>{ 'Credit_Card_Types__mdt' => ccTypes };

            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper getCreditCardInformation(Map<String, Object> myData) {
        try {
            String contextId = (String) myData.get('ContextId');

            ResponseWrapper response = new ResponseWrapper();

            Map<String, Object> ccData = POECCEncryptionService.decryptCreditCardData(contextId);
            if (!ccData.isEmpty()) {
                Map<String, Object> upFront = (Map<String, Object>) ccData.get('upFront');
                Map<String, Object> autoPay = (Map<String, Object>) ccData.get('autoPay');
                Boolean useSameCardAsAutoPay = (Boolean) ccData.get('useSameCardAsAutoPay');
                Boolean hasAutopay = (Boolean) ccData.get('hasAutoPay');
                Boolean hasACH = (Boolean) ccData.get('hasACH');
                Map<String, Object> result = new Map<String, Object>{
                    'hasAutopay' => hasAutopay,
                    'hasACH' => hasACH,
                    'useSameCardAsAutoPay' => useSameCardAsAutoPay,
                    'ccCcv' => upFront.get('ccv'),
                    'ccNumber' => upFront.get('ccNumber'),
                    'ccType' => upFront.get('type'),
                    'ccExpirationMonth' => upFront.get('ccMonth'),
                    'ccExpirationYear' => upFront.get('ccYear'),
                    'ccFirstName' => upFront.get('firstName'),
                    'ccLastName' => upFront.get('lastName'),
                    'ccZipcode' => upFront.get('zipCode'),
                    'ccName' => upFront.get('cardholderName')
                };

                if (hasAutopay && !useSameCardAsAutoPay) {
                    result.put('autoPayCcNumber', autoPay.get('ccNumber'));
                    result.put('autoPayFirstName', autoPay.get('firstName'));
                    result.put('autoPayLastName', autoPay.get('lastName'));
                    result.put('autoPayMonth', autoPay.get('ccMonth'));
                    result.put('autoPayYear', autoPay.get('ccYear'));
                    result.put('autoPayCvv', autoPay.get('ccv'));
                    result.put('autoPayCcName', autoPay.get('cardholderName'));
                    result.put('autoPayZip', autoPay.get('zipCode'));
                    result.put('autoPayType', autoPay.get('type'));
                }

                if (hasACH != null && hasACH) {
                    Map<String, Object> achInfo = (Map<String, Object>) ccData.get('ach');
                    result.put('achAccountFirstName', achInfo.get('achAccountFirstName'));
                    result.put('achAccountLastName', achInfo.get('achAccountLastName'));
                    result.put('achBankRoutingNumber', achInfo.get('achBankRoutingNumber'));
                    result.put('achBankAccountNumber', achInfo.get('achBankAccountNumber'));
                    result.put('achAccountType', achInfo.get('achAccountType'));
                    result.put('achAccountClass', achInfo.get('achAccountClass'));
                }

                response.result = result;
            }

            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper getEarthlinkKeys(Map<String, Object> myData) {
        try {
            String env = (String) myData.get('env');
            String program = (String) myData.get('program');

            ResponseWrapper response = new ResponseWrapper();

            String url;

            if (env == 'dev') {
                if (program == 'spectrum') {
                    url = 'https://safetechpageencryptionvar.chasepaymentech.com/pie/v1/64100000000207/getkey.js';
                } else {
                    url = 'https://safetechpageencryptionvar.chasepaymentech.com/pie/v1/64100000000198/getkey.js';
                }
            } else {
                if (program == 'spectrum') {
                    url = 'https://safetechpageencryption.chasepaymentech.com/pie/v1/64100000000207/getkey.js';
                } else {
                    url = 'https://safetechpageencryption.chasepaymentech.com/pie/v1/64100000000198/getkey.js';
                }
            }

            HttpRequest req = new HttpRequest();
            req.setEndpoint(url);
            req.setMethod('GET');
            req.setHeader('Content-Type', 'application/json;charset=UTF-8');
            req.setTimeout(120000);
            req.setBody(JSON.serialize(myData));
            Http http = new Http();
            HTTPResponse res = http.send(req);
            String strResponse = res.getBody();

            String L = strResponse.substring(strResponse.indexOf('PIE.L = ') + 8, strResponse.indexOf('PIE.L = ') + 9);
            String E = strResponse.substring(strResponse.indexOf('PIE.E = ') + 8, strResponse.indexOf('PIE.E = ') + 9);
            String K = strResponse.substring(strResponse.indexOf('PIE.K = ') + 9, strResponse.indexOf('PIE.K = ') + 41);
            String keyId = strResponse.substring(
                strResponse.indexOf('PIE.key_id = ') + 14,
                strResponse.indexOf('PIE.key_id = ') + 22
            );
            String phase = strResponse.substring(
                strResponse.indexOf('PIE.phase = ') + 12,
                strResponse.indexOf('PIE.phase = ') + 13
            );

            Map<String, Object> result = new Map<String, Object>{
                'E' => E,
                'L' => L,
                'K' => K,
                'key_id' => keyId,
                'phase' => phase
            };

            response.result = result;

            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper updateOrderAndAccountBillingAddress(Map<String, Object> myData) {
        ResponseWrapper response = new ResponseWrapper();

        try {
            String recordId = (String) myData?.get('recordId');

            Map<Object, Object> billingCheckOutAddress = (Map<Object, Object>) myData?.get('billingCheckOutAddress');
            String billingStreet = (String) billingCheckOutAddress?.get('billingAddress');
            String billingAptNumber = (String) billingCheckOutAddress?.get('billingAptNumber');
            String billingCity = (String) billingCheckOutAddress?.get('billingCity');
            String billingState = (String) billingCheckOutAddress?.get('billingState');
            String billingStateName = (String) billingCheckOutAddress?.get('billingStateName');
            String billingCountry = (String) billingCheckOutAddress?.get('billingCountry');
            String billingZip = (String) billingCheckOutAddress?.get('billingZip');

            if (String.isNotBlank(billingAptNumber)) {
                billingStreet = String.format('{0} {1}', new List<String>{ billingStreet, billingAptNumber });
            }

            List<Order> orderList = [
                SELECT
                    Id,
                    OpportunityId,
                    AccountId,
                    BillingPostalCode,
                    BillingCity,
                    BillingState,
                    BillingStateCode,
                    BillingStreet,
                    BillingCountry
                FROM Order
                WHERE OpportunityId = :recordId
            ];

            Order order = orderList[0];
            order.BillingPostalCode = billingZip;
            order.BillingCity = billingCity;
            order.BillingStreet = billingStreet;
            order.BillingState = billingStateName;
            order.BillingStateCode = billingState;
            order.BillingCountry = billingCountry;

            Account accToUpdate = new Account(
                Id = order.AccountId,
                BillingPostalCode = billingZip,
                BillingCity = billingCity,
                BillingStreet = billingStreet,
                BillingState = billingStateName,
                BillingStateCode = billingState,
                BillingCountry = billingCountry,
                Billing_Address_Line_2__c = billingAptNumber
            );

            update new List<SObject>{ accToUpdate, order };

            response.result = new Map<String, Object>{ 'Order' => order, 'Success' => true };
        } catch (AuraHandledException e) {
            throw new AuraHandledException(e.getMessage());
        }
        return response;
    }

    @AuraEnabled
    public static ResponseWrapper getWindstreamVendorId() {
        try {
            ResponseWrapper response = new ResponseWrapper();
            List<Chuzo_Settings__c> settings = [SELECT Id, Windstream_Vendor_Id__c FROM Chuzo_Settings__c];
            response.result = new Map<String, Object>{ 'windstreamSetting' => settings };
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class ResponseWrapper {
        @AuraEnabled
        public map<String, Object> result;
    }
}
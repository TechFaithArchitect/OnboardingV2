public without sharing class POECCEncryptionService {
    public class ResponseWrapper {
        @AuraEnabled
        public Map<String, Object> result;
    }

    @AuraEnabled(cacheable=true)
    public static ResponseWrapper getOpportunityProgram(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String oppId = (String) myData.get('contextId');

            Opportunity opp = [SELECT Id, POE_Program__c FROM Opportunity WHERE Id = :oppId];

            response.result = new Map<String, Object>{ 'program' => opp.POE_Program__c };
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper encryptAndSaveCreditCardData(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();

            Id opportunityId = (Id) myData.get('opportunityId');
            String base64EncodedEncryptionKey = getEncryptionKey();
            Blob key = EncodingUtil.base64Decode(base64EncodedEncryptionKey);

            String ccDataAsString = JSON.serialize(myData.get('creditCardData'));
            Blob creditCardCardData = Blob.valueOf(ccDataAsString);

            Blob encryptedCCBlob = Crypto.encryptWithManagedIV('AES256', key, creditCardCardData);
            String encryptedCC = EncodingUtil.base64Encode(encryptedCCBlob);

            Opportunity opp = new Opportunity(Id = opportunityId);
            opp.POE_Credit_Card__c = encryptedCC;

            update opp;

            response.result = new Map<String, Object>{ 'success' => true };
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper encryptAndSaveCreditCheckData(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String opportunityId = (String) myData.get('opportunityId');
            String base64EncodedEncryptionKey = getEncryptionKey();
            Blob key = EncodingUtil.base64Decode(base64EncodedEncryptionKey);

            String sensitiveDataAsString = JSON.serialize(myData.get('sensitiveData'));
            Blob sensitiveData = Blob.valueOf(sensitiveDataAsString);

            Blob encryptedSensitiveDataBlob = Crypto.encryptWithManagedIV('AES256', key, sensitiveData);
            String encryptedSensitiveData = EncodingUtil.base64Encode(encryptedSensitiveDataBlob);

            Opportunity opp = new Opportunity(Id = opportunityId);
            opp.POE_Sensitive_Data__c = encryptedSensitiveData;

            update opp;

            response.result = new Map<String, Object>{ 'success' => true };
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static Map<String, Object> decryptCreditCheckData(String opportunityId) {
        try {
            String base64EncodedEncryptionKey = getEncryptionKey();
            Blob key = EncodingUtil.base64Decode(base64EncodedEncryptionKey);
            Map<String, Object> decryptedJson = new Map<String, Object>();
            List<Opportunity> opp = [SELECT POE_Sensitive_Data__c FROM Opportunity WHERE Id = :opportunityId];
            if (!opp.isEmpty()) {
                Blob encryptedCCData = EncodingUtil.base64Decode(opp[0].POE_Sensitive_Data__c);
                Blob decryptedData = Crypto.decryptWithManagedIV('AES256', key, encryptedCCData);
                String ccInfo = decryptedData.toString();
                decryptedJson = (Map<String, Object>) JSON.deserializeUntyped(ccInfo);
                return decryptedJson;
            }
            return decryptedJson;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    public static Map<String, Object> decryptCreditCardData(String opportunityId) {
        try {
            String base64EncodedEncryptionKey = getEncryptionKey();
            Blob key = EncodingUtil.base64Decode(base64EncodedEncryptionKey);
            Map<String, Object> decryptedJson = new Map<String, Object>();
            List<Opportunity> opp = [SELECT POE_Credit_Card__c FROM Opportunity WHERE Id = :opportunityId];
            if (!opp.isEmpty()) {
                Blob encryptedCCData = EncodingUtil.base64Decode(opp[0].POE_Credit_Card__c);
                Blob decryptedData = Crypto.decryptWithManagedIV('AES256', key, encryptedCCData);
                String ccInfo = decryptedData.toString();
                decryptedJson = (Map<String, Object>) JSON.deserializeUntyped(ccInfo);
                return decryptedJson;
            }
            return decryptedJson;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    public static String getEncryptionKey() {
        Chuzo_Creditcard_Encryption_Key__mdt record = [SELECT key__c FROM Chuzo_Creditcard_Encryption_Key__mdt LIMIT 1];
        if (record != null) {
            return record.key__c;
        } else {
            return null;
        }
    }
}
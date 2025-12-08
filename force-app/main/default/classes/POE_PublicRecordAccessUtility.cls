public without sharing class POE_PublicRecordAccessUtility {
    
    public static final String RECORD_ENCRYPT_SEP = ';';

    public static String encryptRecordId(Id recordId) {
        Schema.SObjectType sobjectType = recordId.getSObjectType();
        String sobjectName = sobjectType.getDescribe().getName();
        SObject record = Database.query('SELECT Id, CreatedDate FROM ' + sobjectName + ' WHERE Id = :recordId');

        String recordIdClearText = record.Id + RECORD_ENCRYPT_SEP + record.get('CreatedDate')
                                   + RECORD_ENCRYPT_SEP + Datetime.now();

        String base64EncodedEncryptionKey = [
            SELECT key__c 
            FROM Chuzo_Creditcard_Encryption_Key__mdt 
            LIMIT 1
        ].key__c;
        Blob key = EncodingUtil.base64Decode(base64EncodedEncryptionKey);
        Blob encryptedRecordBlob = Crypto.encryptWithManagedIV('AES256', key, Blob.valueOf(recordIdClearText));
        
        return EncodingUtil.base64Encode(encryptedRecordBlob);
    }

    public static String decryptRecordId(String base64EncodedBlob) {
        String base64EncodedEncryptionKey = [
            SELECT key__c 
            FROM Chuzo_Creditcard_Encryption_Key__mdt 
            LIMIT 1
        ].key__c;
        Blob key = EncodingUtil.base64Decode(base64EncodedEncryptionKey);

        Blob encryptedRecordBlob = EncodingUtil.base64Decode(base64EncodedBlob);
        Blob decryptedRecordBlob = Crypto.decryptWithManagedIV('AES256', key, encryptedRecordBlob);
        String decryptedRecordData = decryptedRecordBlob.toString();
        String recordId = decryptedRecordData.split(RECORD_ENCRYPT_SEP)[0];

        return recordId;
    }

    public static Boolean isEncryptedId(String idString) {
        String salesforceIdRegex = '[a-zA-Z0-9]{15}|[a-zA-Z0-9]{18}';

        Pattern MyPattern = Pattern.compile(salesforceIdRegex);
        Matcher MyMatcher = MyPattern.matcher(idString);

        return !MyMatcher.matches();
    }
}
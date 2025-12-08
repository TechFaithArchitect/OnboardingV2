public class EncryptSAForSelfScheduling {
    public class EncryptionInput {
        @InvocableVariable(label='Record ID' description='Record ID to encrypt' required=true)
        public String recordIdList;
        
        @InvocableVariable(label='URL' description='Base URL for the encrypted link')
        public String url;
        
        @InvocableVariable(label='Encode Record ID' description='Encode the Record ID')
        public Boolean encodeRecordId;
    }

    @InvocableMethod(label='Encryption')
    public static List<string> encrypt(List<EncryptionInput> inputs) {
        String sParam; 
        String encrypted ;
        Blob bbEncryptedParam;
        string sURL;
        Blob bbIvKey = Blob.valueOf(System.Label.IVKey);
        Blob bbPrivateKey = Crypto.generateDigest('SHA256', Blob.valueOf(System.Label.privateKey));
        List<String> response = new List<String>();
        for (EncryptionInput input : inputs) {
            sURL = String.isNotBlank(input.url) ? input.url : System.Label.Self_service_scheduling_existing_appointment;
            sParam = input.recordIdList;
            bbEncryptedParam = Crypto.encrypt('AES256', bbPrivateKey,bbIvKey, Blob.valueOf(sParam));
            encrypted = EncodingUtil.urlEncode(EncodingUtil.base64Encode(bbEncryptedParam), 'UTF-8');
            if (input.encodeRecordId != null && input.encodeRecordId) {
                encrypted = EncodingUtil.urlEncode(EncodingUtil.base64Encode(Blob.valueOf(encrypted)), 'UTF-8');
            }
            sURL = sURL + '?recordId=' + encrypted;
            response.add(sURL);
        }
        System.debug(response);
        return response;
    }
}
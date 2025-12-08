/**
* @description       : To Decrypt recordId
* @author            : Impaqtive DevTeam
* @group             :
* @last modified on  : 11-06-2024
* @last modified by  : Impaqtive DevTeam
* Modifications Log
* Ver   Date         Author            Modification
* 1.0                      Initial Version
**/
public class DecryptSAforSelfScheduling {
    @InvocableMethod(label='Decryption')
    public static List<String> decrypt(List<String> recordIdList){    
        Blob bbDecoded;
        Blob bbDecrypted;
        string decrypted;
        List<String> response = new List<String>();
        Blob bbIvKey = blob.valueOf(system.Label.IVKey);
        blob bbPrivateKey = Crypto.generateDigest('SHA256', blob.valueOf(system.Label.privateKey));
        for(String recordId: recordIdList){
            bbDecoded = EncodingUtil.base64decode(EncodingUtil.URLdecode(recordId,'UTF-8'));
            bbDecrypted = Crypto.decrypt('AES256', bbPrivateKey, bbIvKey,  bbDecoded);
            decrypted = bbDecrypted.toString();
            response.add(decrypted);
        }
        return response;
    }
}
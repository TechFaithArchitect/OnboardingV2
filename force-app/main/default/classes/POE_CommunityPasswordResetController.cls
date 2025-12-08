public with sharing class POE_CommunityPasswordResetController {
    public static final String ERROR = 'Error';
    public static final String SUCCESS = 'Success';

    public class ResponseWrapper {
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String errorMessage;
    }

    @AuraEnabled
    public static String setUserPassword(String encodedPassword) {
        String userId = UserInfo.getUserId();
        Blob passwordBlob = EncodingUtil.base64Decode(encodedPassword);
        String password = passwordBlob.toString();
        ResponseWrapper response = new ResponseWrapper();
        String serializedResponse;
        try {
            System.setPassword(userId, password);
            response.status = SUCCESS;
        } catch (Exception ex) {
            response.status = ERROR;
            response.errorMessage = ex.getMessage();
        }
        serializedResponse = JSON.serialize(response);
        return serializedResponse;
    }
}
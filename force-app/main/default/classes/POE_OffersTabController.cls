public without sharing class POE_OffersTabController {
    @testVisible
    private static Boolean throwException = false;
    
    @AuraEnabled
    public static ResponseWrapper getAgentName() {
        try {
            if (throwException) {
                throw new CustomException();
            }

            ResponseWrapper response = new ResponseWrapper();

            User agentUser = [
                SELECT Contact.FirstName, Contact.LastName
                FROM User
                WHERE Id = :UserInfo.getUserId()
            ];

            response.result = new Map<String, Object>{
                'firstName' => agentUser.Contact.FirstName,
                'lastName' => agentUser.Contact.LastName
            };
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class ResponseWrapper {
        @AuraEnabled
        public Map<String, Object> result;
    }
}
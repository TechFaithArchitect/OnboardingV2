public with sharing class ChuzoSessionUtilities {
    public class Response {
        @AuraEnabled
        public Boolean isGuest;

        public Response(Boolean isGuest) {
            this.isGuest = isGuest;
        }
    }

    @AuraEnabled
    public static Response checkUserStatus() {
        Boolean isGuest = Auth.CommunitiesUtil.isGuestUser();

        return new Response(isGuest);
    }
}
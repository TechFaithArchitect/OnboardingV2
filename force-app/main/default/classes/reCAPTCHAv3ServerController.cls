public without sharing class reCAPTCHAv3ServerController {
    
    public reCAPTCHAv3ServerController() {
    }

    @AuraEnabled
    public static Boolean isReCAPTCHAValid(String tokenFromClient) {
        try {
            
            Chuzo_Settings__c settings = Chuzo_Settings__c.getOrgDefaults();
            String SECRET_KEY = settings.ReCaptcha_Secret_Key__c;
            String RECAPTCHA_SERVICE_URL = settings.Recaptcha_API_URL__c;
            
            Double MINIMUM_ACCEPTABLE_SCORE = settings.ReCaptcha_Minimum_Acceptable_Score__c != null 
                ? settings.ReCaptcha_Minimum_Acceptable_Score__c 
                : 0.5; 
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();

            request.setEndpoint(RECAPTCHA_SERVICE_URL + '?secret=' + SECRET_KEY + '&response=' + tokenFromClient);
            request.setMethod('POST');
            request.setHeader('Content-Length', '0');
            HttpResponse response = http.send(request);

            Map<String, Object> mapOfBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

            Boolean success = (Boolean) mapOfBody.get('success');
            Double score = (Double) mapOfBody.get('score');

            Boolean result = success && score != null && score >= MINIMUM_ACCEPTABLE_SCORE;
            
            return result;
            
        } catch (Exception e) {
            return false;
        }
    }
}
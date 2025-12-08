public without sharing class RecaptchaController {

    private static final String RECAPTCHA_SECRET_KEY = Chuzo_Settings__c.getOrgDefaults().ReCaptcha_Secret_Key_V2__c;
        
    @AuraEnabled
    public static Map<String, Object> validateCaptcha(String recaptchaResponse) {
        String url = Chuzo_Settings__c.getOrgDefaults().Recaptcha_API_URL__c;

        HttpRequest request = new HttpRequest();
        request.setEndpoint(url);
        request.setMethod('POST');
        request.setBody('secret=' + RECAPTCHA_SECRET_KEY + '&response=' + recaptchaResponse);

        HttpResponse response = new Http().send(request);
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

        return responseMap;
    }
}
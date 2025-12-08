public without sharing class SecurityInfoTabController {
    final static String validChars = '0123456789';

    @AuraEnabled
    public static ResponseWrapper sendValidationEmail(Map<String, Object> myData){
        try {
            ResponseWrapper response = new ResponseWrapper();

            String email = (String) myData.get('emailAddress');
            String contactName = (String) myData.get('contactName');

            String pincode = '';
            while (pincode.length() < 6) {
                Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), validChars.length());
                pincode += validChars.substring(idx, idx+1);
            }


            OrgWideEmailAddress orgWideEmail = [
                SELECT Id 
                FROM OrgWideEmailAddress 
                WHERE Address = 'no-reply@chuzo.com'
            ];

            EmailTemplate template = [SELECT Id, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Chuzo_DTV_Confirmation'];

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail = Messaging.renderStoredEmailTemplate(template.id, null, null);
            mail.setOrgWideEmailAddressId(orgWideEmail.Id);
            mail.setToAddresses(new List<String>{email});
            mail.setHtmlBody(mail.getHtmlBody().replace('{pincode}', pincode));
            mail.setHtmlBody(mail.getHtmlBody().replace('{contactName}', contactName));

            Messaging.SendEmailResult emailResult = Messaging.sendEmail(
                new List<Messaging.SingleEmailMessage> { mail }
            )[0];

            response.result = new Map<String, Object> {
                'error' => !emailResult.isSuccess()
            };

            if (!emailResult.isSuccess()) {
                response.result.put('errorMessage', emailResult.getErrors()[0].getMessage());
            } else {
                response.result.put('pincode', pincode);
            }

            return response;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class ResponseWrapper{
        @AuraEnabled
        public Map<String, Object> result;
    }
}
global without sharing class POESendPCISMS implements vlocity_cmt.VlocityOpenInterface {

    global Boolean invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        Boolean result = true;
        
        try {
            POE_Callout_Config_API__mdt dat = POE_Callout_Config_API__mdt.getInstance('Twilio');
            String accountSid = (String) inputMap.get('AccountId');
            String token = (String) inputMap.get('Password');
            String endPoint = dat.URL__c;
            String credentials = accountSid + ':' + token;
            String textBody = (String) inputMap.get('Body');
            
            if (textBody.contains('pci-checkout')) {
                textBody = EncodingUtil.urlEncode(textBody, 'UTF-8');
            }

            String fromPhone = (String) inputMap.get('From');
            String toPhone = (String) inputMap.get('To');
            String contactId = (String) inputMap.get('ContactId');

            PV_TwilioIntegrationHandler.sendTwilioSMS(textBody, fromPhone, toPhone, credentials, endPoint, contactId, null);
        } catch (Exception e) {
            result = false;
        }
        return result;
    }
}
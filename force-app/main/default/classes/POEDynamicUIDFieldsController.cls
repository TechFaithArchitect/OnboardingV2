public without sharing class POEDynamicUIDFieldsController {
    @AuraEnabled(cacheable=false)
    public static String getDealerEmail(String recordId) {
        String email = '';
        Contact agent = [SELECT Id, AccountId FROM Contact WHERE Id = :recordId LIMIT 1];
        Account dealer = [SELECT Id, POE_Dealer_Office_Email__c FROM Account WHERE Id = :agent.AccountId LIMIT 1];
        if (!String.isBlank(dealer.POE_Dealer_Office_Email__c)) {
            email = dealer.POE_Dealer_Office_Email__c;
        }
        return email;
    }

    @AuraEnabled(cacheable=true)
    public static void sendEmail(String body, String toSend, String[] ccAddresses) {
        try {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new List<String>{ toSend };
            mail.setToAddresses(toAddresses);
            mail.setSubject('[Customer Service] Additional Information Requirement');
            mail.setHtmlBody('<p>' + body + '</p>');
            if (! ccAddresses.isEmpty()) {
                mail.setCcAddresses(ccAddresses);
            }
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
}
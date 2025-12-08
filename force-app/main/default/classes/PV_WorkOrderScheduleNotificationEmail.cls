public class PV_WorkOrderScheduleNotificationEmail {
    public class EmailRequest {
        @InvocableVariable(required=true)
        public Id workOrderId;
        @InvocableVariable(required=true)
        public String subject;
        @InvocableVariable(required=true)
        public String body;
    }

    @InvocableMethod
    public static void sendEmailonWorkOrderScheduling(List<EmailRequest> emailRequests) {
        for (EmailRequest request : emailRequests) {
            WorkOrder wo = [
                SELECT Id, SIM_Email__c, Sales_Rep_Email__c, Contact.Email
                FROM WorkOrder
                WHERE Id = :request.workOrderId
                LIMIT 1
            ];
            List<String> toAddresses = new List<String>();
            List<String> ccAddresses = new List<String>();

            if (!String.isBlank(wo.Contact.Email)) {
                toAddresses.add(wo.Contact.Email);
            }
            if (wo.Sales_Rep_Email__c != null) {
                ccAddresses.add(wo.Sales_Rep_Email__c);
            }
            if (wo.SIM_Email__c != null) {
                ccAddresses.add(wo.SIM_Email__c);
            }
            String owaEmail = System.Label.PV_OWA_Notification;
            OrgWideEmailAddress owa = [SELECT id FROM OrgWideEmailAddress WHERE Address = :owaEmail LIMIT 1];

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            if (!toAddresses.isEmpty()) {
                mail.setToAddresses(toAddresses);
            }
            if (!ccAddresses.isEmpty()) {
                mail.setCcAddresses(ccAddresses);
            }
            mail.setSaveAsActivity(true);
            mail.setWhatId(wo.Id);
            mail.setOrgWideEmailAddressId(owa.id);
            mail.setSubject(request.subject);
            mail.setPlainTextBody(request.body);
            Messaging.SendEmailResult[] results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
        }
    }
}
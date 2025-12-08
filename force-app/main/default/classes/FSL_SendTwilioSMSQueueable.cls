public without sharing class FSL_SendTwilioSMSQueueable implements Queueable, Database.AllowsCallouts {

    private FSL_SendTwiloSMS.MessageWrapper queableSMSData;


    public FSL_SendTwilioSMSQueueable(FSL_SendTwiloSMS.MessageWrapper payload) {
        this.queableSMSData = payload;
    }

    public void execute(QueueableContext context) {
        Boolean result = true;

        if(queableSMSData.SMSDataList.size() > 0) {
            String textBody = queableSMSData.SMSDataList[0].body;
            String toPhone = queableSMSData.SMSDataList[0].clientPhone;
            String contactId = queableSMSData.SMSDataList[0].contactId;
            String ServiceAppointmentId = queableSMSData.SMSDataList[0].serviceAppointmentId;

            result = PV_TwilioIntegrationHandler.sendTwilioSMS(textBody, 
                                                               queableSMSData.fromPhone, 
                                                               toPhone, 
                                                               queableSMSData.credentials, 
                                                               queableSMSData.endPoint, 
                                                               contactId,
                                                               ServiceAppointmentId);


            this.queableSMSData.SMSDataList.remove(0);

            if (!Test.isRunningTest()) {
                System.enqueueJob(new FSL_SendTwilioSMSQueueable(this.queableSMSData));
            }
        }
        
    }
}
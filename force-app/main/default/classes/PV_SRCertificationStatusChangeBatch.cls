global class PV_SRCertificationStatusChangeBatch implements Database.Batchable<sObject> {
    
    global Database.QueryLocator start(Database.BatchableContext BC) 
    {
        Date plussixtyDays = System.TODAY().addDays(60);
        String query = 'SELECT Id,Name,Viasat_Expiration__c,DIRECTV_Expiration__c, RelatedRecordId, Certification_Status_Viasat__c,Certification_Status_DIRECTV__c,Manager__c FROM ServiceResource WHere  IsActive =true AND (Viasat_Expiration__c =TODAY OR DIRECTV_Expiration__c=TODAY OR Viasat_Expiration__c=:plussixtyDays OR DIRECTV_Expiration__c=:plussixtyDays)' ;
        system.debug(query);
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<ServiceResource> SRList) {
       
        List<ServiceResource> recipientExpViasat = new List<ServiceResource>();
        List<ServiceResource> recipientNearExpViasat = new List<ServiceResource>();
        List<ServiceResource> recipientExpDTV = new List<ServiceResource>();
        List<ServiceResource> recipientNearExpDTV = new List<ServiceResource>();
        
        system.debug('SRList-->'+SRList);
        
        List<ServiceResource> recipientExpViasatMngr = new List<ServiceResource>();
        List<ServiceResource> recipientNearExpViasatMngr = new List<ServiceResource>();
        List<ServiceResource> recipientExpDTVMngr = new List<ServiceResource>();
        List<ServiceResource> recipientNearExpDTVMngr = new List<ServiceResource>();
        
        String viasatExpNotificationMsg = Label.PV_ViasatExpiry_Msg;
        String viasatExpNotificationMsgBody = Label.PV_ViasatExpiry_MsgBody;
        //String viasatNearExpNotificationMsg = Label.PV_ViasatNearExpiry_Msg;
        String viasatNearExpNotificationMsgBody = Label.PV_ViasatNearExpiry_MsgBody;        
        
        String DTVExpNotificationMsg = Label.PV_DTVExpiry_Msg;
        String DTVExpNotificationMsgBody = Label.PV_DTVExpiry_MsgBody;
        //String DTVNearExpNotificationMsg = Label.PV_DTVNearExpiry_Msg;
        String DTVNearExpNotificationMsgBody = Label.PV_DTVNearExpiry_MsgBody;
        Date todayplussixty = System.TODAY().addDays(60);
        
        string MessageExpirationV = '\'s Viasat Certification has expired';
        String messageNearingExpirationV = '\'s Viasat Certification will expire in 60 days';
        string MessageExpirationD = '\'s DIRECTV Certification has expired';
        String messageNearingExpirationD = '\'s DIRECTV Certification will expire in 60 days';
        
        try
        {
            for(ServiceResource sr : SRList) {
                if(sr.Viasat_Expiration__c!=Null)
                {
                    if(sr.Viasat_Expiration__c==Date.today())
                    {
                        sr.Certification_Status_Viasat__c='Expired';
                        recipientExpViasat.add(sr);
                        recipientExpViasatMngr.add(sr);
                    }
                    else if(sr.Viasat_Expiration__c==todayplussixty ) 
                    {
                        sr.Certification_Status_Viasat__c='Nearing Expiration'; 
                        recipientNearExpViasat.add(sr);
                        recipientNearExpViasatMngr.add(sr);
                    }
                }
                //Chking for DirecTV Dates
                if(sr.DIRECTV_Expiration__c!=Null)
                {
                    if(sr.DIRECTV_Expiration__c==Date.today())
                    {
                        sr.Certification_Status_DIRECTV__c='Expired';                           
                        recipientExpDTV.add(sr);
                        recipientExpDTVMngr.add(sr);
                        
                    }
                    else if(sr.DIRECTV_Expiration__c==todayplussixty ) 
                    {
                        sr.Certification_Status_DIRECTV__c='Nearing Expiration'; 
                        recipientNearExpDTV.add(sr);
                        recipientNearExpDTVMngr.add(sr);
                        
                    }
                }                       
            }
            update SRList;
            
            if(recipientExpViasat.size()>0)
                notifyUsers(recipientExpViasat, viasatExpNotificationMsg,viasatExpNotificationMsgBody);
            if(!recipientExpViasatMngr.isEmpty())
                notifyManagers(recipientExpViasatMngr,'Viasat Certification has Expired',MessageExpirationV);
            if(recipientNearExpViasat.size()>0)                        
                notifyUsers(recipientNearExpViasat,viasatExpNotificationMsg,viasatNearExpNotificationMsgBody);
            if(!recipientNearExpViasatMngr.isEmpty())
                notifyManagers(recipientNearExpViasatMngr,'Viasat certification is about to expire',messageNearingExpirationV);
            
            
            if(recipientExpDTV.size()>0)
                notifyUsers(recipientExpDTV, DTVExpNotificationMsg,DTVExpNotificationMsgBody);
            if(!recipientExpDTVMngr.isEmpty())
                notifyManagers(recipientExpDTVMngr,'DIRECTV Certification has Expired',MessageExpirationD);
            if(recipientNearExpDTV.size()>0)                        
                notifyUsers(recipientNearExpDTV,DTVExpNotificationMsg,DTVNearExpNotificationMsgBody);
            if(!recipientNearExpDTVMngr.isEmpty())
                notifyManagers(recipientNearExpDTVMngr,'DIRECTV certification is about to expire',messageNearingExpirationD);
            
        }
        catch (Exception ex) 
        {
            ExceptionUtil.publishException('PV_SRCertificationStatusChangeBatch.execute', ex.getLineNumber(), ex.getMessage(), ex.getStackTraceString());
        }
    }
    
    public static void notifyUsers(List<ServiceResource> recipients,String msgTitle, String msgBody) {
        // Get the Id for our custom notification type
        CustomNotificationType notificationType = 
            [SELECT Id, DeveloperName 
             FROM CustomNotificationType 
             WHERE DeveloperName='Certification_Expiry_Notification'];
        
        // Create a new custom notification
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle(msgTitle);
        notification.setBody(msgBody);
        notification.setNotificationTypeId(notificationType.Id);
        try
        {
            for(ServiceResource rc: recipients)
            {
                Set<String> recipient = new Set<String>();
                system.debug('rc--.'+rc);
                recipient.add(rc.RelatedRecordId);
                notification.setTargetId(rc.Id);
                notification.send(recipient);
            }
        }
        catch (Exception ex) 
        {
            ExceptionUtil.publishException('Issue in Sending Notification', ex.getLineNumber(), ex.getMessage(), ex.getStackTraceString());
        }
    }
    
    
    
    public static void notifyManagers(List<ServiceResource> recipientss,String msgTitle, String msg) {
        // Get the Id for our custom notification type
        CustomNotificationType notificationType =[SELECT Id, DeveloperName 
                                                  FROM CustomNotificationType 
                                                  WHERE DeveloperName='Certification_Expiry_Notification'];
        
        // Create a new custom notification
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle(msgTitle);
        notification.setNotificationTypeId(notificationType.Id);
        try
        {
            for(ServiceResource rc: recipientss)
            {
                Set<String> recipient = new Set<String>();
                system.debug('rc--.'+rc);
                recipient.add(rc.Manager__c);
                notification.setTargetId(rc.Id);
                String resourceName = rc.Name;
                notification.setBody(resourceName+msg);
                notification.send(recipient);
                system.debug('resourceName-->'+resourceName);
            }
        }
        catch (Exception ex) 
        {
            ExceptionUtil.publishException('Issue in Sending Notifications', ex.getLineNumber(), ex.getMessage(), ex.getStackTraceString());
        }
    }
    
    
    
    global void finish(Database.BatchableContext BC) {
        // execute any post-processing operations like sending email
        
    }
}
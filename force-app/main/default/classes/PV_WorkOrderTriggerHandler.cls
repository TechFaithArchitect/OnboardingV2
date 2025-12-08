/**
* @description       : Handler Class for PV_WorkOrderTrigger
* @author            : Impaqtive DevTeam
* @group             :
* @last modified on  : 12-05-2023
* @last modified by  : Impaqtive DevTeam
* Modifications Log
* Ver   Date         Author            Modification
* 1.0                      Initial Version
**/
public class PV_WorkOrderTriggerHandler {
    static String viasatWT = Label.ViaSat_Skills;
    static String DirecTVWT = Label.DirecTV_Skills;
    static String DirecTV = Label.DIRECTV;
    static String ViaSat = Label.ViaSat;
    static String emailBody = Label.T_Mobile_Template;
    
    public static void handleBeforeInsert (List<WorkOrder> workOrders){
        try{
            List<String> assignWOTerritory = Label.PV_AssignWOTerritory.Split(',');
            List<String> pcList = new List<String>();
            List<Id> accList = new List<Id>();
            Map<Id, String> codeList = new Map<Id, String>();
            for(WorkOrder wo: workOrders){
                accList.add(wo.AccountId);
                if(wo.PostalCode != Null && assignWOTerritory.contains(wo.Vendor__c)){
                    pcList.add(wo.PostalCode.substring(0, 5));
                }
            }
            for(Account acc:[SELECT Id, BillingPostalCode FROM Account WHERE Id IN: accList]){
                codeList.put(acc.Id, acc.BillingPostalCode);
            }
            
            Set<String> postalCodes = new Set<String>();
            Map<Id, String> postalCodeByWorkOrderId = new Map<Id, String>();
            
            for (WorkOrder wo : workOrders) {
                String postalCode = null;
                
                if (assignWOTerritory.contains(wo.Vendor__c)) {
                    postalCode = wo.PostalCode?.substring(0, 5);
                } else {
                    postalCode = codeList.get(wo.AccountId);
                }
                
                if (postalCode != null) {
                    postalCodes.add(postalCode);
                    postalCodeByWorkOrderId.put(wo.Id, postalCode);
                }
            }
            
            Map<String, List<Assigned_Postal_Code__c>> vendorMatchesByPostalCode = new Map<String, List<Assigned_Postal_Code__c>>();
            Map<String, Assigned_Postal_Code__c> fallbackByPostalCode = new Map<String, Assigned_Postal_Code__c>();
            
            for (Assigned_Postal_Code__c apc : [
                SELECT Id, Postal_Code__c, Service_Territory__r.Id, Service_Territory__r.Vendors__c
                FROM Assigned_Postal_Code__c 
                WHERE Postal_Code__c IN :postalCodes
            ]) {
                if (String.isBlank(apc.Service_Territory__r.Vendors__c)) {
                    fallbackByPostalCode.put(apc.Postal_Code__c, apc);
                } else {
                    if (!vendorMatchesByPostalCode.containsKey(apc.Postal_Code__c)) {
                        vendorMatchesByPostalCode.put(apc.Postal_Code__c, new List<Assigned_Postal_Code__c>());
                    }
                    vendorMatchesByPostalCode.get(apc.Postal_Code__c).add(apc);
                }
            }
            
            for (WorkOrder wo : workOrders) {
                String postalCode = postalCodeByWorkOrderId.get(wo.Id);
                String vendor = wo.Vendor__c;
                
                if (postalCode != null && vendor != null) {
                    List<Assigned_Postal_Code__c> vendorMatches = vendorMatchesByPostalCode.get(postalCode);
                    Assigned_Postal_Code__c selectedMatch = null;
                    
                    if (vendorMatches != null && !vendorMatches.isEmpty()) {
                        for (Assigned_Postal_Code__c apc : vendorMatches) {
                            if (apc.Service_Territory__r.Vendors__c.contains(vendor)) {
                                selectedMatch = apc;
                                break;
                            }
                        }
                    }
                    
                    if (selectedMatch == null) {
                        selectedMatch = fallbackByPostalCode.get(postalCode);
                    }
                    
                    if (selectedMatch != null) {
                        wo.ServiceTerritoryId = selectedMatch.Service_Territory__r.Id;
                    }
                }
            }
        }catch (Exception ex) {
            ExceptionUtil.publishException('PV_WorkOrderTriggerHandler.handleBeforeInsert', ex.getLineNumber(), ex.getMessage(), ex.getStackTraceString());
        }
    }
    
    //Method to create Messaging Users    
    public static void messagingUserCreation(List<WorkOrder> workOrderList){
        
        Set<Id> accIdSet = new Set<Id>();
        Set<Id> conIdSet = new Set<Id>();
        List<string> msUserAccountWorkType = PV_FSL_Config__mdt.getInstance('MS_User_Account').Value__c.split(',');
        List<string> msUserContactWorkType = PV_FSL_Config__mdt.getInstance('MS_User_Contact').Value__c.split(',');
        MessagingChannel mc = [Select Id from MessagingChannel where DeveloperName LIKE '%TEXT_US_1%'];
        
        for(WorkOrder wo :workOrderList){
            if(wo.AccountId != null){
                accIdSet.add(wo.AccountId);
            }
            if(wo.ContactId != null){
                conIdSet.add(wo.ContactId);
            }
        }
        
        Map<Id, Account> accMap = new Map<Id, Account>([SELECT Id, Name, Phone FROM Account WHERE Id IN: accIdSet]);
        Map<Id, Contact> conMap = new Map<Id, Contact>([SELECT Id, Name, Phone FROM Contact WHERE Id IN: conIdSet]);
        
        Set<String> phoneNumbers = new Set<String>();
        for (Account acc : accMap.values()) {
            if (acc.Phone != null) {
                phoneNumbers.add(changePhoneFormat(acc.Phone));
            }
        }
        for (Contact con : conMap.values()) {
            if (con.Phone != null) {
                phoneNumbers.add(changePhoneFormat(con.Phone));
            }
        }
        
        Map<String, MessagingEndUser> existingEndUsersMap = new Map<String, MessagingEndUser>();
        for (MessagingEndUser existingUser : [SELECT Id, MessagingPlatformKey 
                                              FROM MessagingEndUser 
                                              WHERE MessagingPlatformKey IN :phoneNumbers]) {
                                                  existingEndUsersMap.put(existingUser.MessagingPlatformKey, existingUser);
                                              }
        
        List<MessagingEndUser> mUserList = new List<MessagingEndUser>();
        for(WorkOrder wOd:workOrderList){
            if(msUserAccountWorkType.contains(wOd.Vendor__c) && wOd.AccountId != null 
               && accMap.get(wOd.AccountId).Phone != null &&
               !(existingEndUsersMap.containsKey(changePhoneFormat(accMap.get(wOd.AccountId).Phone)))){
                   MessagingEndUser mUs = new MessagingEndUser();
                   mUs.AccountId = wOd.AccountId;
                   mUs.MessageType	= 'Text';
                   mUs.MessagingChannelId = mc.Id;
                   mUs.HasInitialResponseSent = true;
                   mUs.MessagingConsentStatus = 'ImplicitlyOptedIn';
                   mUs.Name = accMap.get(wOd.AccountId).Name;
                   mUs.MessagingPlatformKey = changePhoneFormat(accMap.get(wOd.AccountId).Phone);
                   mUserList.add(mUs);
                   existingEndUsersMap.put(accMap.get(wOd.AccountId).Phone, mUs);
               }
            
            if(msUserContactWorkType.contains(wOd.Vendor__c) && wOd.ContactId != null 
               && conMap.get(wOd.ContactId).Phone != null &&
               !existingEndUsersMap.containsKey(changePhoneFormat(conMap.get(wOd.ContactId).Phone))){
                   MessagingEndUser mUs = new MessagingEndUser();
                   mUs.ContactId = wOd.ContactId;
                   mUs.MessageType	= 'Text';
                   mUs.MessagingChannelId = mc.Id;
                   mUs.HasInitialResponseSent = true;
                   mUs.MessagingConsentStatus = 'ImplicitlyOptedIn';
                   mUs.Name = conMap.get(wOd.ContactId).Name;
                   mUs.MessagingPlatformKey = changePhoneFormat(conMap.get(wOd.ContactId).Phone);
                   mUserList.add(mUs);
                   existingEndUsersMap.put(conMap.get(wOd.ContactId).Phone, mUs);
               }
        }
        if(!mUserList.isEmpty()){
            insert mUserList;
        }
        
    } 
    
    public static string changePhoneFormat(String phoneNumber){
        if(phoneNumber.startsWith('+1')){
            phoneNumber = phoneNumber.replaceAll('[^0-9]', ''); 
            phoneNumber = '+' + phoneNumber; 
            return phoneNumber;
        }else{
            //remove - and ()
            phoneNumber = phoneNumber.replaceAll('[^0-9]', ''); 
            // Add country code prefix 
            phoneNumber = '+1' + phoneNumber; 
            return phoneNumber;
        }
    }
    
    //Method to check previous completed service appointment
    public static void checkPreviosServiceAppt (List<WorkOrder> wokOrderList){
        
        List<Id> accountIdList = new List<Id>();
        //To store last 90 days work types
        Map<Id,List<String>>accountWorkTypeMap = new Map<Id,List<String>>();
        //To store work type under DIRECTV/Viasat based on Worktype category
        Map<String,List<String>>workTypeNameMap = new Map<String,List<String>>();
        Map<String,List<String>>workTypeIdMap = new Map<String,List<String>>();
        
        for(PV_FSL_Config__mdt config : [Select MasterLabel,Value__c from PV_FSL_Config__mdt where Type__c = 'WORK_ORDER_90']){
            workTypeNameMap.put(config.MasterLabel,config.Value__c.split(','));
        }
        
        for(WorkType  wrktype:[Select Id,Name from WorkType where Name IN: workTypeNameMap.keyset()]){
            workTypeIdMap.put(wrktype.Id,workTypeNameMap.get(wrktype.Name));
        }
        for(WorkOrder ordr: wokOrderList){
            if(ordr.AccountId != null && ordr.WorkTypeId != null && workTypeIdMap.keyset().contains(ordr.WorkTypeId )){
                accountIdList.add(ordr.AccountId);
            }
        }
        //Map to create worktypes under an account
        for(ServiceAppointment serviceAppmt :[SELECT WorkType.Name,AccountId  from ServiceAppointment where AccountId =:accountIdList AND SA_Completed_Date__c= LAST_N_DAYS:90]){
            if(accountWorkTypeMap.containsKey(serviceAppmt.AccountId)){
                accountWorkTypeMap.get(serviceAppmt.AccountId).add(serviceAppmt.WorkType.Name);
            }else{
                accountWorkTypeMap.put(serviceAppmt.AccountId, new List<String>{serviceAppmt.WorkType.Name});
            }
        }
        //To check for a particular worktype previous appointment exists or not
        for(WorkOrder wrkOdr:wokOrderList){
            if(wrkOdr.AccountId != null && wrkOdr.WorkTypeId != null && workTypeIdMap.containskey(wrkOdr.WorkTypeId) && accountWorkTypeMap.containskey(wrkOdr.AccountId)){
                for(String str:workTypeIdMap.get(wrkOdr.WorkTypeId)){
                    if(accountWorkTypeMap.get(wrkOdr.AccountId).contains(str)){
                        wrkOdr.Previous_Appointment__c = true;
                    }
                }
                
            }
            
        }
        
    }
    
    //Method to trigger custom notification by comparing ProductsRequired and ProductsConsumed
    public static void handleNotification(List<WorkOrder> newWorkOrders, Map<Id, WorkOrder> oldMap) {
        try{
            
            Set<Id> requiredProductIds = new Set<Id>();
            Set<Id> consumedProductIds = new Set<Id>();
            List<ProductConsumed> productConsumedList = [SELECT Id FROM ProductConsumed WHERE WorkOrderId IN: newWorkOrders];
            for (ProductConsumed pc : productConsumedList) {
                consumedProductIds.add(pc.Id);
            }
            List<ProductRequired> productRequiredList = [SELECT Id FROM ProductRequired WHERE ParentRecordId IN: newWorkOrders];
            for (ProductRequired pr : productRequiredList) {
                requiredProductIds.add(pr.Id);
            }
            List<WorkOrder> wosToUpdate = new List<WorkOrder>();
            for (WorkOrder wo : newWorkOrders) {
                if (wo.Status == 'Complete' && oldMap.get(wo.Id).Status != 'Complete') {
                    Boolean checkVariable = requiredProductIds.equals(consumedProductIds);
                    if (checkVariable == false) {
                        wo.Notification_check__c = true;
                    } else {
                        wo.Notification_check__c = false;
                    }
                    wosToUpdate.add(wo);
                }
            }
        }
        catch (Exception ex) {
            ExceptionUtil.publishException('PV_WorkOrderTriggerHandler.handleNotification', ex.getLineNumber(), ex.getMessage(), ex.getStackTraceString());
        }
    }
    public static void handleAfterUpdate(List<WorkOrder> newWorkOrders, Map<Id, WorkOrder> oldMap) {
        try{
            List<Id> pendingToCompleteWorkOrderIds = new List<Id>();
            
            for (WorkOrder newWo : newWorkOrders) {
                WorkOrder oldWo = oldMap.get(newWo.Id);
                
                // Check if the vendor type is T-Mobile
                if (newWo.Vendor__c != 'T-Mobile') {
                    continue; 
                }
                
                if (oldWo.Status == 'Pending Complete' && newWo.Status == 'Complete') {
                    pendingToCompleteWorkOrderIds.add(newWo.Id);
                }
            }
            
            if (!pendingToCompleteWorkOrderIds.isEmpty()) {
                generatePDFAndSaveAsAttachment(pendingToCompleteWorkOrderIds);
            }
        }
        catch (Exception ex) {
            ExceptionUtil.publishException('PV_WorkOrderTriggerHandler.handleAfterUpdate', ex.getLineNumber(), ex.getMessage(), ex.getStackTraceString());
        }
    }
    
    
    @Future(callout=true)
    public static void generatePDFAndSaveAsAttachment(List<Id> workOrderIds) {
        try {
             String owaEmail = System.Label.PV_OWA_Notification;
            List<String> toEmailAddress = new List<String>();
            List<ServiceReport> contentVersion = new  List<ServiceReport>();
            List<WorkOrder> workOrders = [
                SELECT
                    Id,
                    External_WO_Id__c,
                    Work_Type_Code_tmo__c,
                    WorkType.Name,
                    Account.Name,
                    WorkType.Site_Survey_Allowed_For_Closeout__c,
                    WorkType.Site_Survey_Report_Id__c
                FROM WorkOrder
                WHERE Id IN :workOrderIds
            ];
            
            OrgWideEmailAddress owa = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :owaEmail LIMIT 1];
            List<Attachment>attachments = new List<Attachment>();
            List<Messaging.EmailFileAttachment> efalist = new List<Messaging.EmailFileAttachment>();
            String AccountName = workOrders[0].Account.Name;
            
            for (PV_FSL_Config__mdt config : [SELECT MasterLabel, Value__c FROM PV_FSL_Config__mdt WHERE Type__c = 'Email']) {
                toEmailAddress.addAll(config.Value__c.split(','));
            }
            
            if (workOrders[0].WorkType.Site_Survey_Allowed_For_Closeout__c) {
                String siteSurveyReportId = String.isNotBlank(workOrders[0].WorkType.Site_Survey_Report_Id__c)
                    ? workOrders[0].WorkType.Site_Survey_Report_Id__c
                    : PV_FSL_Config__mdt.getInstance('Site_Survey_Report_Id').Value__c;
                contentVersion = [
                    SELECT Id, ServiceReportNumber, ParentId, DocumentContentType, DocumentBody 
                    FROM ServiceReport
                    WHERE Template LIKE :'%' + siteSurveyReportId + '%'
                        AND ParentId IN :workOrderIds
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];
            } else {
                contentVersion = [
                    SELECT Id, ServiceReportNumber, ParentId, DocumentContentType, DocumentBody 
                    FROM ServiceReport
                    WHERE Template LIKE :'%' + PV_FSL_Config__mdt.getInstance('Service_Report_Id').Value__c + '%'
                        AND ParentId IN :workOrderIds
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];
            }
            
            if (!contentVersion.isEmpty()) {
                for (ServiceReport cv : contentVersion) {
                    Messaging.EmailFileAttachment emailAttachmentReport = new Messaging.EmailFileAttachment();
                    emailAttachmentReport.setFileName(cv.ServiceReportNumber + '.pdf');
                    emailAttachmentReport.setContentType('application/pdf');
                    emailAttachmentReport.setBody(cv.DocumentBody);
                    
                    efalist.add(emailAttachmentReport);
                }
                
                for (WorkOrder wo : workOrders) {
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setSubject('Close Out Package ' + wo.External_WO_Id__c + ' for ' + AccountName);
                    email.setToAddresses(toEmailAddress); 
                    email.setOrgWideEmailAddressId(owa.Id);
                    emailBody = String.format(emailBody, new List<String>{wo.External_WO_Id__c, wo.Work_Type_Code_tmo__c});
                    email.setPlainTextBody(emailBody);
                    email.setFileAttachments(efalist);
                    
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
                }
            }
        }
        
        catch (Exception ex) {
            ExceptionUtil.publishException('PV_WorkOrderTriggerHandler.generatePDFAndSaveAsAttachment', ex.getLineNumber(), ex.getMessage(), ex.getStackTraceString());
        }
    } 

    public static void immediateDealerAssignment(List<WorkOrder> workOrders) {

        FSL_Settings__c settings = FSL_Settings__c.getOrgDefaults();
        Integer Availability_Period = Integer.valueOf(settings.Availability_Period__c) > 0 ? Integer.valueOf(settings.Availability_Period__c): 7;

        Date Availability_Period_Date = date.today().addDays(Availability_Period);
        
        Map<String, String> typePerWO = new Map<String, String>();
        Map<String, Set<String>> DealersTerritories = new Map<String, Set<String>>();
        Map<String, Set<String>> territoriesPerParent = new Map<String, Set<String>>();
        Map<String, Set<String>> skillsPerWO = new Map<String, Set<String>>();
        Map<String, Set<String>> resourcesPerDealer = new Map<String, Set<String>>();
        Map<String, Set<String>> skillsPerResource = new Map<String, Set<String>>();
        Map<String, String> ChildTerritoriesAndDealers = new Map<String, String>();

        Map<String, ShiftWrapper> shiftsPerResource = new Map<String, ShiftWrapper>();
        Map<String, AppointmentWrapper> appointmentsPerResource = new Map<String, AppointmentWrapper>();

        //Iterates new work orders to get data needed for quering relevant records (workTypes, Skills and territories)
        for(WorkOrder order : workOrders) {
            if(order.Assign_to_Dealer_Immediately__c) {
                if(order.ServiceTerritoryId != null) {
                    territoriesPerParent.put(order.ServiceTerritoryId, new Set<String>());
                }
                skillsPerWO.put(order.Id, new Set<String>());
                typePerWO.put(order.WorkTypeId ,order.Id);
            }

        }

        //Queries and group the skills required for each work order
        for(SkillRequirement skill : [SELECT Id, SkillId, RelatedRecordId FROM SkillRequirement WHERE RelatedRecordId IN: typePerWO.keySet()]) {
            skillsPerWO.get(typePerWO.get(skill.RelatedRecordId)).add(skill.SkillId);
        }

        //Queries and group all child territories with the correspondant dealers
        for(ServiceTerritory territory : [SELECT Id, Account__c, ParentTerritoryId FROM ServiceTerritory WHERE ParentTerritoryId IN :territoriesPerParent.keySet() AND IsActive = true]) {
            territoriesPerParent.get(territory.ParentTerritoryId).add(territory.Id);
            if(!DealersTerritories.keySet().contains(territory.Account__c)) {
                DealersTerritories.put(territory.Account__c, new Set<String>());
            }
            DealersTerritories.get(territory.Account__c).add(territory.Id);
            ChildTerritoriesAndDealers.put(territory.Id, territory.Account__c);

        }

        //Queries and group all service resources with the correspondant dealers
        for(ServiceResource resource : [SELECT id, Name, AccountId FROM ServiceResource WHERE AccountId IN :DealersTerritories.keySet() AND IsActive = true]) {
            if (!resourcesPerDealer.keySet().contains(resource.AccountId)) {
                resourcesPerDealer.put(resource.AccountId, new Set<String>());   
            }
            resourcesPerDealer.get(resource.AccountId).add(resource.Id);
            skillsPerResource.put(resource.Id, new Set<String>());
        }

        ////Queries and group all service resource skills with the correspondant service resource
        for(ServiceResourceSkill skill : [SELECT Id, ServiceResourceId, SkillId FROM ServiceResourceSkill WHERE ServiceResourceId IN :skillsPerResource.keySet()]) {
            skillsPerResource.get(skill.ServiceResourceId).add(skill.SkillId);
        }

        //Queries and group all shifts with its correspondant service resource and calculates the sum of shift hours between today and the availability period
        for (Shift shift : [SELECT Id, StartTime, EndTime, ServiceResourceId FROM Shift WHERE StartTime >= TODAY  AND Status = 'Confirmed' AND ServiceResourceId IN: skillsPerResource.keySet()]) {
            if(shift.StartTime.date() <= Availability_Period_Date) {
                if(!shiftsPerResource.keySet().contains(shift.ServiceResourceId)) {
                    ShiftWrapper newWrapper = new ShiftWrapper();
                    newWrapper.shiftList = new List<Shift>();
                    newWrapper.hours = 0;
                    shiftsPerResource.put(shift.ServiceResourceId, newWrapper);
                }
                
                Long difference = shift.EndTime.getTime() - shift.StartTime.getTime();
                Integer hours = Integer.ValueOf(difference / 3600000);
                
                shiftsPerResource.get(shift.ServiceResourceId).hours = shiftsPerResource.get(shift.ServiceResourceId).hours + hours;
                shiftsPerResource.get(shift.ServiceResourceId).shiftList.add(shift);
                
                
            }
        }

        //Queries and group all service appointments with its correspondant service resource and calculates the sum of service appointment hours between today and the availability period
        for(ServiceAppointment appointment : [SELECT id,
                                                     FSSK__FSK_Assigned_Service_Resource__c, 
                                                     SchedEndTime, 
                                                     SchedStartTime 
                                                     FROM ServiceAppointment 
                                                     WHERE FSSK__FSK_Assigned_Service_Resource__c IN: skillsPerResource.keySet()
                                                     AND SchedStartTime >= TODAY
                                                     AND Status = 'Scheduled']) 
        {
            if(appointment.SchedStartTime.date() <= Availability_Period_Date) {
                if(!appointmentsPerResource.keySet().contains(appointment.FSSK__FSK_Assigned_Service_Resource__c)) {
                    AppointmentWrapper newWrapper = new AppointmentWrapper();
                    newWrapper.appointmentList = new List<ServiceAppointment>();
                    newWrapper.hours = 0;
                    appointmentsPerResource.put(appointment.FSSK__FSK_Assigned_Service_Resource__c, newWrapper);
                }
                
                Long difference = appointment.SchedEndTime.getTime() - appointment.SchedStartTime.getTime();
                Integer hours = Integer.ValueOf(difference / 3600000);

                appointmentsPerResource.get(appointment.FSSK__FSK_Assigned_Service_Resource__c).hours = appointmentsPerResource.get(appointment.FSSK__FSK_Assigned_Service_Resource__c).hours + hours;
                appointmentsPerResource.get(appointment.FSSK__FSK_Assigned_Service_Resource__c).appointmentList.add(appointment);
            }

        }

        //for each work order, calculates the availability balance per dealer depending on territory and skills required, and updates the dealer__c value to the most adequate dealer
        for(WorkOrder order : workOrders) {
            if(order.Assign_to_Dealer_Immediately__c && order.ServiceTerritoryId != null) {

                double bestBalance = 0;
                String winningDealer = null;

                Integer shiftsHours = 0;
                Integer appointmentHours = 0;
                Integer numberOfResources = 0;
                Set<String> childTerrirtories = territoriesPerParent.get(order.ServiceTerritoryId);
                Set<String> possibleDealers = new Set<String>();
                Set<String> possibleResources = new Set<String>();
                for (String territoryId : childTerrirtories) {
                    possibleDealers.add(ChildTerritoriesAndDealers.get(territoryId));
                }
                for(String resourceId : skillsPerResource.keySet()) {
                    if(skillsPerResource.get(resourceId).containsAll(skillsPerWO.get(order.Id))) {
                        possibleResources.add(resourceId);
                    }
                }

                for(String dealerId : possibleDealers) {
                    Double balance = 0;
                    Set<String> DealerResourcesIds = resourcesPerDealer.get(dealerId);
                    if(DealerResourcesIds != null) {
                        for(String resourceId : DealerResourcesIds) {
                            if(possibleResources.contains(resourceId)) {
                                numberOfResources ++;
                                if(shiftsPerResource.get(resourceId) != null){
                                    shiftsHours = shiftsHours + shiftsPerResource.get(resourceId).hours;
                                }
                                if (appointmentsPerResource.get(resourceId) != null) {
                                    appointmentHours = appointmentHours + appointmentsPerResource.get(resourceId).hours;
                                }
                            }
                        }
    
                        if(numberOfResources > 0){
                            balance = (shiftsHours - appointmentHours) / numberOfResources;
                        }
                        if(balance > bestBalance) {
                            bestBalance = balance;
                            winningDealer = dealerId;
                        }
                    }
                    
                }

                if(winningDealer != null){
                    order.Dealer__c = winningDealer;
                }       
            }
        }
    }

    public static void calculateDaysSinceInstallation(List<WorkOrder> workOrders) {
        List<WorkOrder> serviceCallWorkOrders = new List<WorkOrder>();

        Set<Id> workTypeIds = new Set<Id>();
        for (WorkOrder wo : workOrders) {
            if (wo.WorkTypeId != null) {
                workTypeIds.add(wo.WorkTypeId);
            }
        }

        Map<Id, WorkType> workTypeMap = new Map<Id, WorkType>();
        if (!workTypeIds.isEmpty()) {
            for (WorkType wt : [
                SELECT Id, Type__c
                FROM WorkType
                WHERE Id IN :workTypeIds
            ]) {
                workTypeMap.put(wt.Id, wt);
            }
        }

        Set<String> addressKeys = new Set<String>();
        Map<String, List<WorkOrder>> addressToWorkOrdersMap = new Map<String, List<WorkOrder>>();

        for (WorkOrder wo : workOrders) {
            if (wo.WorkTypeId != null && workTypeMap.containsKey(wo.WorkTypeId) && 
                    workTypeMap.get(wo.WorkTypeId).Type__c == 'Service Call') {

                serviceCallWorkOrders.add(wo);

                String addressKey = wo.Vendor__c + '|' + wo.Street + '|' + wo.City + '|' +
                                   wo.State + '|' + wo.Country + '|' + wo.PostalCode;
                addressKeys.add(addressKey);

                if (!addressToWorkOrdersMap.containsKey(addressKey)) {
                    addressToWorkOrdersMap.put(addressKey, new List<WorkOrder>());
                }
                addressToWorkOrdersMap.get(addressKey).add(wo);
            }
        }

        if (serviceCallWorkOrders.isEmpty()) {
            return;
        }

        Set<String> vendors = new Set<String>();
        Set<String> streets = new Set<String>();
        Set<String> cities = new Set<String>();
        Set<String> states = new Set<String>();
        Set<String> countries = new Set<String>();
        Set<String> postalCodes = new Set<String>();

        for (WorkOrder wo : serviceCallWorkOrders) {
            vendors.add(wo.Vendor__c);
            streets.add(wo.Street);
            cities.add(wo.City);
            states.add(wo.State);
            countries.add(wo.Country);
            postalCodes.add(wo.PostalCode);
        }

        Map<String, WorkOrder> addressToPreviousWorkOrderMap = new Map<String, WorkOrder>();
        for (WorkOrder wo : [
            SELECT Id, CreatedDate, Vendor__c, Street, City, State, Country, PostalCode
            FROM WorkOrder
            WHERE Vendor__c IN :vendors
            AND Street IN :streets
            AND City IN :cities
            AND State IN :states
            AND Country IN :countries
            AND PostalCode IN :postalCodes
            ORDER BY CreatedDate DESC
        ]) {
            String addressKey = wo.Vendor__c + '|' + wo.Street + '|' + wo.City + '|' +
                                wo.State + '|' + wo.Country + '|' + wo.PostalCode;

            if (addressKeys.contains(addressKey) && !addressToPreviousWorkOrderMap.containsKey(addressKey)) {
                addressToPreviousWorkOrderMap.put(addressKey, wo);
            }
        }

        Set<Id> previousWorkOrderIds = new Set<Id>();
        for (WorkOrder previousWO : addressToPreviousWorkOrderMap.values()) {
            previousWorkOrderIds.add(previousWO.Id);
        }

        Map<Id, List<WorkOrderHistory>> workOrderToHistoryMap = new Map<Id, List<WorkOrderHistory>>();
        if (!previousWorkOrderIds.isEmpty()) {
            for (WorkOrderHistory history : [
                SELECT Id, CreatedDate, NewValue, WorkOrderId
                FROM WorkOrderHistory
                WHERE WorkOrderId IN :previousWorkOrderIds
                AND Field = 'Status'
                ORDER BY WorkOrderId, CreatedDate DESC
            ]) {
                if (!workOrderToHistoryMap.containsKey(history.WorkOrderId)) {
                    workOrderToHistoryMap.put(history.WorkOrderId, new List<WorkOrderHistory>());
                }
                workOrderToHistoryMap.get(history.WorkOrderId).add(history);
            }
        }

        for (WorkOrder wo : serviceCallWorkOrders) {
            String addressKey = wo.Vendor__c + '|' + wo.Street + '|' + wo.City + '|' +
                               wo.State + '|' + wo.Country + '|' + wo.PostalCode;

            if (addressToPreviousWorkOrderMap.containsKey(addressKey)) {
                WorkOrder previousWO = addressToPreviousWorkOrderMap.get(addressKey);

                if (workOrderToHistoryMap.containsKey(previousWO.Id)) {
                    List<WorkOrderHistory> statusHistory = workOrderToHistoryMap.get(previousWO.Id);

                    for (WorkOrderHistory history : statusHistory) {
                        if (String.valueOf(history.NewValue) == 'Pending Complete') {
                            wo.Days_since_Installation__c = (System.now().getTime() - history.CreatedDate.getTime()) / (1000 * 60 * 60 * 24);
                            break;
                        }
                    }
                }
            }
        }
    }

    public class ShiftWrapper {
        public Integer hours;
        public List<Shift> shiftList;
    }

    public class AppointmentWrapper {
        public Integer hours;
        public List<ServiceAppointment> appointmentList;
    }
}
/**
* @description       :Queueable Class for Creating STM 
* @author            : Impaqtive DevTeam
* @last modified on  : 11-05-2023
* @last modified by  : Impaqtive DevTeam
* Modifications Log
* Ver   Date         Author            	   Modification
* 1.0   11/05/2023   Impaqtive DevTeam     Initial Version
**/
public class PV_CreateSRandSTMQueueable  implements Queueable{
    User user=new User();
    String ResourceType;
    Contact contact;
    list<String> skillList;
    Date skilStartDate;
    Date directvExpiry;
    Date viasatExpiry;
    id paid;
    List<Shift> shiftsToCreate;
    String browserTimeZone;
    list<PV_ManageServiceResources.ServiceTerritoryMembership> stmlist =new list<PV_ManageServiceResources.ServiceTerritoryMembership>();
    public PV_CreateSRandSTMQueueable(User us, String Resource,Contact contact,list<PV_ManageServiceResources.ServiceTerritoryMembership> stmlist,
                                      List<String> skillList, Date skilStartDate,Date directvExpiry,Date viasatExpiry,id paid, List<Shift> shiftsToCreate, String browserTimeZone){
                                          this.user=us;
                                          this.ResourceType=Resource;
                                          this.contact=contact;
                                          this.stmlist=stmlist;
                                          this.skillList = skillList;
                                          this.skilStartDate = skilStartDate;
                                          this.directvExpiry =directvExpiry;
                                          this.viasatExpiry = viasatExpiry;
                                          this.paid=paid;
                                          this.shiftsToCreate = shiftsToCreate;
                                          this.browserTimeZone = browserTimeZone;
                                      }
    public void execute(QueueableContext context) {
        
        List<ServiceTerritoryMember> stms=new List<ServiceTerritoryMember>();
        List<ContentDocumentLink> cLink=new List<ContentDocumentLink>();
        ServiceResource sr = new ServiceResource();
        sr.RelatedRecordId = user.id;
        sr.Name = contact.FirstName+' '+contact.LastName;
        sr.Contact__c = contact.Id;
        sr.AccountId=contact.AccountId;
        sr.IsActive = true;
        /*sr.Address__City__s=contact.MailingCity;
        sr.Address__StateCode__s=contact.MailingState;
        sr.Address__Street__s=contact.MailingStreet;
        sr.Address__PostalCode__s=contact.MailingPostalCode;*/
        sr.ResourceType = 'T';/*resourceType.contains('Dispatcher')?'T':'D';*/
        sr.Is_Dispatcher_and_Technician__c =  resourceType.contains('Dispatcher')? true:false;
        sr.Background_Check_Date__c = contact.Background_Check_Date__c;
        sr.Drug_Screen_Date__c = contact.Drug_Screen_Date__c;
        sr.IsOptimizationCapable = contact.Include_in_Scheduling_Optimization__c;
        sr.ID_DirecTV__c = contact.ID_DirecTV__c;
        sr.ID_Viasat__c = contact.ID_Viasat__c;
        sr.ID_Servicebench__c = contact.ID_Servicebench__c;
        sr.Vendor_Type__c = contact.Vendor_Type__c;
        sr.DIRECTV_Expiration__c = directvExpiry;
        sr.Viasat_Expiration__c = viasatExpiry;
        sr.Manager__c=contact.Manager__c;
        //sr.Approved_by_PerfectVision__c = pa.Approved_by_PerfectVision__c;
        sr.Approved_by_PerfectVision__c = System.today();
        try{
            insert sr;

            if(!skillList.IsEmpty()){
                assignSkillForSR(sr.Id,skillList,skilStartDate);
            }
            if(paid!=null){
                 for(ContentDocumentLink  cdlink:[SELECT ContentDocumentId, LinkedEntityId  FROM ContentDocumentLink where LinkedEntityId =:paid]){
                ContentDocumentLink cdl=new ContentDocumentLink();
                cdl.LinkedEntityId = sr.Id;
                cdl.ContentDocumentId = cdlink.ContentDocumentId;
                cdl.shareType = 'V';
                cLink.add(cdl);
            }
            insert cLink;
            }
           
            
        }catch (Exception ex) {
            system.debug('from SR>>>'+ex.getMessage());
            ExceptionUtil.publishException('PV_CreateSRandSTMQueueable', ex.getLineNumber(), ex.getMessage(), ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
        
        if(resourceType.contains('Technician')){
            list<DateTime> starDateList = new List<DateTime>();
            
            
            for(PV_ManageServiceResources.ServiceTerritoryMembership stmclass:stmlist ){
                
                
                ServiceTerritoryMember stmrecord=new ServiceTerritoryMember();
                stmrecord.ServiceResourceId=sr.id;
                stmrecord.ServiceTerritoryId=stmclass.TerritoryId;
                if(stmclass.TerritoryType=='Primary'){
                    stmrecord.TerritoryType='P';
                    stmrecord.Street=contact.MailingStreet;
                    stmrecord.City=contact.MailingCity;
                    stmrecord.StateCode=contact.MailingStateCode;
                    stmrecord.CountryCode=contact.MailingCountryCode;
                    stmrecord.PostalCode=contact.MailingPostalCode;
                }else{
                    stmrecord.TerritoryType='S';
                }
                
                Date myDate = Date.valueOf(stmclass.StartDate);	
                Time myTime = Time.newInstance(0,0,0,0);
                DateTime dt = DateTime.newInstance(myDate, myTime);    
                stmrecord.EffectiveStartDate=dt;
                
                
                stms.add(stmrecord);
            }
            
            system.debug(stms);
            if(!stms.IsEmpty()){
                try{
                    insert stms;

                    System.debug('ShiftsToCreate: ' + shiftsToCreate);

                    Map<Id, String> timezonesByTerritoryId = new Map<Id, String>();
                    for (ServiceTerritory territory : [SELECT Id, OperatingHoursId, OperatingHours.TimeZone FROM ServiceTerritory WHERE IsActive = TRUE]) {
                        timezonesByTerritoryId.put(territory.Id, territory.OperatingHours.TimeZone);
                    }

                    if(shiftsToCreate.size() > 0){
                         for(Shift shiftToUpdate : shiftsToCreate) {

                            if(timezonesByTerritoryId.get(shiftToUpdate.ServiceTerritoryId) != null && browserTimeZone != ''){ 
                                TimeZone userTimeZone = UserInfo.getTimeZone();
                                TimeZone targetTimeZone = TimeZone.getTimeZone(timezonesByTerritoryId.get(shiftToUpdate.ServiceTerritoryId));
                                TimeZone browserZone = TimeZone.getTimeZone(browserTimeZone);

                                shiftToUpdate.StartTime = calculateHoursDiference(shiftToUpdate.StartTime, browserZone, userTimeZone);
                                shiftToUpdate.EndTime = calculateHoursDiference(shiftToUpdate.EndTime, browserZone, userTimeZone);

                                shiftToUpdate.StartTime = calculateHoursDiference(shiftToUpdate.StartTime, userTimeZone, targetTimeZone);
                                shiftToUpdate.EndTime = calculateHoursDiference(shiftToUpdate.EndTime, userTimeZone, targetTimeZone);

                            }
                            shiftToUpdate.ServiceResourceId = sr.id;
                            shiftToUpdate.Status = 'Confirmed';
                        }

                        upsert shiftsToCreate;

                        //run createShiftsInAdvance
                        FSL_Settings__c settings = FSL_Settings__c.getOrgDefaults();
                        Integer weekStart = Integer.valueOf(settings.Shifts_First_Day_of_the_Week__c);
                        Integer weeksInAdvance = Integer.valueOf(settings.Shift_Weeks_In_Advance__c);
                        List<Shift> futureShiftsToCreate = ShiftsCreationInAdvanceBatch.generateShiftsInAdvance(shiftsToCreate, weekStart, weeksInAdvance);

                        System.debug('futureShiftsToCreate: ' + futureShiftsToCreate);
                        insert futureShiftsToCreate;
                    }
                   
                } catch (Exception ex) {
                    system.debug('from STMS && SHIFTS>>>'+ex.getMessage());
                    ExceptionUtil.publishException('PV_CreateSRandSTMQueueable', ex.getLineNumber(), ex.getMessage(), ex.getStackTraceString());
                    throw new AuraHandledException(ex.getMessage());
                }
            }    
        }
        
    }
    public static void assignSkillForSR(String srId,List<String> skillList, Date skilStartDate){
        List<skill> skillToCreate = [SELECT Id,DeveloperName FROM skill where DeveloperName IN:skillList];
        Time inputTime = Time.newInstance(00, 00, 0,0);
        Datetime dateTimeWithTime = Datetime.newInstance(skilStartDate, inputTime);
        List<ServiceResourceSkill> srSkillNeedsToCreate = new List<ServiceResourceSkill>();
        for(skill skl:skillToCreate){
            ServiceResourceSkill srSkill = new ServiceResourceSkill();
            srSkill.ServiceResourceId = srId;
            srSkill.SkillId = skl.Id;
            srSkill.SkillLevel=50;
            srSkill.EffectiveStartDate = dateTimeWithTime;
            srSkillNeedsToCreate.add(srSkill);
        }
        
        if(!srSkillNeedsToCreate.IsEmpty()){
            try{
                Insert srSkillNeedsToCreate;
            }catch(Exception ex){
                ExceptionUtil.publishException('PV_CreateSRandSTMQueueable', ex.getLineNumber(), ex.getMessage(), ex.getStackTraceString());
                throw new AuraHandledException(ex.getMessage());
            }
            
        }   
    }
    
    public static DateTime calculateHoursDiference (DateTime startDate, TimeZone timeZone1, TimeZone timeZone2) {

        Integer offset1 = timeZone1.getOffset(startDate);
        Integer offset2 = timeZone2.getOffset(startDate);
                                    
        Integer offsetDifferenceInSeconds = (offset1 - offset2) / 1000;
        Integer offsetDifferenceInHours = offsetDifferenceInSeconds/3600;
                                    
        System.debug('offsetDifferenceInSeconds: ' + offsetDifferenceInSeconds/3600);

        DateTime returnDate = startDate.addHours(offsetDifferenceInHours);

        return returnDate;

    }
}
public without sharing class PV_ManageServiceResources {
    public static final String PV_BUSINESS_UNIT = System.Label.FSL_PV_Business_Unit;

    @AuraEnabled(cacheable=true)
    public static List<Contact> getRelatedContacts(Id accountId) {
        return [
            SELECT  Id, Name, FirstName, LastName, Email, Phone, SR_Resource__c, Background_Check_Date__c, Drug_Screen_Date__c, Include_in_Scheduling_Optimization__c 
            FROM    Contact
            WHERE   accountId = :accountId
            AND     (Resource_Type__c = 'Dispatcher' OR Resource_Type__c = 'Dispatcher and Technician')
            AND     Status__c = 'Active'
        ];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<User> getManager(Id accountId) {
        List<User> userList = [
            SELECT  id,Name 
            FROM    User 
            WHERE   ContactId IN (Select Id from Contact where AccountId = :AccountId
            AND     (Resource_Type__c = 'Dispatcher' OR Resource_Type__c = 'Dispatcher and Technician'))
        ]; 
        return userList;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getPickValues() {
        List<String> picklistValues = new List<String>();        
        picklistValues.add('Dispatcher');
        picklistValues.add('Technician');
        picklistValues.add('Dispatcher and Technician');
        
        return picklistValues;
    }

    @AuraEnabled(cacheable=false)
    public static List<String> getValues(String objectName,String fieldName, String accountId) {
        List<String> VendorValues = new List<String>();
        Schema.SObjectType s = Schema.getGlobalDescribe().get(objectName) ;
        Schema.DescribeSObjectResult r = s.getDescribe() ;
        Map<String,Schema.SObjectField> fields = r.fields.getMap() ;
        Schema.DescribeFieldResult fieldResult = fields.get(fieldName).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for (Schema.PicklistEntry pickListVal : ple) {
            VendorValues.add(pickListVal.getValue());
        }

        if (fieldName == 'Vendor_Type__c' && accountId != null) {
            Account acc = [SELECT Id, Available_FSL_Vendors__c FROM Account WHERE Id = :accountId LIMIT 1];
            if (acc.Available_FSL_Vendors__c != null) {
                VendorValues = acc.Available_FSL_Vendors__c.split(';');
            } else {
                VendorValues = new List<String>();
            }
        }
        return VendorValues;
    }

    @AuraEnabled(cacheable=false)
    public static List<Skill> getskill(List<String> vendorSkills) {
        List<SkillType> skillTypes = [SELECT Id, MasterLabel FROM SkillType WHERE MasterLabel IN :vendorSkills];
        List<String> vendorTypes = new List<String>();
        
        for (SkillType stype : skillTypes) {
            vendorTypes.add(stype.Id);
        }
        
        return [Select MasterLabel, DeveloperName from Skill WHERE TypeId IN :vendorTypes ORDER BY MasterLabel ASC];  
    }
    
    // Timezone method
    public static List<String> getTimzonePickListValues() {
        List<String> pickListValuesList = new List<String>();
        Schema.DescribeFieldResult fieldResult = Contact.Time_zone__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry pickListVal : ple ) {
            pickListValuesList.add(pickListVal.getLabel());
        }     
        return pickListValuesList;
    }
    
    @AuraEnabled
    public static String submitForApprovalOrSRCreation(
        Contact partnerContact, String resourceType, String stMembership,List<String> skillList, Date startDate,
        date viasatExpiry, date directvExpiry,String profilepic,id approvalid,String imgurl, List<Shift> shifts, String browserTimeZone) {
                                                           
        if (String.isBlank(resourceType)) {
            throw new AuraHandledException('Please choose a resource type.');
        }

        Account account = [SELECT Id, Name, Business_Unit__c FROM Account WHERE Id = :partnerContact.AccountId];

        String userProfile = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
        List<string> approvalRequiredProfiles = PV_FSL_Config__mdt.getInstance('SR_Approval_Requied_Profile').Value__c.split(',');

        Permission_Set_Assignment__mdt permissions = [
            SELECT  Permission_Sets__c, Profile__c, Resource_Type__c
            FROM    Permission_Set_Assignment__mdt
            WHERE   Resource_Type__c = :ResourceType
            AND     Business_Unit__c = :account.Business_Unit__c
            LIMIT 1
        ];

        Map<Id, String> timezonesByTerritoryId = new Map<Id, String>();
        for (ServiceTerritory territory : [SELECT Id, OperatingHoursId, OperatingHours.TimeZone FROM ServiceTerritory WHERE IsActive = TRUE]) {
            timezonesByTerritoryId.put(territory.Id, territory.OperatingHours.TimeZone);
        }
        
        if (approvalRequiredProfiles.contains(userProfile) && account.Business_Unit__c == PV_BUSINESS_UNIT) {
            try {
                String commaSepratedSkill = '';
                for (String str:skillList) {
                    commaSepratedSkill += str + ',';
                }
                
                Process_Approval__c pa = new Process_Approval__c();
                Id rtId = [SELECT Id FROM RecordType WHERE SobjectType = 'Process_Approval__c' AND Name = 'Service Resource Approval' LIMIT 1].Id;
                pa.RecordTypeId = rtId;
                pa.Resource_Type__c = resourceType;
                pa.Background_Check_Date__c = partnerContact.Background_Check_Date__c;
                pa.Drug_Screen_Date__c = partnerContact.Drug_Screen_Date__c;
                pa.Service_memberships__c = stMembership;
                pa.Skill__c = commaSepratedSkill;
                pa.Skill_Start_Date__c = startDate;
                pa.Include_in_Scheduling_Optimization__c = partnerContact.Include_in_Scheduling_Optimization__c;
                pa.First_Name__c = partnerContact.FirstName;
                pa.Last_Name__c = partnerContact.LastName;

                if (profilepic!=null && !Test.isRunningTest()) {
                    pa.Resource_Image__c='<img alt="Candidate" src="data:image/jpeg;base64,' +profilepic + '" width="250" height="250"></img>';
                }

                pa.Account__c = partnerContact.AccountId;
                pa.Email__c = partnerContact.Email;
                pa.Phone__c = partnerContact.Phone;
                pa.Time_Zone__c = partnerContact.Time_zone__c;
                pa.Vendor_Type__c = partnerContact.Vendor_Type__c;
                pa.DIRECTV_Expiration__c = directvExpiry;
                pa.Viasat_Expiration__c = viasatExpiry;            
                pa.MailingStreet__c = partnerContact.Mailingstreet;
                pa.MailingCity__c = partnerContact.Mailingcity;
                pa.MailingState__c = partnerContact.MailingstateCode;
                pa.MailingPostalCode__c = partnerContact.MailingpostalCode;
                pa.MailingCountry__c = partnerContact.MailingcountryCode;
                pa.Manager__c=partnerContact.Manager__c;
                pa.ID_DirecTV__c = partnerContact.ID_DirecTV__c;
                pa.ID_Servicebench__c = partnerContact.ID_Servicebench__c;
                insert pa;

                if (shifts.size() > 0) {
                    for (Shift shiftToUpdate : shifts) {
                        if (timezonesByTerritoryId.get(shiftToUpdate.ServiceTerritoryId) != null && browserTimeZone != '') {
                            TimeZone userTimeZone = UserInfo.getTimeZone();
                            TimeZone targetTimeZone = TimeZone.getTimeZone(timezonesByTerritoryId.get(shiftToUpdate.ServiceTerritoryId));
                            TimeZone browserZone = TimeZone.getTimeZone(browserTimeZone);

                            shiftToUpdate.StartTime = calculateHoursDiference(shiftToUpdate.StartTime, browserZone, userTimeZone);
                            shiftToUpdate.EndTime = calculateHoursDiference(shiftToUpdate.EndTime, browserZone, userTimeZone);

                            shiftToUpdate.StartTime = calculateHoursDiference(shiftToUpdate.StartTime, userTimeZone, targetTimeZone);
                            shiftToUpdate.EndTime = calculateHoursDiference(shiftToUpdate.EndTime, userTimeZone, targetTimeZone);
                        }
                        shiftToUpdate.Process_Approval__c = pa.id;
                    }
                    insert shifts;

                    // Run createShiftsInAdvance
                    FSL_Settings__c settings = FSL_Settings__c.getOrgDefaults();
                    Integer weekStart = Integer.valueOf(settings.Shifts_First_Day_of_the_Week__c);
                    Integer weeksInAdvance = Integer.valueOf(settings.Shift_Weeks_In_Advance__c);
                    List<Shift> futureShiftsToCreate = ShiftsCreationInAdvanceBatch.generateShiftsInAdvance(shifts, weekStart, weeksInAdvance);
                    insert futureShiftsToCreate;
                }
                
                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                req.setObjectId(pa.Id);
                req.setProcessDefinitionNameOrId('PV_Approval_Contact');
                req.setSkipEntryCriteria(false);
                Approval.ProcessResult result = Approval.process(req);
                return 'Approval-'+pa.id;
            } catch (Exception e) {
                ExceptionUtil.publishFSLException('Internal Error', 'FSL', PV_ManageServiceResources.class.getName(), e.getMessage());
                throw new AuraHandledException(e.getMessage());
            }
        }
        else {
            Blob blobImage;
            try {
                User newUser = new User();
                List<Contact> conList = [SELECT Id,FirstName,LastName,Email,Time_zone__c,AccountId,Resource_Type__c FROM contact where email=:partnerContact.Email and AccountId=:partnerContact.AccountId];
                
                if (conList.size() > 0) {
                    List<User> userList = [SELECT id,Profile.Name,IsActive, UserRole.Name FROM user where ContactId=:conList[0].Id];

                    if (userList.size() > 0) {
                        if (userList[0].Profile.Name == permissions.Profile__c) {     
                            if((ResourceType  == 'Dispatcher' || ResourceType == 'Dispatcher and Technician') && userList[0].UserRole.Name != account.Name + ' '+'Partner Manager') {
                                insert partnerContact;
                                newUser = createUser(partnerContact,permissions);
                            }
                            else if (ResourceType == 'Technician' && userList[0].UserRole.Name != account.Name + ' '+'Partner User') {
                                insert partnerContact;
                                newUser = createUser(partnerContact,permissions);
                            }
                            else {
                                partnerContact.Id = conList[0].Id;
                                newUser = userList[0];
                            }
                        }
                    }
                    else {
                        partnerContact.Id = conList[0].Id;
                        newUser = createUser(conList[0],permissions);
                    }      

                    if (conList[0].FirstName == null) {
                        conList[0].FirstName = partnerContact.FirstName;
                    }
                    if (conList[0].LastName == null) {
                        conList[0].LastName = partnerContact.LastName;
                    }
                    if (conList[0].Email == null) {
                        conList[0].Email = partnerContact.Email;
                    }
                    if (conList[0].Time_zone__c == null) {
                        conList[0].Time_zone__c = partnerContact.Time_zone__c;
                    }
                    if (conList[0].Resource_Type__c == null) {
                        conList[0].Resource_Type__c = partnerContact.Resource_Type__c;
                    }

                    partnerContact.FirstName = conList[0].FirstName;
                    partnerContact.LastName = conList[0].LastName;
                    partnerContact.Email = conList[0].Email;
                    partnerContact.Resource_Type__c = conList[0].Resource_Type__c;
                    partnerContact.Time_zone__c = conList[0].Time_zone__c;
                    update partnerContact;
                }
                else {
                    insert partnerContact;
                    newUser = createUser(partnerContact, permissions);
                }

                if (!Test.isRunningTest()) {
                    shareUserRecord(newUser);
                }

                if (imgurl == null && profilepic != null && !Test.isRunningTest()) {
                    updateProfilePicture(newUser.id, profilepic);
                } else {
                    if (!Test.isRunningTest()) {
                        updateProfilePic(newUser.id, imgurl);
                    }  
                }
                
                List<ServiceTerritoryMembership> stm=(List<ServiceTerritoryMembership>) System.JSON.deserialize(stMembership, List<ServiceTerritoryMembership>.class);
                String jobid = (String) System.enqueueJob(new PV_AssignPermissionsetQueueable(newUser, resourceType, partnerContact, stm, skillList, startDate, directvExpiry, viasatExpiry, approvalid, shifts, browserTimeZone));
                return jobid;
            }
            catch (Exception e) {
                ExceptionUtil.publishFSLException('Internal Error', 'FSL', PV_ManageServiceResources.class.getName(), e.getMessage());
                throw new AuraHandledException(e.getMessage());
            } 
        }
    }

    public static void shareUserRecord(User newUser) {
        UserShare userShr = new UserShare();
        userShr.UserId = newUser.id;
        userShr.UserOrGroupId = UserInfo.getUserId();
        userShr.UserAccessLevel = 'Edit';
        userShr.RowCause = 'Manual';
        insert(userShr);
    }

    public static String createUserName(String conEmail, String usernamePrefix) {
        String uniqueUserName = conEmail + usernamePrefix;
        Integer emailCount = 0;
        
        for(AggregateResult ar :[SELECT Email, COUNT(id) FROM User WHERE email = :conEmail GROUP BY email]) {
            emailCount = (Integer)ar.get('expr0');
        }
        if (emailCount != 0) {
            String[] emailSplits = conEmail.split( '@' );
            uniqueUserName = emailSplits[0] + '_' + String.valueOf( emailCount + 1) + '@' + emailSplits[1] + usernamePrefix;
        }
        return uniqueUserName.toLowerCase();
    }

    public static user createUser(Contact partnerContact, Permission_Set_Assignment__mdt Permissions) {
        User newUser = new User();

        newUser.FirstName = partnerContact.FirstName;
        newUser.LastName = partnerContact.LastName;
        newUser.Email = partnerContact.Email;
        newUser.Username = createUserName(partnerContact.Email,System.Label.username_prefix);
        newUser.CommunityNickname = createNickName(partnerContact);
        newUser.ProfileId = [SELECT Id FROM Profile WHERE Name=:Permissions.Profile__c LIMIT 1].Id;
        newUser.Alias = !String.isBlank(partnerContact.FirstName) ? partnerContact.FirstName.substring(0, 1) : '' + partnerContact.LastName.substring(0, 1);
        
        if (partnerContact.Time_zone__c == null) {
            Organization orgInfo = [SELECT TimeZoneSidKey FROM Organization LIMIT 1];
            String orgTimeZone = orgInfo.TimeZoneSidKey;
            partnerContact.Time_zone__c = orgTimeZone;
        }
        
        newUser.TimeZoneSidKey = partnerContact.Time_zone__c;
        newUser.LocaleSidKey = 'en_US';
        newUser.ContactId = partnerContact.Id;
        newUser.EmailEncodingKey = 'UTF-8';
        newUser.LanguageLocaleKey = 'en_US';
        newUser.UserPreferencesShowProfilePicToGuestUsers = true;
        insert newUser;
        return newUser;
    }

    public static String createNickName(Contact con) {
        String nickName  =  !String.isBlank(con.FirstName) ? con.FirstName + con.LastName : '' + con.LastName;
        Integer nickNameCount = 0;
        String searchTerm = '%'+nickName+'%';
        List<User> usrList =[SELECT Id FROM User WHERE CommunityNickname like:searchTerm];

        if (!usrList.isEmpty()) {
            nickName = nickName + '_'+usrList.size();
        }
        
        return nickName;
    }
    
    @AuraEnabled
    public static Contact validateContact(String con, String resourceType,date viasatExpiry, date directvExpiry) {
        contactWrapper cont=(contactWrapper)system.JSON.deserialize(con,contactWrapper.class);
         validateEmail(cont.Email,cont.Account,resourceType);
        // If a new vendor is added
        if((resourceType == 'Technician'|| resourceType == 'Dispatcher and Technician') && 
           ((cont.Vendor.contains('DIRECTV') && String.isBlank(cont.IDDirecTV)) || (cont.Vendor.contains('Viasat') && String.isBlank(cont.IDViasat)))){
               String vendortype = cont.Vendor.contains('DIRECTV') && cont.Vendor.contains('Viasat') ? 'Viasat and DIRECTV' : cont.Vendor.contains('DIRECTV') ? 'DIRECTV' : 'Viasat';
               String vendor = ' Id';
               String vendors = ' Id'+'\''+'s';
               if(cont.Vendor.split(';').size()>1){
                   throw new AuraHandledException('Please fill ' + vendortype + vendors);
               }else{
                   throw new AuraHandledException('Please fill ' + String.join(cont.Vendor.split(';'), ',') +vendor);
               }
           }else if(String.isNotBlank(cont.IDDirecTV) || String.isNotBlank(cont.IDViasat)){
               if(String.isNotBlank(cont.IDDirecTV)){
                   validateDirectvVendorIds(cont.IDDirecTV, directvExpiry);
               }
               if(String.isNotBlank(cont.IDViasat)){
                   validateViasatVendorIds(cont.IDViasat, viasatExpiry);
               }
           }
        
        if (resourceType == 'Dispatcher' || resourceType == 'Dispatcher and Technician'){
            // validateDispatcher(cont.Email);
        }

        if((resourceType == 'Technician'|| resourceType == 'Dispatcher and Technician') && String.isNotBlank(cont.IDServicebench)){
            validateServicebenchVendorIds(cont.IDServicebench);
        }
        
        Contact ContRec=New Contact();
        ContRec.FirstName=cont.FirstName;
        ContRec.LastName=cont.LastName;
        ContRec.AccountId=cont.Account;
        ContRec.Time_zone__c=cont.Timezone;
        ContRec.Email=cont.Email;
        ContRec.Phone=cont.Phone;

        if(cont.DrugScreenDate!='') {
            ContRec.Drug_Screen_Date__c=Date.valueOf(cont.DrugScreenDate);
        }        
        if(cont.BackgroundCheckDate!='') {
            ContRec.Background_Check_Date__c=Date.valueOf(cont.BackgroundCheckDate);
        }
        ContRec.Include_in_Scheduling_Optimization__c=Boolean.valueOf(cont.IncludeinSchedulingOptimization);
        ContRec.MailingStreet=cont.MailingStreet;
        ContRec.MailingCity=cont.MailingCity;
        ContRec.MailingStateCode=cont.MailingStateCode;
        ContRec.MailingCountryCode=cont.MailingCountryCode;
        ContRec.MailingPostalCode=cont.MailingPostalCode;
        ContRec.ID_DirecTV__c=cont.IDDirecTV;
        ContRec.ID_Viasat__c=cont.IDViasat;
        ContRec.ID_Servicebench__c = cont.IDServicebench;
        ContRec.Vendor_Type__c=cont.Vendor;
        ContRec.Resource_Type__c = resourceType;
        ContRec.Manager__c=cont.Manager;
        return ContRec;
    }

    // Method to check viasatId is exist for another user
    public static void validateViasatVendorIds(String viasatId,Date viasatExpiry) {
        if(![SELECT id,EffectiveEndDate  from ServiceTerritoryMember where (EffectiveEndDate  >= TODAY OR EffectiveEndDate  = null) and ServiceResource.ID_Viasat__c =:viasatId].isEmpty()){
            throw new AuraHandledException('This Viasat ID is associated with another service resource.');
        }else if(viasatExpiry == null){
            throw new AuraHandledException('Please fill Viasat Id Expiration Date field');
        }
    }

    // Method to check directvId is exist for another user
    public static void validateDirectvVendorIds(String directvId,date directvExpiry) {
        if( ![SELECT id,EffectiveEndDate  from ServiceTerritoryMember where (EffectiveEndDate  >= TODAY OR EffectiveEndDate  = null) and ServiceResource.ID_DirecTV__c  =:directvId].isEmpty()){
            throw new AuraHandledException('This DIRECTV ID is associated with another service resource.');
        }else if(directvExpiry == null){
            throw new AuraHandledException('Please fill DIRECTV Id Expiration Date field');
        }
    }

    public static void validateServicebenchVendorIds(String IDServicebench) {
        if( ![SELECT id FROM ServiceResource WHERE ID_Servicebench__c  =:IDServicebench].isEmpty()){
            throw new AuraHandledException('This Servicebench ID is associated with another service resource.');
        }
    }

    // Method to check active user available or not
    public static void validateDispatcher(String dispatcherEmail) {
        if( ![SELECT Id from User where Contact.Email =:dispatcherEmail AND IsActive = true].isEmpty()){
            throw new AuraHandledException('This Email is associated with another Dispatcher.');
        }
    }

    // Method to check duplicate contact
    public static void validateEmail(String userEmail,String acc,String ResourceType) {
        List<string> errMsg1 = PV_FSL_Config__mdt.getInstance('ManageServiceResourceErrorMsg').Value__c.split(',');
        List<string> errMsg2 = PV_FSL_Config__mdt.getInstance('ManageServiceResourceErrorMsg2').Value__c.split(',');

        Permission_Set_Assignment__mdt Permissions = [
            SELECT  Permission_Sets__c, Permission_Set_Group__c, Profile__c, Resource_Type__c
            FROM    Permission_Set_Assignment__mdt
            WHERE   Resource_Type__c = :ResourceType
            LIMIT 1
        ];
        
        String accName = [SELECT Id,Name FROM  Account WHERE Id=:acc].Name;
        List<Contact> conList = [SELECT Id,FirstName,LastName,Email,Time_zone__c,AccountId,Resource_Type__c FROM contact where email=:userEmail];
                                                                  
        if (conList.size() > 0) {
            List<User> userList = [SELECT id,Profile.Name,IsActive,UserRole.Name FROM user where ContactId=:conList[0].Id];
            
            if (userList.size() > 0) {
                if (conList[0].Resource_Type__c  == 'Dispatcher and Technician' && conList[0].AccountId == acc) {
                    throw new AuraHandledException(errMsg1[1]);
                }
                if (conList[0].Resource_Type__c  == 'Dispatcher' && conList[0].AccountId == acc) {
                    throw new AuraHandledException(errMsg1[2]);
                }
                if (conList[0].Resource_Type__c == 'Technician' && conList[0].AccountId == acc) {
                    throw new AuraHandledException(errMsg1[3]);
                }
                if (userList[0].Profile.Name != Permissions.Profile__c) {
                    // throw new AuraHandledException(errMsg2[0]);
                }
                
                // Retrive current users assigned permissions
                List<PermissionSetAssignment> psList = [
                    SELECT  Id, PermissionSetId, PermissionSet.Name,PermissionSetGroup.DeveloperName, PermissionSet.ProfileId, PermissionSet.Profile.Name, AssigneeId, Assignee.Name 
                    FROM PermissionSetAssignment 
                    WHERE Assignee.Id =:userList[0].Id
                ];
                
                Boolean psExist = false;
                Boolean psGrpExist = false;
                
                for (PermissionSetAssignment psa : psList) {
                    if (Permissions.Permission_Sets__c == psa.PermissionSet.Name) {  
                        psExist = true;
                    }
                    if (Permissions.Permission_Set_Group__c == psa.PermissionSetGroup.DeveloperName) {
                        psGrpExist = true;
                    }
                }
                if (psExist == true && psGrpExist==true) {
                    throw new AuraHandledException(errMsg2[1]);
                }
            }
        }
    }
    
    @AuraEnabled
    public static String getFirstjobstatus(String jobid) {
        return [ SELECT Id, Status FROM AsyncApexJob WHERE Id = :jobid AND JobType='Queueable'].Status;
    }
    
    @AuraEnabled
    public static List<ServiceTerritory> getServiceTerritories(String AccountId,String searchKey) {
        String strKey = '%' + searchKey + '%';  
        return [SELECT Id, Name FROM ServiceTerritory WHERE Account__c = :AccountId AND Name LIKE: strKey AND IsActive = TRUE LIMIT 5];
    }
    
    @AuraEnabled
    public static String getSecondjobstatus() {
        id ApexclassId=[select id,Name from ApexClass where Name='PV_CreateSRandSTMQueueable'].id;
        return [ SELECT Id,status FROM AsyncApexJob where  JobType='Queueable' AND ApexClassId=:ApexclassId order by CreatedDate desc limit 1 ].status;
    }
    
    @future(Callout=true)
    public static void updateProfilePic(id us,string img) {
        PageReference page = new PageReference(img);
        Blob blobImage = page.getContent();
        ConnectApi.BinaryInput fileUpload = new ConnectApi.BinaryInput(blobImage, 'image/jpg', 'userImage.jpg');
        ConnectApi.Photo photoProfile = ConnectApi.UserProfiles.setPhoto(null, us,  fileUpload);
    }

    @AuraEnabled
    public static void updateProfilePicture(String userId, String profilePicture) {
        Blob blobImage = EncodingUtil.base64Decode(profilePicture);
        ConnectApi.BinaryInput fileUpload = new ConnectApi.BinaryInput(blobImage, 'image/jpg', 'userImage.jpg');
        ConnectApi.Photo photoProfile = ConnectApi.UserProfiles.setPhoto(null, userId, fileUpload);

        User user = [SELECT Id, UserPreferencesShowProfilePicToGuestUsers FROM User WHERE Id = :userId];
        if (user.UserPreferencesShowProfilePicToGuestUsers == false) {
            user.UserPreferencesShowProfilePicToGuestUsers = true;
            update user;
        }
    }

    //Method to validate permission
    @AuraEnabled
    public static string validatePermission() {
        Boolean hasCustomEditPermission = FeatureManagement.checkPermission('ManageServiceResource_edit_access');
        if(hasCustomEditPermission == false){
           return 'false';
        }else
        {
            return 'true';
        }
    }
    
    public class ServiceTerritoryMembership {
        public Integer IndexId;
        public String TerritoryId;
        public String StartDate;
        public String TerritoryType;
    }

    public class contactWrapper {
        public String FirstName;  
        public String LastName;  
        public String Account;  
        public String Timezone;  
        public String Email;  
        public String Phone;  
        public String DrugScreenDate;  
        public String BackgroundCheckDate;  
        public String IncludeinSchedulingOptimization;  
        public String MailingStreet;  
        public String MailingCity;  
        public String MailingStateCode;  
        public String MailingCountryCode;  
        public String MailingPostalCode;  
        public String IDDirecTV;  
        public String IDViasat;
        public String IDServicebench;
        public String Vendor;
        public String Manager=null;
    }
    
    public class filelist {
        String filename;
        String base64;
    }

    public static DateTime calculateHoursDiference(DateTime startDate, TimeZone timeZone1, TimeZone timeZone2) {
        System.debug('StartDate: ' + startDate);

        Integer offset1 = timeZone1.getOffset(startDate);
        Integer offset2 = timeZone2.getOffset(startDate);
                                    
        Integer offsetDifferenceInSeconds = (offset1 - offset2) / 1000;
        Integer offsetDifferenceInHours = offsetDifferenceInSeconds/3600;
                                    
        System.debug('offsetDifferenceInSeconds: ' + offsetDifferenceInSeconds/3600);

        DateTime returnDate = startDate.addHours(offsetDifferenceInHours);
        System.debug('newDateTime: ' + returnDate);

        return returnDate;
    }
}
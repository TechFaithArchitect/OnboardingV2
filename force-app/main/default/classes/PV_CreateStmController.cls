public class PV_CreateStmController {
    //Method to return service resource list againt an account
    @AuraEnabled(cacheable=true)
    public static list<ServiceResource> getResourceList(String accountId) {
        List<ServiceResource> servicResourceList = [
            SELECT Id, Name, RelatedRecordId, RelatedRecord.FullPhotoUrl
            FROM ServiceResource
            WHERE AccountId = :accountId AND IsActive = TRUE
        ];
        return servicResourceList;
    }
    //Method to return STM associated with Resource
    @AuraEnabled(cacheable=false)
    public static list<ResourceWrapper> getStmAsscociatedWithResource(String resourceId, String accountId) {
      
        Map<String, ServiceTerritoryMember> stmMapForResource = new Map<String, ServiceTerritoryMember>();
        for (ServiceTerritoryMember stm : [
            SELECT ServiceTerritoryId, EffectiveEndDate
            FROM ServiceTerritoryMember
            WHERE ServiceResourceId = :resourceId
        ]) {
            stmMapForResource.put(stm.ServiceTerritoryId, stm);
        }
        List<ResourceWrapper> wrapperList = new List<ResourceWrapper>();
        for (ServiceTerritory st : [
            SELECT Id, Name
            FROM ServiceTerritory
            WHERE Account__c = :accountId AND IsActive = TRUE
            ORDER BY Name ASC
        ]) {
            Date todayDate = System.today();

            ResourceWrapper wrapperObj = new ResourceWrapper();
            wrapperObj.serviceTerritoryId = st.Id;
            wrapperObj.serviceTerritoryMemberId = stmMapForResource.containsKey(st.Id) ? stmMapForResource.get(st.Id).Id : null;
            wrapperObj.territoryName = st.Name;
            wrapperObj.isTerritoryMember = stmMapForResource.containsKey(st.Id) && (stmMapForResource.get(st.Id).EffectiveEndDate == null || stmMapForResource.get(st.Id).EffectiveEndDate.date() > todayDate);
            wrapperObj.EndDate = stmMapForResource.containsKey(st.Id) ? stmMapForResource.get(st.Id).EffectiveEndDate : null;
            wrapperList.add(wrapperObj);
        }
        system.debug('wrapperList' + wrapperList);
        return wrapperList;
    }

    @AuraEnabled(cacheable=false)
    public static list<ServiceTerritoryMember> getSTMAddress(String resourceId) {
        return [
            SELECT Id, Address
            FROM ServiceTerritoryMember
            WHERE ServiceResourceId = :resourceId AND TerritoryType = 'P'
        ];
    }

    @AuraEnabled(cacheable=false)
    public static ServiceTerritoryMember updateSTMAddress(String memberId, Map<String, Object> addressData) {
        ServiceTerritoryMember member = [
            SELECT Id, Street, City, State, StateCode, PostalCode, Country, CountryCode
            FROM ServiceTerritoryMember
            WHERE Id = :memberId
        ];
        member.Street = (String) addressData.get('street');
        member.City = (String) addressData.get('city');
        member.State = (String) addressData.get('state');
        member.StateCode = (String) addressData.get('stateCode');
        member.PostalCode = (String) addressData.get('zip');
        member.Country = (String) addressData.get('country');
        member.CountryCode = (String) addressData.get('countryCode');
        update member;
        return member;
    }

    @AuraEnabled(cacheable=false)
    public static list<DispatcherWrapper> getStmAsscociatedWithResourceDispatchers(String contactId, String accountId) {
        List<DispatcherWrapper> wrapperList = new List<DispatcherWrapper>();

        try {
            List<ServiceTerritory> serviceTerritories = [
                SELECT Id, Name
                FROM ServiceTerritory
                WHERE Account__c = :accountId AND IsActive = TRUE
                ORDER BY Name ASC
            ];
            User dispatcher = [SELECT Id, ContactId FROM User WHERE ContactId = :contactId LIMIT 1];
            Set<String> groupNames = new Set<String>();

            for (ServiceTerritory st : serviceTerritories) {
                groupNames.add(st.Name);
            }

            Map<String, GroupMember> memberByGroupName = new Map<String, GroupMember>();
            for (GroupMember gm : [
                SELECT Id, GroupId, Group.Name, UserOrGroupId
                FROM GroupMember
                WHERE UserOrGroupId = :dispatcher.Id AND Group.Name IN :groupNames
            ]) {
                memberByGroupName.put(gm.Group.Name, gm);
            }

            for (ServiceTerritory st : serviceTerritories) {
                DispatcherWrapper wrapperObj = new DispatcherWrapper();
                wrapperObj.userId = dispatcher.Id;
                wrapperObj.serviceTerritoryId = st.Id;
                wrapperObj.groupName = st.Name;
                wrapperObj.isTerritoryMember = memberByGroupName.get(st.Name) != null;
                wrapperObj.memberId = wrapperObj.isTerritoryMember ? memberByGroupName.get(st.Name).Id : null;
                wrapperList.add(wrapperObj);
            }
        } catch (Exception e) {
            System.debug(e.getMessage());
        }

        return wrapperList;
    }

    @AuraEnabled(cacheable=false)
    public static void processMemberships(List<Map<String, String>> members) {
        List<GroupMember> membersToCreate = new List<GroupMember>();
        List<GroupMember> membersToDelete = new List<GroupMember>();

        Set<String> groupNames = new Set<String>();

        for (Map<String, String> member : members) {
            groupNames.add(member.get('groupName'));
        }

        Map<String, Id> groupsByName = new Map<String, Id>();

        for (Group g : [SELECT Id, Name FROM Group WHERE Name IN :groupNames]) {
            groupsByName.put(g.Name, g.Id);
        }

        for (Map<String, String> member : members) {
            if (member.get('isTerritoryMember') == 'true') {
                System.debug('GROUP ID:    ' + groupsByName.get(member.get('groupName')));

                GroupMember gm = new GroupMember();
                gm.UserOrGroupId = member.get('userId');
                gm.GroupId = groupsByName.get(member.get('groupName'));

                membersToCreate.add(gm);
            } else {
                GroupMember gmDelete = new GroupMember();
                gmDelete.Id = member.get('memberId');
                membersToDelete.add(gmDelete);
            }
        }

        if (!membersToCreate.isEmpty()) {
            PV_CreateStmGroupMembersHandler.createGroupMembers(membersToCreate);
        }
        if (!membersToDelete.isEmpty()) {
            PV_CreateStmGroupMembersHandler.deleteGroupMembers(membersToDelete);
        }
    }

    ///Method to upsert STM
    @AuraEnabled(cacheable=false)
    public static string upsertStm(list<Map<String, String>> resourceRegionList, String resourceId, Date startDate) {

        try { 

            Map<String, List<Shift>> shiftsByTerritory = new Map<String, List<Shift>>();
            List<Shift> shiftsToDelete = new List<Shift>();
           

            for(Shift s : [SELECT Id, ServiceResourceId, ServiceTerritoryId FROM Shift 
                           WHERE ServiceResourceId = :resourceId 
                           AND StartTime > :System.now()]) {
                               
				if (!shiftsByTerritory.containsKey(s.ServiceTerritoryId)) {
                	shiftsByTerritory.put(s.ServiceTerritoryId, new List<Shift>());
                }
                	shiftsByTerritory.get(s.ServiceTerritoryId).add(s);                
            }
            

            List<ServiceTerritoryMember> stmToUpsertList = new List<ServiceTerritoryMember>();

            for (Map<String, String> serviceTerritory : resourceRegionList) {

                ServiceTerritoryMember stm = new ServiceTerritoryMember();

                if(serviceTerritory.get('serviceTerritoryMemberId') != null) {
                    stm.Id = serviceTerritory.get('serviceTerritoryMemberId');

                }else {
                    stm.ServiceTerritoryId = serviceTerritory.get('serviceTerritoryId');
                }
                    

                if(!Boolean.valueOf(serviceTerritory.get('isChecked'))) {

                    Datetime todayDateTime = Datetime.newInstance(System.today(), Time.newInstance(0, 0, 0, 0)).addHours(8);
                    stm.EffectiveEndDate = todayDateTime;   
                    
                    if(shiftsByTerritory.get(serviceTerritory.get('serviceTerritoryId')) != null) {
                        shiftsToDelete.addAll(shiftsByTerritory.get(serviceTerritory.get('serviceTerritoryId')));
                    }

                }else {

                    if(serviceTerritory.get('EndDate') != null)
                        stm.EffectiveEndDate = null;

                    Time inputTime = Time.newInstance(0, 0, 0, 0);
                    Datetime dateTimeWithTime = Datetime.newInstance(startDate, inputTime);

                    stm.EffectiveStartDate = dateTimeWithTime;
                }

                stm.ServiceResourceId = resourceId;
                stm.TerritoryType = 'S';
                
                stmToUpsertList.add(stm);
            }

            if (!stmToUpsertList.isEmpty()) {
                upsert stmToUpsertList;
            }
            if(!shiftsToDelete.isEmpty()) {
                delete shiftsToDelete;
            }
            return 'Success';
        } catch (Exception ex) {
            ExceptionUtil.publishException(
                'PV_CreateStmController.upsertStm',
                ex.getLineNumber(),
                ex.getMessage(),
                ex.getStackTraceString()
            );
            throw new AuraHandledException(ex.getMessage());
        }
    }

    public class ResourceWrapper {
        @AuraEnabled
        public Id serviceTerritoryId;
        @AuraEnabled
        public Id serviceTerritoryMemberId;
        @AuraEnabled
        public String territoryName;
        @AuraEnabled
        public Boolean isTerritoryMember;
        @AuraEnabled
        public Datetime EndDate;
    }

    public class DispatcherWrapper {
        @AuraEnabled
        public Id userId;
        @AuraEnabled
        public Id serviceTerritoryId;
        @AuraEnabled
        public String groupName;
        @AuraEnabled
        public Boolean isTerritoryMember;
        @AuraEnabled
        public Id memberId;
    }
}
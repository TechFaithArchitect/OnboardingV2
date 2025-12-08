public class PV_AddLocation {
    public static final String PV_BUSINESS_UNIT = System.Label.FSL_PV_Business_Unit;

    @AuraEnabled
    public static void submitForLocationApproval(String locationName, String locationType, Id accountId, Boolean isInventory,Boolean isMobile, String locationResource) {
        try {
            if (locationType == 'Van') {
                if (locationType == 'Van' && (isMobile == false || isInventory == false)) {
                    throw newMessageException('For creating a location Type as Van, ensure you check Mobile and Inventory Location');
                }

                Schema.Location loct = new Schema.Location();
                loct.Name = locationName;
                loct.LocationType = locationType;
                loct.IsInventoryLocation = isInventory;
                loct.Account__c = accountId;
                loct.IsMobile = isMobile;

                if (isMobile && locationResource != '') {
                    loct.Service_Resource__c = locationResource;
                }
                insert loct;
            }
            else {
                if (locationType == 'Warehouse' && isMobile == true) {
                    throw newMessageException('Mobile Location should not be checked for the Location Type Warehouse');
                }

                Account account = getCurrentAccount(accountId);

                if (account.Business_Unit__c == PV_BUSINESS_UNIT) {
                    submitForApproval(locationName, locationType, accountId, isInventory, isMobile);
                } else {
                    createLocationRecord(locationName, locationType, accountId, isInventory, isMobile);
                }
            }
        }
        catch (Exception e) {
            ExceptionUtil.publishFSLException('Internal Error', 'FSL', PV_AddLocation.class.getName(), e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static Account getCurrentAccount(Id accountId) {
        return [
            SELECT  Id, Business_Unit__c
            FROM    Account
            WHERE   Id = :accountId
        ];
    }

    public static void submitForApproval(String locationName, String locationType, String accountId, Boolean isInventory, Boolean isMobile) {
        Process_Approval__c pa = new Process_Approval__c();
        Id rtId = [SELECT Id FROM RecordType WHERE SobjectType = 'Process_Approval__c' AND Name = 'Location Approval' LIMIT 1].Id;
        pa.RecordTypeId = rtId;
        pa.Location_Name__c = locationName;
        pa.Location_Type__c = locationType;
        pa.Account__c = accountId;
        pa.Inventory_Location__c = isInventory;
        pa.Mobile_Location__c = isMobile;
        insert pa;
        
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(pa.Id);
        req.setProcessDefinitionNameOrId('PV_Location_Approval');
        req.setSkipEntryCriteria(false);
        Approval.ProcessResult result = Approval.process(req);
    }

    public static void createLocationRecord(String locationName, String locationType, String accountId, Boolean isInventory, Boolean isMobile) {
        Schema.Location location = new Schema.Location();
        location.Name = locationName;
        location.LocationType = locationType;
        location.IsInventoryLocation = isInventory;
        location.Account__c = accountId;
        location.IsMobile = isMobile;
        insert location;
    }

    private static AuraHandledException newMessageException(String message) {
        AuraHandledException e = new AuraHandledException(message);
        e.setMessage(message);
        return e;
    }

    @AuraEnabled
    public static List<ResourceWrapper> getServiceResources (String accountId) {
        List<ServiceResource> accountResources = [SELECT ID, Name, AccountId, Vendor_Type__c FROM ServiceResource WHERE IsActive = TRUE AND AccountId =: accountId AND LocationId = null ORDER BY Name];
        List<ResourceWrapper> returnList = new List<ResourceWrapper>();
        ResourceWrapper defaultValue = new ResourceWrapper();

        defaultValue.label = '-';
        defaultValue.value = '';
        defaultValue.isSelected = true;
        defaultValue.hidden = true;
        returnList.add(defaultValue);

        for (ServiceResource res : accountResources) {
            ResourceWrapper newValue = new ResourceWrapper();
            newValue.label = res.Name + ' - (' + res.Vendor_Type__c + ')';
            newValue.value = res.Id;
            newValue.isSelected = false;

            returnList.add(newValue);
        }
        return returnList;
    }

    public class ResourceWrapper {
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String value {get; set;}
        @AuraEnabled
        public Boolean isSelected {get; set;}
        @AuraEnabled
        public Boolean hidden {get; set;}
    }
}
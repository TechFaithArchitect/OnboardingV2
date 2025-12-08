public without sharing class ClickerController {
    public static final String EVENT = 'event';
    public static final String RETAIL = 'retail';
    public static final String CALLCENTER = 'callcenter';
    public static final String CLICKER_GEO_CODE_REC_TYPE = 'ClickerGeoCode';
    public static final String TRACKING_GEO_CODE_REC_TYPE = 'TrackingGeoCode';
    public static final String CLICKER_PAGE = 'ClickerPage';
    public static final String PLUS_BUTTON = 'Plus Button';
    public static final String ACTION_CONTACT = 'Contact';
    //TO DO METHODS:

    // Begin Sale actions - Sales / Event / Retail

    // Get Stores for Store Selection - Replace DRGetRetailStore
    @AuraEnabled
    public static Map<String, Object> getStore() {
        try {
            Map<String, Object> result;
            Id userId = UserInfo.getUserId();
            User userRecord = [SELECT Partner_Account_Id__c FROM User WHERE Id = :userId];
            List<POE_DealerStore__c> dealer = [
                SELECT POE_Dealer__c, POE_Store__c
                FROM POE_DealerStore__c
                WHERE POE_Dealer__c = :userRecord.Partner_Account_Id__c
            ];
            Set<Id> storeIds = new Set<Id>();
            if (dealer.isEmpty()) {
                result = new Map<String, Object>{ 'error' => 'No Dealer Stores found' };
                return result;
            } else {
                for (POE_DealerStore__c dealerRecord : dealer) {
                    storeIds.add(dealerRecord.POE_Store__c);
                }
            }
            List<POE_Retail_Store__c> stores = [SELECT Id, Name FROM POE_Retail_Store__c WHERE Id IN :storeIds AND Status__c = 'Active'];
            if (stores.isEmpty()) {
                result = new Map<String, Object>{ 'error' => 'No Stores found' };
                return result;
            }
            result = new Map<String, Object>{
                'User' => userRecord,
                'Account' => userRecord.Partner_Account_Id__c,
                'DealerStore' => dealer,
                'stores' => stores
            };
            return result;
        } catch (Exception exc) {
            throw new AuraHandledException(exc.getMessage());
        }
    }

    // Get Event for Event selection - Replace DRGetEvent
    @AuraEnabled
    public static Map<String, Object> getEvent() {
        try {
            Boolean isOwner = false;
            Id userId = UserInfo.getUserId();
            Map<String, Object> result;
            User userRecord = [SELECT Partner_Account_Id__c,Contact.POE_Functional_Role__c FROM User WHERE Id = :userId];
            isOwner = userRecord.Contact.POE_Functional_Role__c == 'Office Manager' || userRecord.Contact.POE_Functional_Role__c == 'Sales Manager' || userRecord.Contact.POE_Functional_Role__c == 'Team Lead';
            List<POE_DealerEvent__c> dealer = [
                SELECT POE_Dealer__c, POE_Event__c
                FROM POE_DealerEvent__c
                WHERE POE_Dealer__c = :userRecord.Partner_Account_Id__c
            ];
            Set<Id> eventIds = new Set<Id>();
            if (dealer.isEmpty()) {
                result = new Map<String, Object>{ 'error' => 'No Dealer Events found' };
                return result;
            } else {
                for (POE_DealerEvent__c dealerRecord : dealer) {
                    eventIds.add(dealerRecord.POE_Event__c);
                }
            }
            List<POE_Event__c> events = [
                SELECT Id, Name
                FROM POE_Event__c
                WHERE Id IN :eventIds AND Status__c = 'Active'
            ];
            if (events.isEmpty()) {
                result = new Map<String, Object>{ 'error' => 'No Active Events found' };
                return result;
            }
            result = new Map<String, Object>{
                'User' => userRecord,
                'Account' => userRecord.Partner_Account_Id__c,
                'DealerEvent' => dealer,
                'events' => events,
                'isOwner' => isOwner
            };
            return result;
        } catch (Exception exc) {
            throw new AuraHandledException(exc.getMessage());
        }
    }

    // Log an Interaction - Replaces Log an Interaction IP actions on Event / Retail
    @AuraEnabled
    public static Map<String, Object> logAnInteraction(String origin, String userId, String relatedRecordId) {
        try {
            Map<String, Object> result;
            if (userId == null) {
                userId = UserInfo.getUserId();
            }
            result = setTrack(origin, userId, relatedRecordId);
            maps__Location__c geoCodeTracking = saveGeoCodeTracking(userId);
            result.put('geoCodeTracking', geoCodeTracking.Id);
            result.put('error', false);
            return result;
        } catch (Exception exc) {
            throw new AuraHandledException(exc.getMessage());
        }
    }

    // Set Track - Replaces IPs for Event / Retail / Call Center (Begin Sales button)
    @AuraEnabled
    public static Map<String, Object> setTrack(String origin, String userId, String relatedRecordId) {
        try {
            Date today = System.today();
            SObject setTrackResult;
            Map<String, Object> getTrackResult;
            switch on origin {
                when 'event' {
                    setTrackResult = setClickerEventTrack(relatedRecordId, true, ACTION_CONTACT, null);
                    getTrackResult = getClickerEventTrack(userId, today);
                }
                when 'retail' {
                    setTrackResult = setClickerRetailTrack(relatedRecordId, true, ACTION_CONTACT, null);
                    getTrackResult = getClickerRetailTrack(userId, today);
                }
                when 'mdu' {
                    setTrackResult = setClickerMDUTrack(relatedRecordId, true, ACTION_CONTACT, null);
                    getTrackResult = getClickerMDUTrack(userId, today);
                }
                when else {
                    throw new AuraHandledException('Invalid origin provided');
                }
            }
            POEInteractionTracker interactionTracker = new POEInteractionTracker();
            Boolean poeInteractionTrackerResult = interactionTracker.invokeMethod(null, null, null, null);
            return getTrackResult;
        } catch (Exception exc) {
            throw new AuraHandledException(exc.getMessage());
        }
    }

    //Replace DRgetUserFraudFlag
    @AuraEnabled
    public static Boolean getUserFraudFlag(Id userId) {
        try {
            Id searchUserId = (String.isBlank(userId)) ? UserInfo.getUserId() : userId;

            User userWithFlag = [SELECT POE_FraudObservation__c FROM User WHERE Id = :searchUserId];
            return userWithFlag.POE_FraudObservation__c;
        } catch (Exception exc) {
            throw new AuraHandledException(exc.getMessage());
        }
    }

    //Replace DRSetClickerEventTrack
    @AuraEnabled
    public static POE_Clicker_Event_Track__c setClickerEventTrack(
        String event,
        Boolean isCount,
        String action,
        Id trackId
    ) {
        try {
            POE_Clicker_Event_Track__c clickerEventTrack = new POE_Clicker_Event_Track__c(
                Action__c = action,
                POE_Event__c = event,
                POE_isCount__c = isCount
            );
            if (trackId != null && trackId != '') {
                clickerEventTrack.Id = trackId;
            }
            upsert clickerEventTrack;
            return clickerEventTrack;
        } catch (Exception exc) {
            throw new AuraHandledException(exc.getMessage());
        }
    }

    //Replace DRSetClickerRetailTrack
    @AuraEnabled
    public static POE_Clicker_Retail_Track__c setClickerRetailTrack(
        String store,
        Boolean isCount,
        String action,
        Id trackId
    ) {
        try {
            POE_Clicker_Retail_Track__c clickerRetailTrack = new POE_Clicker_Retail_Track__c(
                POE_Action__c = action,
                POE_Store__c = store,
                POE_isCount__c = isCount
            );
            if (trackId != null && trackId != '') {
                clickerRetailTrack.Id = trackId;
            }
            upsert clickerRetailTrack;
            return clickerRetailTrack;
        } catch (Exception exc) {
            throw new AuraHandledException(exc.getMessage());
        }
    }

    //Replace DRSetClickerCallCenterTrack
    @AuraEnabled
    public static POE_Clicker_Call_Center_Track__c setClickerCallCenterTrack(String action, Id trackId) {
        try {
            POE_Clicker_Call_Center_Track__c clickerCallCenterTrack = new POE_Clicker_Call_Center_Track__c(
                Action__c = action
            );
            if (trackId != null && trackId != '') {
                clickerCallCenterTrack.Id = trackId;
            }
            upsert clickerCallCenterTrack;
            return clickerCallCenterTrack;
        } catch (Exception exc) {
            throw new AuraHandledException(exc.getMessage());
        }
    }

    //Replace DRGetClickerEventTrack
    @AuraEnabled
    public static Map<String, Object> getClickerEventTrack(Id userId, Date searchDate) {
        try {
            String inProgressEvent;
            String event;
            String eventId;
            Integer countCompleted;
            Integer countServiceability;
            Integer countProduct;
            Integer countContact;
            if (searchDate == null) {
                searchDate = System.today();
            }
            if (userId == null) {
                userId = UserInfo.getUserId();
            }

            List<POE_Clicker_Event_Track__c> eventTrackLast = [
                SELECT Id, CreatedById, Poe_Date_c__c, Poe_isCount__c, Action__c, Poe_Event__c, Poe_Event__r.Name
                FROM POE_Clicker_Event_Track__c
                WHERE CreatedById = :userId AND POE_Date_c__c = :searchDate AND POE_Event__c != NULL
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            List<POE_Clicker_Event_Track__c> eventTrackInProgress = [
                SELECT Id, CreatedById, Poe_Date_c__c, Poe_isCount__c, Action__c, Poe_Event__c, Poe_Event__r.Name
                FROM POE_Clicker_Event_Track__c
                WHERE CreatedById = :userId AND POE_isCount__c = TRUE
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            List<POE_Clicker_Event_Track__c> eventTracks = [
                SELECT Id, CreatedById, Poe_Date_c__c, Poe_isCount__c, Action__c, Poe_Event__c, Poe_Event__r.Name
                FROM POE_Clicker_Event_Track__c
                WHERE CreatedById = :userId AND POE_Date_c__c = :searchDate AND POE_isCount__c = TRUE
            ];
            List<POE_Clicker_Event_Track__c> eventTrackContact = new List<POE_Clicker_Event_Track__c>();
            List<POE_Clicker_Event_Track__c> eventTrackServiceability = new List<POE_Clicker_Event_Track__c>();
            List<POE_Clicker_Event_Track__c> eventTrackProduct = new List<POE_Clicker_Event_Track__c>();
            List<POE_Clicker_Event_Track__c> eventTrackCompleted = new List<POE_Clicker_Event_Track__c>();

            for (POE_Clicker_Event_Track__c eventTrack : eventTracks) {
                switch on eventTrack.Action__c {
                    when 'Contact' {
                        eventTrackContact.add(eventTrack);
                    }
                    when 'Serviceability Check' {
                        eventTrackServiceability.add(eventTrack);
                    }
                    when 'Product Selection' {
                        eventTrackProduct.add(eventTrack);
                    }
                    when 'Buyflow Completed' {
                        eventTrackCompleted.add(eventTrack);
                    }
                }
            }

            countContact = eventTrackContact.size();
            countServiceability = eventTrackServiceability.size();
            countProduct = eventTrackProduct.size();
            countCompleted = eventTrackCompleted.size();
            inProgressEvent = !eventTrackInProgress.isEmpty() ? eventTrackInProgress[0].Id : null;
            event = !eventTrackLast.isEmpty() ? eventTrackLast[0].POE_Event__r.Name : null;
            eventId = !eventTrackLast.isEmpty() ? eventTrackLast[0].POE_Event__c : null;

            Map<String, Object> result = new Map<String, Object>{
                'inProgressEvent' => inProgressEvent,
                'eventId' => eventId,
                'event' => event,
                'countCompleted' => countCompleted,
                'countServiceability' => countServiceability,
                'countProduct' => countProduct,
                'countContact' => countContact
            };
            return result;
        } catch (Exception exc) {
            throw new AuraHandledException(exc.getMessage());
        }
    }

    //Replace DRGetClickerRetailTrack
    @AuraEnabled
    public static Map<String, Object> getClickerRetailTrack(Id userId, Date searchDate) {
        try {
            String inProgressRetail;
            String store;
            String storeId;
            String NFFLcode;
            String FFLcode;
            String storeType;
            Integer countCompleted;
            Integer countServiceability;
            Integer countProduct;
            Integer countContact;
            if (searchDate == null) {
                searchDate = System.today();
            }
            if (userId == null) {
                userId = UserInfo.getUserId();
            }

            List<POE_Clicker_Retail_Track__c> retailTrackLast = [
                SELECT
                    Id,
                    CreatedById,
                    Poe_Date__c,
                    Poe_isCount__c,
                    Poe_Action__c,
                    Poe_Store__c,
                    Poe_Store__r.Poe_Retail_National_Retail__c,
                    Poe_Store__r.Poe_DTV_FFL__c,
                    Poe_Store__r.Poe_DTV_NFFL__c,
                    Poe_Store__r.Name
                FROM POE_Clicker_Retail_Track__c
                WHERE CreatedById = :userId AND POE_Date__c = :searchDate AND POE_Store__c != NULL
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            List<POE_Clicker_Retail_Track__c> retailTrackInProgress = [
                SELECT
                    Id,
                    CreatedById,
                    Poe_Date__c,
                    Poe_isCount__c,
                    Poe_Action__c,
                    Poe_Store__c,
                    Poe_Store__r.Poe_Retail_National_Retail__c,
                    Poe_Store__r.Poe_DTV_FFL__c,
                    Poe_Store__r.Poe_DTV_NFFL__c,
                    Poe_Store__r.Name
                FROM POE_Clicker_Retail_Track__c
                WHERE CreatedById = :userId AND POE_isCount__c = TRUE
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            List<POE_Clicker_Retail_Track__c> retailTracks = [
                SELECT
                    Id,
                    CreatedById,
                    Poe_Date__c,
                    Poe_isCount__c,
                    Poe_Action__c,
                    Poe_Store__c,
                    Poe_Store__r.Poe_Retail_National_Retail__c,
                    Poe_Store__r.Poe_DTV_FFL__c,
                    Poe_Store__r.Poe_DTV_NFFL__c,
                    Poe_Store__r.Name
                FROM POE_Clicker_Retail_Track__c
                WHERE CreatedById = :userId AND POE_Date__c = :searchDate AND POE_isCount__c = TRUE
            ];
            List<POE_Clicker_Retail_Track__c> retailTrackContact = new List<POE_Clicker_Retail_Track__c>();
            List<POE_Clicker_Retail_Track__c> retailTrackServiceability = new List<POE_Clicker_Retail_Track__c>();
            List<POE_Clicker_Retail_Track__c> retailTrackProduct = new List<POE_Clicker_Retail_Track__c>();
            List<POE_Clicker_Retail_Track__c> retailTrackCompleted = new List<POE_Clicker_Retail_Track__c>();

            for (POE_Clicker_Retail_Track__c retailTrack : retailTracks) {
                switch on retailTrack.POE_Action__c {
                    when 'Contact' {
                        retailTrackContact.add(retailTrack);
                    }
                    when 'Serviceability Check' {
                        retailTrackServiceability.add(retailTrack);
                    }
                    when 'Product Selection' {
                        retailTrackProduct.add(retailTrack);
                    }
                    when 'Buyflow Completed' {
                        retailTrackCompleted.add(retailTrack);
                    }
                }
            }

            countContact = retailTrackContact.size();
            countServiceability = retailTrackServiceability.size();
            countProduct = retailTrackProduct.size();
            countCompleted = retailTrackCompleted.size();
            inProgressRetail = !retailTrackInProgress.isEmpty() ? retailTrackInProgress[0].Id : null;
            if (!retailTrackLast.isEmpty()) {
                storeId = retailTrackLast[0].POE_Store__c;
                store = retailTrackLast[0].POE_Store__r.Name;
                storeType = retailTrackLast[0].POE_Store__r.Poe_Retail_National_Retail__c;
                NFFLcode = retailTrackLast[0].POE_Store__r.Poe_DTV_NFFL__c;
                FFLcode = retailTrackLast[0].POE_Store__r.Poe_DTV_FFL__c;
            }

            Map<String, Object> result = new Map<String, Object>{
                'inProgressRetail' => inProgressRetail,
                'store' => store,
                'storeId' => storeId,
                'NFFLcode' => NFFLcode,
                'FFLcode' => FFLcode,
                'storeType' => storeType,
                'countCompleted' => countCompleted,
                'countServiceability' => countServiceability,
                'countProduct' => countProduct,
                'countContact' => countContact
            };
            return result;
        } catch (Exception exc) {
            throw new AuraHandledException(exc.getMessage());
        }
    }

    //Replace DRGetClickerCallCenterTrack
    @AuraEnabled
    public static Map<String, Object> getClickerCallCenterTrack(Id userId, Date searchDate) {
        try {
            String inProgressTrack;
            Integer countCompleted;
            Integer countServiceability;
            Integer countProduct;
            Integer countContact;
            if (searchDate == null) {
                searchDate = System.today();
            }

            List<POE_Clicker_Call_Center_Track__c> callCenterTrackInProgress = [
                SELECT Id, Poe_Date__c, CreatedById, Action__c
                FROM POE_Clicker_Call_Center_Track__c
                WHERE CreatedById = :userId AND POE_Date__c = :searchDate
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            List<POE_Clicker_Call_Center_Track__c> callCenterTracks = [
                SELECT Id, Poe_Date__c, CreatedById, Action__c
                FROM POE_Clicker_Call_Center_Track__c
                WHERE CreatedById = :userId AND POE_Date__c = :searchDate
            ];
            List<POE_Clicker_Call_Center_Track__c> callCenterTrackContact = new List<POE_Clicker_Call_Center_Track__c>();
            List<POE_Clicker_Call_Center_Track__c> callCenterTrackServiceability = new List<POE_Clicker_Call_Center_Track__c>();
            List<POE_Clicker_Call_Center_Track__c> callCenterTrackProduct = new List<POE_Clicker_Call_Center_Track__c>();
            List<POE_Clicker_Call_Center_Track__c> callCenterTrackCompleted = new List<POE_Clicker_Call_Center_Track__c>();

            for (POE_Clicker_Call_Center_Track__c callCenterTrack : callCenterTracks) {
                switch on callCenterTrack.Action__c {
                    when 'Contact' {
                        callCenterTrackContact.add(callCenterTrack);
                    }
                    when 'Serviceability Check' {
                        callCenterTrackServiceability.add(callCenterTrack);
                    }
                    when 'Product Selection' {
                        callCenterTrackProduct.add(callCenterTrack);
                    }
                    when 'Buyflow Completed' {
                        callCenterTrackCompleted.add(callCenterTrack);
                    }
                }
            }

            countContact = callCenterTrackContact.size();
            countServiceability = callCenterTrackServiceability.size();
            countProduct = callCenterTrackProduct.size();
            countCompleted = callCenterTrackCompleted.size();
            inProgressTrack = !callCenterTrackInProgress.isEmpty() ? callCenterTrackInProgress[0].Id : null;

            Map<String, Object> result = new Map<String, Object>{
                'inProgressTrack' => inProgressTrack,
                'countCompleted' => countCompleted,
                'countServiceability' => countServiceability,
                'countProduct' => countProduct,
                'countContact' => countContact
            };
            return result;
        } catch (Exception exc) {
            throw new AuraHandledException(exc.getMessage());
        }
    }

    // Replace DRgetClickerLocationRecordType
    @AuraEnabled
    public static Id getClickerLocationRecordType() {
        try {
            Id clickerGeoCodeRecTypeId = Schema.SObjectType.maps__Location__c.getRecordTypeInfosByDeveloperName()
                .get(CLICKER_GEO_CODE_REC_TYPE)
                .getRecordTypeId();
            return clickerGeoCodeRecTypeId;
        } catch (Exception exc) {
            throw new AuraHandledException(exc.getMessage());
        }
    }

    // Replace DRgetClickerGeolocation
    @AuraEnabled
    public static maps__Location__c getClickerGeolocation(String userId, String recType) {
        try {
            maps__Location__c clickerGeoLocation = [
                SELECT Id, maps__Latitude__c, maps__Longitude__c, RecordTypeId
                FROM maps__Location__c
                WHERE OwnerId = :userId AND RecordTypeId = :recType
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            return clickerGeoLocation;
        } catch (Exception exc) {
            throw new AuraHandledException(exc.getMessage());
        }
    }

    // Replace DRgetMapsLocationRecordType
    @AuraEnabled
    public static Id getMapsLocationRecordType() {
        try {
            Id trackingGeoCodeRecTypeId = Schema.SObjectType.maps__Location__c.getRecordTypeInfosByDeveloperName()
                .get(TRACKING_GEO_CODE_REC_TYPE)
                .getRecordTypeId();
            return trackingGeoCodeRecTypeId;
        } catch (Exception exc) {
            throw new AuraHandledException(exc.getMessage());
        }
    }

    // Replace DRsaveGeoLocation
    @AuraEnabled
    public static maps__Location__c saveGeoLocation(
        String origin,
        String subOrigin,
        Id recordType,
        maps__Location__c location
    ) {
        try {
            maps__Location__c geoLocation = new maps__Location__c();
            geoLocation.POE_GeoCode_Origin__c = origin != null ? origin : CLICKER_PAGE;
            geoLocation.POE_GeoCode_Sub_Origin__c = subOrigin != null ? subOrigin : PLUS_BUTTON;
            geoLocation.RecordTypeId = recordType;
            geoLocation.maps__Latitude__c = location.maps__Latitude__c;
            geoLocation.maps__Longitude__c = location.maps__Longitude__c;

            insert geoLocation;
            return geoLocation;
        } catch (Exception exc) {
            throw new AuraHandledException(exc.getMessage());
        }
    }

    // Save Geo Code Tracking - replace saveGeoCodeTracking IP
    @AuraEnabled
    public static maps__Location__c saveGeoCodeTracking(String userId) {
        try {
            Id clickerRecType = getClickerLocationRecordType();
            maps__Location__c clickerGeoLocation = getClickerGeolocation(userId, clickerRecType);

            Id trackingRecType = getMapsLocationRecordType();
            maps__Location__c geoLocation = saveGeoLocation(
                CLICKER_PAGE,
                PLUS_BUTTON,
                trackingRecType,
                clickerGeoLocation
            );

            return geoLocation;
        } catch (Exception exc) {
            throw new AuraHandledException(exc.getMessage());
        }
    }

    // Get Session Type - Used to detect Community Builder context
    @AuraEnabled
    public static String getCurrentSessionType() {
        try {
            Map<String, String> currentSessionAttributes = Auth.SessionManagement.getCurrentSession();
            String sessionType = currentSessionAttributes.get('SessionType');
            return sessionType;
        } catch (Exception exc) {
            throw new AuraHandledException(exc.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, Object> getClickerMDUTrack(Id userId, Date searchDate) {
        try {
            String inProgressMDU;
            String mdu;
            String mduId;
            String FFLcode;
            String NFFLcode;
            Integer countCompleted;
            Integer countServiceability;
            Integer countProduct;
            Integer countContact;
            if (searchDate == null) {
                searchDate = System.today();
            }
            if (userId == null) {
                userId = UserInfo.getUserId();
            }

            List<MDU_Tracker__c> mduTrackLast = [
                SELECT
                    Id,
                    CreatedById,
                    Date__c,
                    IsCount__c,
                    Action__c,
                    MDU_CHUZO__c,
                    MDU_CHUZO__r.Name,
                    MDU_CHUZO__r.DIRECTV_Dealer_Code_FFL__c,
                    MDU_CHUZO__r.DIRECTV_Dealer_Code_NFFL__c
                FROM MDU_Tracker__c
                WHERE CreatedById = :userId AND Date__c = :searchDate AND MDU_CHUZO__c != NULL
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            List<MDU_Tracker__c> mduTrackInProgress = [
                SELECT
                    Id,
                    CreatedById,
                    Date__c,
                    IsCount__c,
                    Action__c,
                    MDU_CHUZO__c,
                    MDU_CHUZO__r.Name,
                    MDU_CHUZO__r.DIRECTV_Dealer_Code_FFL__c,
                    MDU_CHUZO__r.DIRECTV_Dealer_Code_NFFL__c
                FROM MDU_Tracker__c
                WHERE CreatedById = :userId AND IsCount__c = TRUE
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            List<MDU_Tracker__c> mduTracks = [
                SELECT
                    Id,
                    CreatedById,
                    Date__c,
                    IsCount__c,
                    Action__c,
                    MDU_CHUZO__c,
                    MDU_CHUZO__r.Name,
                    MDU_CHUZO__r.DIRECTV_Dealer_Code_FFL__c,
                    MDU_CHUZO__r.DIRECTV_Dealer_Code_NFFL__c
                FROM MDU_Tracker__c
                WHERE CreatedById = :userId AND Date__c = :searchDate AND IsCount__c = TRUE
            ];
            List<MDU_Tracker__c> mduTrackContact = new List<MDU_Tracker__c>();
            List<MDU_Tracker__c> mduTrackServiceability = new List<MDU_Tracker__c>();
            List<MDU_Tracker__c> mduTrackProduct = new List<MDU_Tracker__c>();
            List<MDU_Tracker__c> mduTrackCompleted = new List<MDU_Tracker__c>();

            for (MDU_Tracker__c mduTrack : mduTracks) {
                switch on mduTrack.Action__c {
                    when 'Contact' {
                        mduTrackContact.add(mduTrack);
                    }
                    when 'Serviceability Check' {
                        mduTrackServiceability.add(mduTrack);
                    }
                    when 'Product Selection' {
                        mduTrackProduct.add(mduTrack);
                    }
                    when 'Buyflow Completed' {
                        mduTrackCompleted.add(mduTrack);
                    }
                }
            }

            countContact = mduTrackContact.size();
            countServiceability = mduTrackServiceability.size();
            countProduct = mduTrackProduct.size();
            countCompleted = mduTrackCompleted.size();
            inProgressMDU = !mduTrackInProgress.isEmpty() ? mduTrackInProgress[0].Id : null;
            if (!mduTrackLast.isEmpty()) {
                mduId = mduTrackLast[0].MDU_CHUZO__c;
                mdu = mduTrackLast[0].MDU_CHUZO__r.Name;
                FFLcode = mduTrackLast[0].MDU_CHUZO__r.DIRECTV_Dealer_Code_FFL__c;
                NFFLcode = mduTrackLast[0].MDU_CHUZO__r.DIRECTV_Dealer_Code_NFFL__c;
            }

            Map<String, Object> result = new Map<String, Object>{
                'inProgressMDU' => inProgressMDU,
                'mdu' => mdu,
                'mduId' => mduId,
                'NFFLcode' => NFFLcode,
                'FFLcode' => FFLcode,
                'countCompleted' => countCompleted,
                'countServiceability' => countServiceability,
                'countProduct' => countProduct,
                'countContact' => countContact
            };
            return result;
        } catch (Exception exc) {
            throw new AuraHandledException(exc.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, Object> getMDU() {
        try {
            Map<String, Object> result;
            Id userId = UserInfo.getUserId();
            User userRecord = [SELECT Partner_Account_Id__c FROM User WHERE Id = :userId];
            List<DealerMDU__c> dealer = [
                SELECT Dealer__c, MDU_Chuzo__c
                FROM DealerMDU__c
                WHERE Dealer__c = :userRecord.Partner_Account_Id__c
            ];
            Set<Id> mduIds = new Set<Id>();
            if (dealer.isEmpty()) {
                result = new Map<String, Object>{ 'error' => 'No Dealer MDUs found' };
                return result;
            } else {
                for (DealerMDU__c dealerRecord : dealer) {
                    mduIds.add(dealerRecord.MDU_Chuzo__c);
                }
            }
            List<MDU_Chuzo__c> mdus = [SELECT Id, Name FROM MDU_Chuzo__c WHERE Id IN :mduIds AND Status__c = 'Active'];
            if (mdus.isEmpty()) {
                result = new Map<String, Object>{ 'error' => 'No MDUs found' };
                return result;
            }
            result = new Map<String, Object>{
                'User' => userRecord,
                'Account' => userRecord.Partner_Account_Id__c,
                'DealerMDU' => dealer,
                'mdus' => mdus
            };
            return result;
        } catch (Exception exc) {
            throw new AuraHandledException(exc.getMessage());
        }
    }

    @AuraEnabled
    public static MDU_Tracker__c setClickerMDUTrack(
        String mdu,
        Boolean isCount,
        String action,
        Id trackId
    ) {
        try {
            MDU_Tracker__c clickerTrack = new MDU_Tracker__c(
                Action__c = action,
                MDU_Chuzo__c = mdu,
                IsCount__c = isCount
            );
            if (trackId != null && trackId != '') {
                clickerTrack.Id = trackId;
            }
            upsert clickerTrack;
            return clickerTrack;
        } catch (Exception exc) {
            throw new AuraHandledException(exc.getMessage());
        }
    }
}
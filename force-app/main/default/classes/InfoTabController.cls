public without sharing class InfoTabController {
    @AuraEnabled
    public static ResponseWrapper getAddressInfo(Map<String, Object> myData) {
        ResponseWrapper response = new ResponseWrapper();
        Map<String, Object> result = new Map<String, Object>();
        String recordId = (String) myData.get('Id');
        String program = (String) myData.get('Program');
        Boolean isGuestUser = Auth.CommunitiesUtil.isGuestUser();

        try {
            List<Opportunity> previousOpportunity = [
                SELECT
                    Id,
                    AccountId,
                    CloseDate,
                    Maps_Appartment__c,
                    Maps_AptNumber__c,
                    Maps_Building__c,
                    Maps_City__c,
                    Maps_Country__c,
                    Maps_Floor__c,
                    Maps_Latitude__c,
                    Maps_Longitude__c,
                    Maps_PostalCode__c,
                    Maps_State__c,
                    Maps_Street__c,
                    Name,
                    POE_Clicker_Event_Track__c,
                    POE_Clicker_Origin__c,
                    POE_Clicker_Retail_Track__c,
                    POE_Clicker_MDU_Track__c,
                    POE_Program__c,
                    POE_Reference_Number__c,
                    POE_ParentOpportunity__c,
                    POE_ParentOpportunity__r.AccountId,
                    StageName
                FROM Opportunity
                WHERE Id = :recordId
            ];

            List<RecordType> mapsLocationRT = [
                SELECT Id, DeveloperName
                FROM RecordType
                WHERE DeveloperName = 'TrackingGeoCode'
            ];

            if (!isGuestUser) {
                User currentUser = [
                    SELECT Id, Name, isOwner__c, ProfileId, Profile.Name
                    FROM User
                    WHERE Id = :System.UserInfo.getUserId()
                ];

                result.put('IsOwner', currentUser.isOwner__c);
                result.put('UserId', currentUser.Id);
                result.put('UserProfile', currentUser.Profile.Name);
            } else {
                Chuzo_Settings__c chuzoSettings = Chuzo_Settings__c.getOrgDefaults();
                result.put('isRedirectionEnabled', chuzoSettings.Redirection_Enabled_Partners__c.contains(program));
            }

            if (!previousOpportunity.isEmpty()) {
                if (
                    !String.isBlank(previousOpportunity[0].Maps_Appartment__c) &&
                    previousOpportunity[0].Maps_Appartment__c.contains('null')
                ) {
                    previousOpportunity[0].Maps_Appartment__c = '';
                }
                result.put('Opportunity', previousOpportunity[0]);
                String accId;
                if (previousOpportunity[0].POE_ParentOpportunity__c != null) {
                    accId = previousOpportunity[0].POE_ParentOpportunity__r.AccountId;
                } else {
                    accId = previousOpportunity[0].AccountId;
                }
                List<Account> accountData = [
                    SELECT Id, PersonEmail, FirstName, LastName, Phone
                    FROM Account
                    WHERE Id = :accId
                ];
                if (!accountData.isEmpty()) {
                    result.put('Contact', accountData[0]);
                }
            }

            if (!mapsLocationRT.isEmpty()) {
                result.put('GeoRecordType', mapsLocationRT[0].Id);
            }

            if (recordId != null && program != null) {
                updateOpportunityProgram(recordId, program);
            }

            response.result = result;

            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper saveGeoLocalization(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();

            Map<Object, Object> mapsLocationData = (Map<Object, Object>) myData.get('maps__Location__c');
            Decimal latitude = (Decimal) mapsLocationData.get('maps__Latitude__c');
            Decimal longitude = (Decimal) mapsLocationData.get('maps__Longitude__c');
            String geoCodeOrigin = (String) mapsLocationData.get('POE_GeoCode_Origin__c');
            String geoCodeSubOrigin = (String) mapsLocationData.get('POE_GeoCode_Sub_Origin__c');
            String rtId = (String) mapsLocationData.get('RecordTypeId');

            maps__Location__c mapsLocation = new maps__Location__c(
                maps__Latitude__c = latitude,
                maps__Longitude__c = longitude,
                POE_GeoCode_Origin__c = geoCodeOrigin,
                POE_GeoCode_Sub_Origin__c = geoCodeSubOrigin
            );

            if (rtId != null) {
                mapsLocation.RecordTypeId = rtId;
            }

            insert mapsLocation;

            Map<String, Object> result = new Map<String, Object>{ 'UpsertSuccess' => true, 'Id' => mapsLocation.Id };

            response.result = result;

            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper setClickerRetailTrack(Map<string, object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            Map<String, Object> result = new Map<String, Object>{
                'countCompleted' => 0,
                'countContact' => 0,
                'countProduct' => 0,
                'countServiceability' => 0
            };

            String operation = (String) myData.get('operation');
            String userId = (String) myData.get('userId');
            if (userId == null) {
                userId = UserInfo.getUserId();
            }
            Boolean isCount = (Boolean) myData.get('isCount');
            String store = (String) myData.get('store');
            String trackId = (String) myData.get('trackId');
            String action = (String) myData.get('action');

            result.put('FraudFlag', getFraudFlag());

            if (operation == 'setTrack') {
                POE_Clicker_Retail_Track__c retailTrack = new POE_Clicker_Retail_Track__c(
                    POE_isCount__c = isCount,
                    POE_Store__c = store,
                    POE_Action__c = action,
                    Id = trackId
                );

                upsert retailTrack;
            }

            POEInteractionTracker interationTracker = new POEInteractionTracker();
            interationTracker.invokeMethod(null, null, null, null);

            getTrackCounts('POE_Clicker_Retail_Track__c', userId, result);

            List<POE_Clicker_Retail_Track__c> retailTrackLast = [
                SELECT
                    Id,
                    POE_Store__r.Name,
                    POE_Store__r.POE_DTV_FFL__c,
                    POE_Store__r.POE_DTV_NFFL__c,
                    POE_Store__r.POE_Retail_National_Retail__c
                FROM POE_Clicker_Retail_Track__c
                WHERE POE_Store__c != '' AND CreatedById = :userId AND POE_Date__c = TODAY
                ORDER BY CreatedDate DESC
            ];
            if (!retailTrackLast.isEmpty()) {
                String FFLCode = retailTrackLast[0].POE_Store__r.POE_DTV_FFL__c != null
                    ? retailTrackLast[0].POE_Store__r.POE_DTV_FFL__c
                    : 'none';
                String NFFLCode = retailTrackLast[0].POE_Store__r.POE_DTV_NFFL__c != null
                    ? retailTrackLast[0].POE_Store__r.POE_DTV_NFFL__c
                    : 'none';

                result.put('store', retailTrackLast[0].POE_Store__r.Name);
                result.put('FFLcode', FFLCode);
                result.put('NFFLcode', NFFLCode);
                result.put('storeType', retailTrackLast[0].POE_Store__r.POE_Retail_National_Retail__c);
            }

            POE_Clicker_Retail_Track__c trackInProgress = [
                SELECT Id
                FROM POE_Clicker_Retail_Track__c
                WHERE CreatedById = :userId AND POE_isCount__c = TRUE
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            result.put('inProgressRetail', trackInProgress.Id);

            response.result = result;

            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper setClickerMDUTrack(Map<string, object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            Map<String, Object> result = new Map<String, Object>{
                'countCompleted' => 0,
                'countContact' => 0,
                'countProduct' => 0,
                'countServiceability' => 0
            };

            String operation = (String) myData.get('operation');
            String userId = (String) myData.get('userId');
            if (userId == null) {
                userId = UserInfo.getUserId();
            }
            Boolean isCount = (Boolean) myData.get('isCount');
            String mduId = (String) myData.get('mduId');
            String trackId = (String) myData.get('trackId');
            String action = (String) myData.get('action');

            result.put('FraudFlag', getFraudFlag());

            if (operation == 'setTrack') {
                MDU_Tracker__c mduTrack = new MDU_Tracker__c(
                    IsCount__c = isCount,
                    MDU_CHUZO__c = mduId,
                    Action__c = action,
                    Id = trackId
                );
                upsert mduTrack;
            }
            POEInteractionTracker interationTracker = new POEInteractionTracker();
            interationTracker.invokeMethod(null, null, null, null);
            getTrackCounts('MDU_Tracker__c', userId, result);

            System.debug('Querying last MDU track');
            List<MDU_Tracker__c> mduTrackLast = [
                SELECT
                    Id,
                    MDU_CHUZO__r.Name,
                    MDU_CHUZO__r.DIRECTV_Dealer_Code_FFL__c,
                    MDU_CHUZO__r.DIRECTV_Dealer_Code_NFFL__c
                FROM MDU_Tracker__c
                WHERE MDU_CHUZO__c != '' AND CreatedById = :userId AND Date__c = TODAY
                ORDER BY CreatedDate DESC
            ];
            if (!mduTrackLast.isEmpty()) {
                String FFLCode = mduTrackLast[0].MDU_CHUZO__r.DIRECTV_Dealer_Code_FFL__c != null
                    ? mduTrackLast[0].MDU_CHUZO__r.DIRECTV_Dealer_Code_FFL__c
                    : 'none';
                String NFFLCode = mduTrackLast[0].MDU_CHUZO__r.DIRECTV_Dealer_Code_NFFL__c != null
                    ? mduTrackLast[0].MDU_CHUZO__r.DIRECTV_Dealer_Code_NFFL__c
                    : 'none';

                result.put('mdu', mduTrackLast[0].MDU_CHUZO__r.Name);
                result.put('FFLcode', FFLCode);
                result.put('NFFLcode', NFFLCode);
            }
            List<MDU_Tracker__c> trackInProgressList = [
                SELECT Id
                FROM MDU_Tracker__c
                WHERE CreatedById = :userId AND IsCount__c = TRUE
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            if (!trackInProgressList.isEmpty()) {
                result.put('inProgressMDU', trackInProgressList[0].Id);
            }
            response.result = result;
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper setClickerEventTrack(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            Map<String, Object> result = new Map<String, Object>{
                'countCompleted' => 0,
                'countContact' => 0,
                'countProduct' => 0,
                'countServiceability' => 0
            };

            String operation = (String) myData.get('operation');
            String userId = (String) myData.get('userId');
            if (userId == null) {
                userId = UserInfo.getUserId();
            }
            Boolean isCount = (Boolean) myData.get('isCount');
            String event = (String) myData.get('event');
            String trackId = (String) myData.get('trackId');
            String action = (String) myData.get('action');

            result.put('FraudFlag', getFraudFlag());

            if (operation == 'setTrack') {
                POE_Clicker_Event_Track__c eventTrack = new POE_Clicker_Event_Track__c(
                    POE_isCount__c = isCount,
                    POE_Event__c = event,
                    Action__c = action,
                    Id = trackId
                );

                upsert eventTrack;
            }

            POEInteractionTracker interationTracker = new POEInteractionTracker();
            interationTracker.invokeMethod(null, null, null, null);

            getTrackCounts('POE_Clicker_Event_Track__c', userId, result);

            List<POE_Clicker_Event_Track__c> eventTrackLast = [
                SELECT Id, POE_Event__r.Name
                FROM POE_Clicker_Event_Track__c
                WHERE POE_Event__c != '' AND CreatedById = :userId AND POE_Date_c__c = TODAY
                ORDER BY CreatedDate DESC
            ];
            if (!eventTrackLast.isEmpty()) {
                result.put('event', eventTrackLast[0].POE_Event__r.Name);
            }

            POE_Clicker_Event_Track__c trackInProgress = [
                SELECT Id
                FROM POE_Clicker_Event_Track__c
                WHERE CreatedById = :userId AND POE_isCount__c = TRUE
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            result.put('inProgressEvent', trackInProgress.Id);

            response.result = result;

            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Boolean getDirecTVRestriction(Id accountId) {
        User agent = [
            SELECT Account.DIRECTV_Via_Satellite_Restriction__c
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        return agent.Account.DIRECTV_Via_Satellite_Restriction__c;
    }

    @AuraEnabled
    public static ResponseWrapper setClickerCallCenterTrack(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            Map<String, Object> result = new Map<String, Object>{
                'countCompleted' => 0,
                'countContact' => 0,
                'countProduct' => 0,
                'countServiceability' => 0
            };

            String operation = (String) myData.get('operation');
            String userId = (String) myData.get('userId');
            Boolean isCount = (Boolean) myData.get('isCount');
            String trackId = (String) myData.get('trackId');
            String action = (String) myData.get('action');

            result.put('FraudFlag', getFraudFlag());

            if (operation == 'setTrack') {
                POE_Clicker_Call_Center_Track__c ccTrack = new POE_Clicker_Call_Center_Track__c(
                    Action__c = action,
                    Id = trackId
                );

                upsert ccTrack;
            }

            POEInteractionTracker interationTracker = new POEInteractionTracker();
            interationTracker.invokeMethod(null, null, null, null);

            getTrackCounts('POE_Clicker_Call_Center_Track__c', userId, result);

            POE_Clicker_Call_Center_Track__c trackInProgress = [
                SELECT Id
                FROM POE_Clicker_Call_Center_Track__c
                WHERE CreatedById = :userId AND POE_Date__c = TODAY
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            result.put('inProgressTrack', trackInProgress.Id);

            response.result = result;

            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper saveOpportunityAddressInformation(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            Decimal latitude = (Decimal) myData.get('latitude');
            Decimal longitude = (Decimal) myData.get('longitude');
            String origin;
            Boolean productDisplay = (myData.containsKey('productDisplay') && myData.get('productDisplay') != null)
                ? (Boolean) myData.get('productDisplay')
                : false;
            String inProgressEvent = (String) myData.get('inProgressEvent');
            String inProgressRetail = (String) myData.get('inProgressRetail');
            String inProgressMDU = (String) myData.get('inProgressMDU');
            Boolean contact = (Boolean) myData.get('contact');
            Map<Object, Object> opp = (Map<Object, Object>) myData.get('opportunity');
            String country = (String) opp.get('Maps_Country__c');
            String postalCode = (String) opp.get('Maps_PostalCode__c');
            String street = (String) opp.get('Maps_Street__c');
            String apt = (String) opp.get('Maps_Appartment__c');
            String state = (String) opp.get('Maps_State__c');
            String city = (String) opp.get('Maps_City__c');
            String externalAgentId = (String) opp.get('External_Agent_Id__c');
            String dealerCode = (String) opp.get('POE_DTV_Program_Selected__c');
            String externalSessionId = (String) opp.get('External_Session_Id__c');
            String name = (String) opp.get('Name');
            String stageName = (String) opp.get('StageName');
            String oppId = (String) opp.get('Id');
            String availablePrograms = (String) opp.get('Available_Programs__c');
            String referralCodeId = (String) opp.get('referralCodeId');
            String program = (String) opp.get('Program');
            Boolean isGuestUser = Auth.CommunitiesUtil.isGuestUser();
            String standardRecordTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
                .get('Standard_Opportunity')
                .getRecordTypeId();
            List<POE_ProgramZipCode__c> programsByZipCode = new List<POE_ProgramZipCode__c>();
            Map<String, Map<String, Object>> contactPrograms = new Map<String, Map<String, Object>>();
            Map<String, Map<String, Object>> accountPrograms = new Map<String, Map<String, Object>>();
            List<Program_Sales_Restriction__c> programRestrictions = new List<Program_Sales_Restriction__c>();
            List<AggregateResult> salesStatistics = new List<AggregateResult>();

            if (isGuestUser) {
                origin = 'Self Service';
            } else {
                origin = (String) myData.get('origin');
            }

            List<Opportunity> existingOppList = [
                SELECT
                    Id,
                    Name,
                    POE_Clicker_Origin__c,
                    POE_Clicker_Event_Track__c,
                    POE_Clicker_Retail_Track__c,
                    Available_Programs__c,
                    CloseDate,
                    External_Agent_Id__c,
                    External_Session_Id__c,
                    Maps_Appartment__c,
                    Maps_City__c,
                    Maps_Country__c,
                    Maps_PostalCode__c,
                    Maps_State__c,
                    Maps_Street__c,
                    StageName
                FROM Opportunity
                WHERE Id = :oppId
            ];
            Opportunity newOpportunity = existingOppList.size() > 0 ? existingOppList[0] : new Opportunity();
            if (String.isNotBlank(referralCodeId)) {
                newOpportunity.Referral_Code__c = referralCodeId;
            }
            newOpportunity.POE_Clicker_Origin__c = origin;
            newOpportunity.POE_Clicker_Event_Track__c = inProgressEvent;
            newOpportunity.POE_Clicker_Retail_Track__c = inProgressRetail;
            if (String.isBlank(newOpportunity.Available_Programs__c)) {
                newOpportunity.Available_Programs__c = availablePrograms;
            }
            newOpportunity.CloseDate = Date.today();
            if (!String.isBlank(externalAgentId)) {
                newOpportunity.External_Agent_Id__c = externalAgentId;
            }
            if (!String.isBlank(externalSessionId)) {
                newOpportunity.External_Session_Id__c = externalSessionId;
            }
            if (!String.isBlank(dealerCode)) {
                newOpportunity.POE_DTV_Program_Selected__c = dealerCode;
            }
            newOpportunity.Maps_Appartment__c = productDisplay && String.isBlank(apt)
                ? newOpportunity.Maps_Appartment__c
                : apt;
            newOpportunity.Maps_City__c = String.isNotBlank(city) ? city : newOpportunity.Maps_City__c;
            newOpportunity.Maps_Country__c = country;
            newOpportunity.Maps_PostalCode__c = postalCode;
            newOpportunity.Maps_State__c = String.isNotBlank(state) ? state : newOpportunity.Maps_State__c;
            newOpportunity.Maps_Street__c = String.isNotBlank(street) ? street : newOpportunity.Maps_Street__c;
            newOpportunity.Name = name;
            newOpportunity.StageName = stageName;
            if (String.isNotBlank(program)) {
                newOpportunity.POE_Program__c = program;
            }
            newOpportunity.recordTypeId = standardRecordTypeID;
            upsert newOpportunity;

            if (!isGuestUser) {
                programsByZipCode = [
                    SELECT Id, Price__c, Program__c, Speed__c
                    FROM POE_ProgramZipCode__c
                    WHERE Zip_Code__c = :postalCode
                ];

                User currentUser = [
                    SELECT
                        Id,
                        Account.POE_Programs_available__c,
                        Account.Frontier_Only__c,
                        AccountId,
                        Contact.D2D_Programs__c,
                        Contact.POE_Blacklisted_Programs__c,
                        Contact.POE_Event_Programs__c,
                        Contact.POE_Programs_available__c,
                        Contact.POE_Retail_Programs__c,
                        Contact.MDU_Programs_Available__c,
                        ContactId
                    FROM User
                    WHERE Id = :System.UserInfo.getUserId()
                ];

                Map<String, Object> inputData = new Map<String, Object>{
                    'ContextId' => newOpportunity.Id,
                    'latitude' => latitude,
                    'longitude' => longitude,
                    'origin' => origin
                };

                programRestrictions = [
                    SELECT Id, Limit__c, Program__c, Start_Date__c, End_Date__c, Notified__c, Limit_Reached__c
                    FROM Program_Sales_Restriction__c
                    WHERE Account__c = :currentUser.AccountId
                ];

                Date earliestStartDate = null;
                Date latestEndDate = null;
                for (Program_Sales_Restriction__c restriction : programRestrictions) {
                    if (restriction.Start_Date__c != null) {
                        if (earliestStartDate == null || restriction.Start_Date__c < earliestStartDate) {
                            earliestStartDate = restriction.Start_Date__c;
                        }
                    }
                    if (restriction.End_Date__c != null) {
                        if (latestEndDate == null || restriction.End_Date__c > latestEndDate) {
                            latestEndDate = restriction.End_Date__c;
                        }
                    }
                }
                if (earliestStartDate != null && latestEndDate != null) {
                    salesStatistics = [
                        SELECT COUNT(Id), POE_Program__c
                        FROM Order
                        WHERE
                            POE_Dealer__c = :currentUser.AccountId
                            AND Status != 'Draft'
                            AND CreatedDate >= :earliestStartDate
                            AND CreatedDate < :latestEndDate.addDays(1)
                        GROUP BY POE_Program__c
                    ];
                } else {
                    salesStatistics = [
                        SELECT COUNT(Id), POE_Program__c
                        FROM Order
                        WHERE CreatedDate = THIS_MONTH AND POE_Dealer__c = :currentUser.AccountId AND Status != 'Draft'
                        GROUP BY POE_Program__c
                    ];
                }

                POE_SaveACIVlocity ACIVlocity = new POE_SaveACIVlocity();
                ACIVlocity.invokeMethod(null, inputData, null, null);

                contactPrograms.put(
                    'Contact',
                    new Map<String, Object>{
                        'D2D_Programs__c' => currentUser.Contact.D2D_Programs__c,
                        'POE_Retail_Programs__c' => currentUser.Contact.POE_Retail_Programs__c,
                        'MDU_Programs_Available__c' => currentUser.Contact.MDU_Programs_Available__c,
                        'POE_Event_Programs__c' => currentUser.Contact.POE_Event_Programs__c,
                        'POE_Programs_Available__c' => currentUser.Contact.POE_Programs_Available__c
                    }
                );
                contactPrograms.put('User', new Map<String, Object>{ 'ContactId' => currentUser.ContactId });

                accountPrograms.put(
                    'Account',
                    new Map<String, Object>{
                        'POE_Programs_available__c' => currentUser.Account.POE_Programs_available__c,
                        'Frontier_Only__c' => currentUser.Account.Frontier_Only__c
                    }
                );
                accountPrograms.put('User', new Map<String, Object>{ 'AccountId' => currentUser.AccountId });
            } else {
                programsByZipCode = [
                    SELECT Id, Price__c, Program__c, Speed__c
                    FROM POE_ProgramZipCode__c
                    WHERE Zip_Code__c = :postalCode AND Available_In_Self_Service__c = TRUE
                ];
            }

            newOpportunity.StageName = 'Contact';
            update newOpportunity;

            Map<String, List<POE_ProgramZipCode__c>> zipCodePrograms = new Map<String, List<POE_ProgramZipCode__c>>{
                'Programs' => programsByZipCode
            };

            Map<String, Object> result = new Map<String, Object>{
                'opportunityId' => newOpportunity.Id,
                'accountPrograms' => accountPrograms,
                'zipCodePrograms' => zipCodePrograms,
                'contactPrograms' => contactPrograms,
                'programRestrictions' => programRestrictions,
                'salesStatistics' => salesStatistics
            };
            response.result = result;
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static boolean getFraudFlag() {
        User currentUser = [SELECT Id, POE_FraudObservation__c FROM User WHERE Id = :System.UserInfo.getUserId()];
        return currentUser.POE_FraudObservation__c;
    }

    private static void getTrackCounts(String objectName, String userId, Map<String, Object> result) {
        String actionField;
        String dateField;
        String countField;
        if (objectName == 'POE_Clicker_Retail_Track__c') {
            actionField = 'POE_Action__c';
            dateField = 'POE_Date__c';
            countField = 'POE_isCount__c';
        } else if (objectName == 'POE_Clicker_Event_Track__c') {
            actionField = 'Action__c';
            dateField = 'POE_Date_c__c';
            countField = 'POE_isCount__c';
        } else if (objectName == 'MDU_Tracker__c') {
            actionField = 'Action__c';
            dateField = 'Date__c';
            countField = 'isCount__c';
        } else {
            actionField = 'Action__c';
            dateField = 'POE_Date__c';
            countField = 'POE_isCount__c';
        }
        String query =
            'SELECT COUNT(Id) trackCount, ' +
            actionField +
            ' FROM ' +
            objectName +
            ' WHERE CreatedById = :userId ' +
            'AND ' +
            dateField +
            ' = TODAY ';

        if (objectName != 'POE_Clicker_Call_Center_Track__c') {
            query += 'AND ' + countField + ' = true ';
        }

        query += 'GROUP BY ' + actionField;

        List<AggregateResult> trackCounts = Database.query(query);

        for (AggregateResult aggre : trackCounts) {
            String currentaction = (String) aggre.get(actionField);
            switch on currentaction {
                when 'Contact' {
                    result.put('countContact', aggre.get('trackCount'));
                }
                when 'Serviceability Check' {
                    result.put('countServiceability', aggre.get('trackCount'));
                }
                when 'Product Selection' {
                    result.put('countProduct', aggre.get('trackCount'));
                }
                when 'Buyflow Completed' {
                    result.put('countCompleted', aggre.get('trackCount'));
                }
            }
        }
    }

    private static void updateOpportunityProgram(String recordId, String program) {
        Opportunity opp = new Opportunity(Id = recordId, POE_Program__c = program);
        update opp;
    }

    @AuraEnabled
    public static String saveACIPresentation(String request) {
        Map<String, Object> myData = (Map<String, Object>) JSON.deserializeUntyped(request);
        try {
            ResponseWrapper response = new ResponseWrapper();
            String serializedResponse;
            Map<String, Object> resultMap = new Map<String, Object>();
            String oppId = (String) myData.get('ContextId');
            POE_ACI_Statistic__c aciStatisticRecord = new POE_ACI_Statistic__c();
            Boolean isGuestUser = Auth.CommunitiesUtil.isGuestUser();

            List<Opportunity> opportunity = [
                SELECT StageName, POE_Clicker_Origin__c
                FROM Opportunity
                WHERE Id = :oppId
            ];
            opportunity[0].StageName = 'DM';
            update (opportunity);

            if (!isGuestUser) {
                List<POE_ACI_Statistic__c> aciStatistic = [
                    SELECT Id, Product_Selection__c, Presentation__c
                    FROM POE_ACI_Statistic__c
                    WHERE Opportunity__c = :oppId
                ];

                if (!aciStatistic.isEmpty()) {
                    aciStatisticRecord = aciStatistic[0];
                }

                if (!opportunity.isEmpty() && opportunity[0].POE_Clicker_Origin__c == 'retail') {
                    List<POE_Clicker_Retail_Track__c> retail = [
                        SELECT POE_Store__c
                        FROM POE_Clicker_Retail_Track__c
                        WHERE OwnerId = :UserInfo.getUserId() AND CreatedDate = TODAY AND POE_Store__c != NULL
                    ];
                    if (!retail.isEmpty()) {
                        POE_Retail_Store__c store = [
                            SELECT Name, Location__latitude__s, Location__longitude__s
                            FROM POE_Retail_Store__c
                            WHERE Id = :retail[0].POE_Store__c
                            LIMIT 1
                        ];
                        aciStatisticRecord.Store__c = store.Id;
                    }
                } else if (!opportunity.isEmpty() && opportunity[0].POE_Clicker_Origin__c == 'mdu') {
                    List<MDU_Tracker__c> tracker = [
                        SELECT MDU_Chuzo__c
                        FROM MDU_Tracker__c
                        WHERE OwnerId = :UserInfo.getUserId() AND CreatedDate = TODAY AND MDU_Chuzo__c != NULL
                    ];
                    if (!tracker.isEmpty()) {
                        MDU_Chuzo__c mdu = [
                            SELECT Name, Location__latitude__s, Location__longitude__s
                            FROM MDU_Chuzo__c
                            WHERE Id = :tracker[0].MDU_Chuzo__c
                            LIMIT 1
                        ];
                        aciStatisticRecord.MDU_Chuzo__c = mdu.Id;
                    }
                }

                aciStatisticRecord.Presentation__c = 1;
                aciStatisticRecord.Opportunity__c = oppId;

                upsert (aciStatisticRecord);
            }

            Map<String, Object> result = new Map<String, Object>{ 'Status' => 'Success' };
            response.result = result;
            serializedResponse = JSON.serialize(response);
            return serializedResponse;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Opportunity> getQuoteResumeData(String opportunityId) {
        try {
            List<Opportunity> result;

            Opportunity opp = [SELECT Id, Tab_Reached__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];

            if (String.isBlank(opp.Tab_Reached__c)) {
                opp.Tab_Reached__c = 'Info';
                opp.Id = opportunityId;
                update opp;
            }

            Chuzo_Settings__c settings = Chuzo_Settings__c.getOrgDefaults();

            if (settings.Frontier_Quote_Resume_Project__c) {
                User currentUser = [
                    SELECT Id, AccountId, Contact.POE_Functional_Role__c
                    FROM User
                    WHERE Id = :UserInfo.getUserId()
                ];

                Set<String> ownerRoles = new Set<String>{ 'Office Manager', 'Sales Manager', 'Team Lead' };
                Boolean isOwner = ownerRoles.contains(currentUser.Contact.POE_Functional_Role__c);

                if (isOwner) {
                    result = [
                        SELECT
                            Id,
                            CreatedDate,
                            StageName,
                            Frontier_Quote_ID__c,
                            Frontier_Quote_Number__c,
                            Frontier_BTN__c,
                            Maps_Appartment__c,
                            Maps_City__c,
                            Maps_PostalCode__c,
                            Maps_State__c,
                            Maps_Street__c,
                            Account.FirstName,
                            Account.MiddleName,
                            Account.LastName,
                            Account.Phone,
                            Account.PersonEmail,
                            POE_Clicker_Origin__c,
                            POE_Identification_Method__c,
                            Referral_Code__c,
                            Tab_Reached__c,
                            Account.ShippingPostalCode,
                            Account.ShippingCity,
                            Account.ShippingStreet,
                            Account.ShippingStateCode,
                            Account.Shipping_Address_Line_2__c,
                            Account.BillingPostalCode,
                            Account.BillingCity,
                            Account.BillingStreet,
                            Account.BillingStateCode,
                            Account.Billing_Address_Line_2__c,
                            Account.Consent_to_Automated_Communications__c,
                            AutoPay__c,
                            Ebill_Registration__c,
                            Frontier_911_Terms_Sent__c,
                            Full_Credit_Check__c
                        FROM Opportunity
                        WHERE
                            POE_Dealer__c = :currentUser.AccountId
                            AND CreatedDate >= LAST_N_DAYS:15
                            AND StageName != 'Order Created'
                            AND Frontier_Quote_ID__c != NULL
                            AND Frontier_Quote_Number__c != NULL
                        ORDER BY CreatedDate DESC
                    ];
                } else {
                    result = [
                        SELECT
                            Id,
                            CreatedDate,
                            StageName,
                            Frontier_Quote_ID__c,
                            Frontier_Quote_Number__c,
                            Frontier_BTN__c,
                            Maps_Appartment__c,
                            Maps_City__c,
                            Maps_PostalCode__c,
                            Maps_State__c,
                            Maps_Street__c,
                            Account.FirstName,
                            Account.MiddleName,
                            Account.LastName,
                            Account.Phone,
                            Account.PersonEmail,
                            POE_Clicker_Origin__c,
                            Referral_Code__c,
                            Tab_Reached__c,
                            Account.ShippingPostalCode,
                            Account.ShippingCity,
                            Account.ShippingStreet,
                            Account.ShippingStateCode,
                            Account.Shipping_Address_Line_2__c,
                            Account.BillingPostalCode,
                            Account.BillingCity,
                            Account.BillingStreet,
                            Account.BillingStateCode,
                            Account.Billing_Address_Line_2__c,
                            Account.Consent_to_Automated_Communications__c,
                            AutoPay__c,
                            Ebill_Registration__c,
                            Frontier_911_Terms_Sent__c,
                            Full_Credit_Check__c
                        FROM Opportunity
                        WHERE
                            OwnerId = :currentUser.Id
                            AND CreatedDate >= LAST_N_DAYS:15
                            AND StageName != 'Order Created'
                            AND Frontier_Quote_ID__c != NULL
                            AND Frontier_Quote_Number__c != NULL
                        ORDER BY CreatedDate DESC
                    ];
                }
            }

            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper getCharterInformation(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String program = (String) myData.get('program');
            String programLabel = '';
            if (program == 'Spectrum API') {
                programLabel = 'Charter';
            } else {
                programLabel = program;
            }
            User runningUser = [
                SELECT Email, FirstName, LastName, Account.P10_Invoice_Account__c
                FROM User
                WHERE Id = :UserInfo.getUserId()
            ];
            POE_Providers_Identifier__mdt charterCredentials = [
                SELECT affiliate__c, salesId__c, url__c
                FROM POE_Providers_Identifier__mdt
                WHERE Label = :programLabel
                LIMIT 1
            ];
            String affiliateId = charterCredentials.affiliate__c;
            if (program == 'Charter' || program == 'Altice') {
                response.result = new Map<String, Object>{
                    'userEmail' => runningUser.Email,
                    'firstName' => runningUser.FirstName,
                    'lastName' => runningUser.LastName,
                    'url' => charterCredentials.url__c,
                    'salesId' => charterCredentials.salesId__c,
                    'affiliateId' => affiliateId
                };
            } else {
                String storeId = '';
                Boolean isGuestUser = Auth.CommunitiesUtil.isGuestUser();
                if (isGuestUser) {
                    Self_Service_Dealer_Codes__c setting = Self_Service_Dealer_Codes__c.getOrgDefaults();
                    storeId = setting.Spectrum_Store_ID__c;
                    response.result = new Map<String, Object>{ 'storeId' => storeId, 'userEmail' => 'test@test.com' };
                } else {
                    Chuzo_Settings__c setting = Chuzo_Settings__c.getOrgDefaults();
                    storeId = setting.Spectrum_Store_ID__c + '_' + runningUser.Account.P10_Invoice_Account__c;
                    response.result = new Map<String, Object>{
                        'storeId' => storeId,
                        'userEmail' => runningUser.Email,
                        'affiliateId' => affiliateId,
                        'salesId' => charterCredentials.salesId__c,
                        'brightspeedPartnerId' => setting.Brightspeed_Partner_ID__c
                    };
                }
            }
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper saveIframeClient(Map<String, Object> myData) {
        try {
            POEUpsertIframeClientData upsertIFrameClientData = new POEUpsertIframeClientData();
            ResponseWrapper response = new ResponseWrapper();

            myData.put('isCallOrder', myData.get('isCallOrder') != null ? myData.get('isCallOrder') : false);

            response.result = upsertIFrameClientData.upsertClient(myData, new Map<String, Object>(), null);

            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateAutoPay(Boolean autopay, Boolean ebill, String oppId, Boolean fullCreditCheck) {
        try {
            Opportunity opp = new Opportunity();
            opp.AutoPay__c = autopay;
            opp.Ebill_Registration__c = ebill;
            opp.Id = oppId;
            opp.Full_Credit_Check__c = fullCreditCheck;
            update opp;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper associateProductWithOrder(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String productName = (String) myData.get('name');
            String orderId = (String) myData.get('orderId');
            Boolean isConflictOrder = (Boolean) myData.get('isConflictOrder');

            Order order = [SELECT Id, Conflict_Order__c FROM Order WHERE Id = :orderId];
            if (isConflictOrder != null) {
                order.Conflict_Order__c = isConflictOrder;
                update order;
            }

            List<PricebookEntry> pricebookEntry = [
                SELECT Id, Name, UnitPrice
                FROM PricebookEntry
                WHERE Name = :productName
                ORDER BY LastModifiedDate DESC
            ];
            OrderItem newOrderItem = new OrderItem(
                OrderId = order.Id,
                PricebookEntryId = pricebookEntry[0].Id,
                UnitPrice = pricebookEntry[0].UnitPrice,
                Quantity = 1
            );
            insert newOrderItem;

            response.result = new Map<String, Object>{ 'OrderItem' => newOrderItem };
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper saveOpportunityStage(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String oppId = (String) myData.get('ContextId');
            Boolean isGuestUser = Auth.CommunitiesUtil.isGuestUser();

            Opportunity opp = [
                SELECT Id, StageName, POE_Outcome__c, POE_Sensitive_Data__c, POE_Credit_Card__c
                FROM Opportunity
                WHERE Id = :oppId
            ];
            opp.StageName = 'Order Created';
            opp.POE_Sensitive_Data__c = null;
            opp.POE_Credit_Card__c = null;
            opp.POE_Outcome__c = 'Closed Won';
            update opp;

            Order latestOrder = [
                SELECT
                    Id,
                    POE_AccountNumber__c,
                    POE_Early_Installation_Date__c,
                    POE_InstallationDate__c,
                    POE_OrderId__c,
                    POE_OrderNumber__c,
                    POE_Service_Reference__c,
                    Status,
                    POE_TransactionId__c
                FROM Order
                WHERE OpportunityId = :oppId
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            latestOrder.POE_AccountNumber__c = (String) myData.get('accountNumber');
            if (myData.get('earliestDate') != null && myData.get('earliestDate') != '') {
                latestOrder.POE_Early_Installation_Date__c = Date.valueOf(String.valueOf(myData.get('earliestDate')));
            }
            if (myData.get('installationDate') != null && myData.get('installationDate') != '') {
                latestOrder.POE_InstallationDate__c = Date.valueOf(String.valueOf(myData.get('installationDate')));
            }
            latestOrder.POE_OrderId__c = (String) myData.get('orderId');
            latestOrder.POE_OrderNumber__c = (String) myData.get('orderNumber');
            latestOrder.POE_Service_Reference__c = (String) myData.get('serviceReference');
            latestOrder.Status = 'Pending Installation';
            latestOrder.POE_TransactionId__c = (String) myData.get('transactionId');
            update latestOrder;

            if (!isGuestUser) {
                List<POE_ACI_Statistic__c> aciStatisticList = [
                    SELECT Id, Product_Selection__c, Order_Created__c, Credit_Check__c, Presentation__c, Contact__c
                    FROM POE_ACI_Statistic__c
                    WHERE Opportunity__c = :oppId
                    LIMIT 1
                ];
                POE_ACI_Statistic__c aciStatistic = aciStatisticList.size() > 0
                    ? aciStatisticList[0]
                    : new POE_ACI_Statistic__c();
                aciStatistic.Opportunity__c = oppId;
                aciStatistic.Product_Selection__c = 1;
                aciStatistic.Order_Created__c = 1;
                aciStatistic.Credit_Check__c = 1;
                aciStatistic.Presentation__c = 1;
                aciStatistic.Contact__c = 1;
                upsert aciStatistic;
            }

            response.result = new Map<String, Object>{ 'Opportunity' => opp };
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper updateOrderBillingAddress(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String orderId = (String) myData.get('orderId');
            String zip = (String) myData.get('zip');
            String street = (String) myData.get('street');
            String city = (String) myData.get('city');
            String state = (String) myData.get('state');

            Order order = [
                SELECT
                    Id,
                    BillingCity,
                    BillingState,
                    BillingStateCode,
                    BillingStreet,
                    BillingPostalCode,
                    Account.Id,
                    Account.BillingCity,
                    Account.BillingState,
                    Account.BillingStateCode,
                    Account.BillingStreet,
                    Account.BillingPostalCode
                FROM Order
                WHERE Id = :orderId
            ];
            order.BillingCity = city;
            order.BillingStateCode = state;
            order.BillingStreet = street;
            order.BillingPostalCode = zip;
            update order;

            Account account = order.Account;
            account.BillingCity = city;
            account.BillingStateCode = state;
            account.BillingStreet = street;
            account.BillingPostalCode = zip;
            update account;

            response.result = new Map<String, Object>{ 'Order' => order, 'Account' => account };
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper setAddressDiscrepancy(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String oppId = (String) myData.get('ContextId');

            Opportunity opp = [SELECT Id, POE_AddressDiscrepancy__c FROM Opportunity WHERE Id = :oppId];
            opp.POE_AddressDiscrepancy__c = true;
            update opp;

            response.result = new Map<String, Object>{ 'Opportunity' => opp };
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper addNewProduct(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String oppId = (String) myData.get('ContextId');

            Opportunity opp = [
                SELECT
                    AccountId,
                    CloseDate,
                    Maps_Appartment__c,
                    Maps_AptNumber__c,
                    Maps_Building__c,
                    Maps_City__c,
                    Maps_Country__c,
                    Maps_Floor__c,
                    Maps_PostalCode__c,
                    Maps_State__c,
                    Maps_Street__c,
                    Name,
                    POE_Clicker_Event_Track__c,
                    POE_Clicker_Origin__c,
                    POE_Clicker_Retail_Track__c,
                    POE_New_Product_Opportunity__c,
                    POE_ParentOpportunity__c,
                    StageName
                FROM Opportunity
                WHERE Id = :oppId
            ];
            opp.Id = null;
            opp.POE_ParentOpportunity__c = opp.POE_New_Product_Opportunity__c ? opp.POE_ParentOpportunity__c : oppId;
            opp.CloseDate = Date.today();
            opp.POE_New_Product_Opportunity__c = true;
            opp.StageName = 'Opportunity';
            insert opp;

            response.result = new Map<String, Object>{ 'Opportunity' => opp };
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getIPStackApiKey() {
        POE_Callout_Config_API__mdt config = POE_Callout_Config_API__mdt.getInstance('IPStack');
        return config.Password__c;
    }

    private static ResponseWrapper getIPStackData(String ipAddress) {
        ResponseWrapper response = new ResponseWrapper();
        response.result = new Map<String, Object>{
            'ip' => '0.0.0.0',
            'latitude' => 0.00,
            'longitude' => 0.00,
            'region_name' => 'NA',
            'country_code' => 'NA'
        };

        try {
            POE_Callout_Config_API__mdt config = POE_Callout_Config_API__mdt.getInstance('IPStack');
            String endpoint = config.URL__c + ipAddress + '?access_key=' + config.Password__c;

            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('Content-Type', 'application/json;charset=UTF-8');
            req.setTimeout(120000);

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                response.result = new Map<String, Object>{
                    'ip' => (String) data.get('ip'),
                    'latitude' => (Decimal) data.get('latitude'),
                    'longitude' => (Decimal) data.get('longitude'),
                    'region_name' => (String) data.get('region_name'),
                    'country_code' => (String) data.get('country_code')
                };
            }
        } catch (Exception e) {
        }
        return response;
    }

    @AuraEnabled
    public static ResponseWrapper getIPStackSettingsWithIP(String ipAddress) {
        return getIPStackData(ipAddress);
    }

    @AuraEnabled
    public static ResponseWrapper getIPStackSettings() {
        AuthSession session = [
            SELECT SourceIp
            FROM AuthSession
            WHERE UsersId = :UserInfo.getUserId()
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        return getIPStackData(session.SourceIp);
    }

    @AuraEnabled
    public static Boolean getRestrictedZips(String zipCode) {
        List<DIRECTV_Zip_Restriction__c> zips = [SELECT Name FROM DIRECTV_Zip_Restriction__c WHERE Name = :zipCode];
        return zips.isEmpty();
    }

    @AuraEnabled
    public static ResponseWrapper saveIPStatisticRecord(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String userId = (String) myData.get('userId');
            String oppId = (String) myData.get('ContextId');
            String ipAddress = (String) myData.get('ip');

            List<Opportunity> oppList = [SELECT Id, IP_Address__c FROM Opportunity WHERE Id = :oppId];
            if (oppList.size() > 0 && oppList[0].IP_Address__c != ipAddress) {
                Opportunity opp = oppList[0];
                opp.IP_Address__c = ipAddress;
                update opp;
            }

            User user = [SELECT ContactId FROM User WHERE Id = :userId];

            Fraud_Validation_Statistics__c ipStatistic = new Fraud_Validation_Statistics__c(
                Contact__c = user.ContactId,
                Last_Updated__c = Datetime.now(),
                Validation_Rule__c = 'Suspicious IP Address',
                IP_Address__c = ipAddress
            );
            insert ipStatistic;

            POEIPStatisticValidator ipStatisticValidator = new POEIPStatisticValidator();
            ipStatisticValidator.invokeMethod(
                'validateStatistic',
                new Map<String, Object>{ 'ContactId' => user.ContactId, 'State' => myData.get('state') },
                null,
                null
            );

            response.result = new Map<String, Object>{ 'statistic' => ipStatistic };
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper updateOnProbationValue(Boolean probation) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String userId = UserInfo.getUserId();
            User user = [SELECT Id, AccountId FROM User WHERE Id = :userId LIMIT 1];
            Account account = [SELECT Id, On_Probation__c FROM Account WHERE Id = :user.AccountId LIMIT 1];
            if (account.On_Probation__c != probation) {
                account.On_Probation__c = probation;
                update account;
            }
            response.result = new Map<String, Object>{ 'Account' => account };
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper getDealerCode(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String program = (String) myData.get('program');
            String origin = (String) myData.get('origin');
            List<POE_Dealer_Code__c> codes = new List<POE_Dealer_Code__c>();
            Boolean isGuestUser = Auth.CommunitiesUtil.isGuestUser();
            List<User> user = new List<User>();
            List<Account> account = new List<Account>();

            if (program.equals('Altice')) {
                Decimal zipCode = (Decimal) myData.get('zipCode');
                codes = [
                    SELECT Id, POE_Dealer_Code__c
                    FROM POE_Dealer_Code__c
                    WHERE POE_Provider__c = :program AND Zip_Code__c = :zipCode
                ];
                response.result = new Map<String, Object>{ 'Codes' => codes };
            } else {
                if (!isGuestUser) {
                    String userId = UserInfo.getUserId();
                    user = [SELECT Id, AccountId FROM User WHERE Id = :userId];
                    account = [SELECT Id, P10_Invoice_Account__c FROM Account WHERE Id = :user[0].AccountId];
                    String accountPVID = '';
                    if (!account.isEmpty() && account[0].P10_Invoice_Account__c != null) {
                        accountPVID = account[0].P10_Invoice_Account__c.toUpperCase();
                    }
                    codes = [
                        SELECT
                            Id,
                            POE_Dealer_Code__c,
                            POE_Program_Type__c,
                            POE_Affiliate_Id__c,
                            Frontier_PID__c,
                            Spectrum_Sales_Id__c
                        FROM POE_Dealer_Code__c
                        WHERE POE_Provider__c = :program AND POE_Account__c = :account[0].Id
                    ];
                    if (program.equals('Frontier')) {
                        if (origin == 'retail') {
                            codes.clear();
                            List<POE_Clicker_Retail_Track__c> store = [
                                SELECT POE_Store__r.POE_Dealer_Code__c, POE_Store__r.Frontier_PID__c
                                FROM POE_Clicker_Retail_Track__c
                                WHERE OwnerId = :UserInfo.getUserId() AND CreatedDate = TODAY AND POE_Store__c != NULL
                                ORDER BY CreatedDate DESC
                                LIMIT 1
                            ];
                            if (!store.isEmpty()) {
                                POE_Dealer_Code__c frontierCode = new POE_Dealer_Code__c();
                                frontierCode.POE_Dealer_Code__c = store[0].POE_Store__r.POE_Dealer_Code__c;
                                frontierCode.Frontier_PID__c = store[0].POE_Store__r.Frontier_PID__c;
                                codes.add(frontierCode);
                            }
                        } else if (origin == 'event') {
                            codes.clear();
                            List<POE_Clicker_Event_Track__c> event = [
                                SELECT POE_Event__r.Frontier_PID__c, POE_Event__r.Frontier_User_ID__c
                                FROM POE_Clicker_Event_Track__c
                                WHERE OwnerId = :UserInfo.getUserId() AND CreatedDate = TODAY AND POE_Event__c != NULL
                                ORDER BY CreatedDate DESC
                                LIMIT 1
                            ];
                            if (!event.isEmpty()) {
                                POE_Dealer_Code__c frontierCode = new POE_Dealer_Code__c();
                                frontierCode.POE_Dealer_Code__c = event[0].POE_Event__r.Frontier_User_ID__c;
                                frontierCode.Frontier_PID__c = event[0].POE_Event__r.Frontier_PID__c;
                                codes.add(frontierCode);
                            }
                        }
                    }
                } else {
                    Self_Service_Dealer_Codes__c dealerCodes = Self_Service_Dealer_Codes__c.getOrgDefaults();
                    if (program.equals('DirecTV')) {
                        POE_Dealer_Code__c fflCode = new POE_Dealer_Code__c();
                        fflCode.POE_Dealer_Code__c = dealerCodes.DTV_FFL__c;
                        fflCode.POE_Program_Type__c = 'FFL';
                        POE_Dealer_Code__c nfflCode = new POE_Dealer_Code__c();
                        nfflCode.POE_Dealer_Code__c = dealerCodes.DTV_NFFL__c;
                        nfflCode.POE_Program_Type__c = 'NFFL';
                        codes.add(fflCode);
                        codes.add(nfflCode);
                    } else if (program.equals('Frontier')) {
                        POE_Dealer_Code__c frontierCode = new POE_Dealer_Code__c();
                        frontierCode.POE_Dealer_Code__c = dealerCodes.Frontier__c;
                        codes.add(frontierCode);
                    } else if (program.equals('Viasat')) {
                        POE_Dealer_Code__c viasatCode = new POE_Dealer_Code__c();
                        viasatCode.POE_Dealer_Code__c = dealerCodes.Viasat__c;
                        codes.add(viasatCode);
                    }
                }
                response.result = new Map<String, Object>{ 'Codes' => codes, 'Account' => account, 'User' => user };
            }

            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper saveBuyflowTab(Map<String, Object> myData) {
        try {
            String oppId = (String) myData.get('oppId');
            String currentTab = (String) myData.get('tab');

            ResponseWrapper response = new ResponseWrapper();

            Opportunity opp = new Opportunity(Id = oppId, Tab_Reached__c = currentTab);

            update opp;

            Map<String, Object> result = new Map<String, Object>{ 'Opportunity' => opp };

            response.result = result;

            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper getOppReferenceNumber(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String oppId = (String) myData.get('ContextId');

            Opportunity opp = [
                SELECT Id, POE_Reference_Number__c, POE_QuantityOfAttempts__c
                FROM Opportunity
                WHERE Id = :oppId
            ];

            response.result = new Map<String, Object>{
                'referenceNumber' => opp.POE_Reference_Number__c,
                'attempts' => opp.POE_QuantityOfAttempts__c
            };
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper getDealerInfo(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            List<User> accs = [SELECT Id, LastName, Name, Account.Name FROM User WHERE Id = :UserInfo.getUserId()];
            if (!accs.isEmpty()) {
                Map<String, Object> users = new Map<String, Object>{
                    'LastName' => accs[0].LastName,
                    'Name' => accs[0].Name
                };
                Map<String, Object> accounts = new Map<String, Object>{ 'Name' => accs[0].Account.Name };

                response.result = new Map<String, Object>{ 'Users' => users, 'Accounts' => accounts };
            }
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static ResponseWrapper getEarthlinkPromoCodes() {
        try {
            ResponseWrapper response = new ResponseWrapper();
            Chuzo_Settings__c settings = Chuzo_Settings__c.getOrgDefaults();

            List<String> promoCodes = String.isBlank(settings.Earthlink_Promo_Codes__c)
                ? new List<String>()
                : settings.Earthlink_Promo_Codes__c.split(';');
            List<Map<String, String>> promoCodeMaps = new List<Map<String, String>>();
            for (String promoCode : promoCodes) {
                List<String> promoCodeInfo = promoCode.split(':');
                promoCodeMaps.add(new Map<String, String>{ 'label' => promoCodeInfo[0], 'value' => promoCodeInfo[1] });
            }

            response.result = new Map<String, Object>{ 'promoCodes' => promoCodeMaps };
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper getGeoCodeData(Map<String, Object> myData) {
        String address = (String) myData.get('address');

        Map<string, object> options = new Map<String, Object>{ 'version' => '1', 'address' => address };
        ResponseWrapper response = new ResponseWrapper();

        if (!Test.isRunningTest()) {
            response.result = maps.API.Geocode(options);
        } else {
            Map<String, Object> position = new Map<String, Object>();
            position.put('lat', 37.7897784);
            position.put('lng', -122.3973206);
            Map<String, Object> data = new Map<String, Object>();
            data.put('position', position);
            response.result = new Map<String, Object>{ 'data' => data };
        }

        return response;
    }

    @AuraEnabled
    public static ResponseWrapper getAccountFSLDatesConfig() {
        try {
            ResponseWrapper response = new ResponseWrapper();
            Chuzo_Settings__c settings = Chuzo_Settings__c.getOrgDefaults();
            Boolean isFSLDatesEnabled = Auth.CommunitiesUtil.isGuestUser();

            if (!isFSLDatesEnabled) {
                User user = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];

                Account userAccount = [SELECT POE_FSL_Dates_Enabled__c FROM Account WHERE Id = :user.AccountId];

                Integer psAssignmentCount = [
                    SELECT COUNT()
                    FROM PermissionSetAssignment
                    WHERE
                        AssigneeId = :user.Id
                        AND (PermissionSet.Name = 'FSL_Community_Self_Service_Permissions'
                        OR PermissionSet.Name = 'FSL_Dates')
                ];
                isFSLDatesEnabled = userAccount.POE_FSL_Dates_Enabled__c && psAssignmentCount > 0;
            }

            WorkType defaultWorkType = [SELECT Name FROM WorkType WHERE Id = :settings.FSL_Work_Type_Id__c];

            response.result = new Map<String, Object>{
                'isFSLDatesEnabled' => isFSLDatesEnabled,
                'defaultWorkTypeId' => settings.FSL_Work_Type_Id__c,
                'defaultWorkTypeName' => defaultWorkType.Name,
                'fslDealerCode' => settings.FSL_Dealer_Code__c
            };
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper getWorkOrderIdByServiceAppId(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();

            String serviceAppointmentId = (String) myData.get('serviceAppointmentId');
            ServiceAppointment sa = [SELECT ParentRecordId FROM ServiceAppointment WHERE Id = :serviceAppointmentId];
            WorkOrder word = [SELECT Id FROM WorkOrder WHERE Id = :sa.ParentRecordId];

            response.result = new Map<String, Object>{ 'workOrderId' => word.Id };
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static ResponseWrapper getDTVAddressRegEx() {
        try {
            ResponseWrapper res = new ResponseWrapper();

            POE_Chuzo_Regular_Expressions__mdt regex = [
                SELECT RegEx__c
                FROM POE_Chuzo_Regular_Expressions__mdt
                WHERE DeveloperName = 'DTV_Address_RegEx'
                LIMIT 1
            ];

            res.result = new Map<String, Object>{ 'dtvAddressRegEx' => regex.RegEx__c };
            return res;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static ResponseWrapper getAgentReferralCodes(Map<String, Object> myData) {
        try {
            ResponseWrapper res = new ResponseWrapper();
            String userId = (String) myData.get('userId');

            List<Contact> contacts = [
                SELECT Id, Name, (SELECT Id, Agent__c, Referral_Code__c FROM Agent_ReferralCode_Associations__r)
                FROM Contact
                WHERE Id IN (SELECT ContactId FROM User WHERE Id = :userId)
            ];
            if (!contacts.isEmpty()) {
                Set<Id> referralCodesId = new Set<Id>();
                for (Contact contact : contacts) {
                    for (Agent_ReferralCode_Association__c association : contact.Agent_ReferralCode_Associations__r) {
                        referralCodesId.add(association.Referral_Code__c);
                    }
                }
                List<Referral_Code__c> availableCodes = [
                    SELECT
                        Id,
                        Referral_Code__c,
                        Body__c,
                        Title__c,
                        Subtitle__c,
                        Logo_URL__c,
                        Primary_Brand_Color__c,
                        Secondary_Brand_Color__c
                    FROM Referral_Code__c
                    WHERE Id IN :referralCodesId
                ];
                res.result = new Map<String, Object>{ 'hasCodes' => true, 'availableCodes' => availableCodes };
            } else {
                res.result = new Map<String, Object>{ 'hasCodes' => false, 'availableCodes' => '' };
            }

            return res;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper saveTransactionId(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String transactionId = (String) myData.get('transactionId');
            String recordId = (String) myData.get('recordId');
            Opportunity opp = new Opportunity();
            opp.Id = recordId;
            opp.Frontier_Quote_ID__c = transactionId;
            update opp;
            Map<String, Object> result = new Map<String, Object>{ 'transactionId' => transactionId };
            response.result = result;
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper saveFrontierQuoteNumber(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String quoteId = (String) myData.get('quoteId');
            String quoteNumber = (String) myData.get('quoteNumber');
            String recordId = (String) myData.get('recordId');
            Opportunity opp = new Opportunity();
            opp.Id = recordId;
            opp.Frontier_Quote_ID__c = quoteId;
            opp.Frontier_Quote_Number__c = quoteNumber;
            update opp;
            Map<String, Object> result = new Map<String, Object>{ 'quoteID' => quoteId, 'quoteNumber' => quoteNumber };
            response.result = result;
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper saveFrontierBTN(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String btn = (String) myData.get('btn');
            String recordId = (String) myData.get('recordId');
            Opportunity opp = new Opportunity();
            opp.Id = recordId;
            opp.Frontier_BTN__c = btn;
            update opp;
            Map<String, Object> result = new Map<String, Object>{ 'btn' => btn };
            response.result = result;
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper saveOpportunityReferralCode(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String oppId = (String) myData.get('oppId');
            Id referralCode = (Id) myData.get('referralCode');
            Opportunity opp = new Opportunity(Id = oppId, Referral_Code__c = referralCode);
            update opp;

            Map<String, Object> result = new Map<String, Object>{ 'Opportunity' => opp };

            response.result = result;

            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateProgramRestrictionNotification(List<String> restrictionIds) {
        try {
            if (restrictionIds == null || restrictionIds.isEmpty()) {
                throw new AuraHandledException('Restriction IDs are required');
            }

            List<Program_Sales_Restriction__c> restrictions = [
                SELECT Id, Notified__c, Limit_Reached__c
                FROM Program_Sales_Restriction__c
                WHERE Id IN :restrictionIds
            ];

            for (Program_Sales_Restriction__c restriction : restrictions) {
                if (restriction.Notified__c != true || restriction.Limit_Reached__c != true) {
                    restriction.Notified__c = true;
                    restriction.Limit_Reached__c = true;
                }
            }

            if (!restrictions.isEmpty()) {
                update restrictions;
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error updating program restrictions: ' + e.getMessage());
        }
    }

    public class ResponseWrapper {
        @AuraEnabled
        public Map<String, Object> result;
    }
}
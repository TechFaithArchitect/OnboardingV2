public without sharing class RepOnBoardingController {
    private static final String FIELD_SERVICE_NETWORK_NAME = 'Field Service';
    private static final String INITIAL_STATUS = 'Onboarding In Progress';

    @AuraEnabled(cacheable=true)
    public static ResponseWrapper getChuzoAgents() {
        try {
            String accountId = [SELECT AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].AccountId;
            List<String> contactIds = new List<String>();
            for (NetworkMember net : [
                SELECT NetworkId, Member.ContactId
                FROM NetworkMember
                WHERE
                    Member.AccountId = :accountId
                    AND (Network.Name = 'POE'
                    OR Network.Name = :FIELD_SERVICE_NETWORK_NAME)
            ]) {
                contactIds.add(net.Member.ContactId);
            }
            ResponseWrapper response = new ResponseWrapper();
            response.result = new Map<String, Object>{ 'memberList' => contactIds };
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper getOnboardingRepresentatives(Map<String, Object> myData) {
        try {
            String representativeList = (String) myData.get('representativeList');

            ResponseWrapper response = new ResponseWrapper();

            User currentUser = [SELECT AccountId FROM User WHERE Id = :System.UserInfo.getUserId()];
            String accountId = currentUser.AccountId;

            Account userAccount = [SELECT Id, POE_Require_TPV__c FROM Account WHERE Id = :accountId];

            List<Id> fslContactIds = new List<Id>();
            for (NetworkMember net : [
                SELECT Member.ContactId
                FROM NetworkMember
                WHERE Member.AccountId = :accountId AND Network.Name = :FIELD_SERVICE_NETWORK_NAME
            ]) {
                fslContactIds.add(net.Member.ContactId);
            }

            String query;

            if (representativeList == 'Active') {
                query =
                    'SELECT Id, IsActive, Contact.FirstName, Contact.LastName, Contact.Chuzo_Member__c, Contact.MobilePhone, Contact.POE_Enable_Trial_Period__c, ' +
                    'Contact.POE_Programs_Available__c, Contact.POE_Blacklisted_Programs__c, Contact.POE_RO_Status__c FROM User WHERE AccountId = :accountId ' +
                    'AND Contact.Chuzo_Member__c = true ' +
                    'AND IsActive = true ' +
                    'AND Contact.POE_RO_Status__c = \'Ready To Sell\' ORDER By Contact.FirstName';
            } else if (representativeList == 'Onboarding') {
                query =
                    'SELECT Id, FirstName, LastName, MiddleName, MobilePhone, Birthdate, Email, ' +
                    'POE_Start_Date__c, POE_Enable_Trial_Period__c, POE_Programs_Available__c, ' +
                    'POE_Blacklisted_Programs__c, POE_RO_Status__c, POE_Functional_Role__c, ' +
                    'POE_Representative_Type__c, POE_Call_Center_Type__c, POE_County__c, ' +
                    'MailingStreet, MailingState, MailingPostalCode, vlocity_cmt__SSN__c, ' +
                    'POE_Event_Programs__c, POE_Retail_Programs__c, D2D_Programs__c, MDU_Programs_Available__c ' +
                    'FROM Contact WHERE AccountId = :accountId ' +
                    'AND POE_RO_Status__c != \'Ready To Sell\' AND (POE_Functional_Role__c != null OR Id IN :fslContactIds) ORDER BY POE_RO_Status__c';
            } else if (representativeList == 'Inactive') {
                List<RecordType> repOnboardingRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'Rep_Onboarding'];
                if (repOnboardingRT.isEmpty()) {
                    throw new AuraHandledException('Error while retrieving Agents');
                }
                query =
                    'SELECT Id, IsActive, Contact.FirstName, Contact.LastName, Contact.Chuzo_Member__c, Contact.MobilePhone, ' +
                    'Contact.POE_Enable_Trial_Period__c, Contact.POE_Programs_Available__c, Contact.POE_Blacklisted_Programs__c, Contact.POE_RO_Status__c ' +
                    'FROM User ' +
                    'WHERE AccountId = :accountId ' +
                    'AND Contact.POE_RO_Status__c = \'Ready To Sell\' ' +
                    'AND (Contact.Chuzo_Member__c = false OR IsActive = false) ' +
                    'AND ContactId NOT IN (SELECT ContactId FROM Case WHERE IsClosed = false AND RecordTypeId = \'' +
                    String.valueOf(repOnboardingRT[0].Id) +
                    '\') ' +
                    'ORDER BY Contact.FirstName';
            }

            response.result = new Map<String, Object>{
                'Representatives' => Database.query(query),
                'Account' => userAccount
            };

            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateTPVField(Map<String, Object> myData) {
        try {
            String contactId = (String) myData.get('contactId');
            Boolean value = (Boolean) myData.get('value');

            Contact contactToUpdate = new Contact(Id = contactId, POE_Enable_Trial_Period__c = value);

            update contactToUpdate;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper getAccountDetails() {
        try {
            ResponseWrapper response = new ResponseWrapper();

            User currentUser = [SELECT AccountId FROM User WHERE Id = :System.UserInfo.getUserId()];
            Account userAccount = [
                SELECT Id, Name, POE_Dealer_Office_Email__c, POE_Point_of_Contact__c
                FROM Account
                WHERE Id = :currentUser.AccountId
            ];

            response.result = new Map<String, Object>{ 'Account' => userAccount, 'User' => currentUser };

            List<Contact> contacts = [
                SELECT AccountId, Email
                FROM Contact
                WHERE AccountId = :userAccount.Id AND POE_Point_of_Contact__c = TRUE
            ];
            if (!contacts.isEmpty()) {
                response.result.put('Contact', contacts[0]);
            }

            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void saveAccountChanges(Map<String, Object> myData) {
        try {
            String accountId = (String) myData.get('accountId');
            String email = (String) myData.get('email');
            String name = (String) myData.get('name');

            Account updatedAccount = new Account(
                Id = accountId,
                POE_Point_of_Contact__c = name,
                POE_Dealer_Office_Email__c = email
            );

            update updatedAccount;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper getOwnerRepresentativeType() {
        try {
            ResponseWrapper response = new ResponseWrapper();

            User currentUser = [
                SELECT Id, Contact.POE_Representative_Type__c, Account.POE_Programs_Available__c
                FROM User
                WHERE Id = :System.UserInfo.getUserId()
            ];

            Map<String, Object> repType = new Map<String, Object>{
                'callCenter' => currentUser.Contact.POE_Representative_Type__c.contains('Phone Sales'),
                'doorToDoor' => currentUser.Contact.POE_Representative_Type__c.contains('Door To Door'),
                'event' => currentUser.Contact.POE_Representative_Type__c.contains('Event'),
                'retail' => currentUser.Contact.POE_Representative_Type__c.contains('Retail'),
                'mdu' => currentUser.Contact.POE_Representative_Type__c.contains('MDU')
            };

            response.result = new Map<String, Object>{
                'representativeType' => repType,
                'programsAvailable' => currentUser.Account.POE_Programs_available__c
            };

            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void saveRepresentative(Map<String, Object> myData) {
        try {
            String accountId = (String) myData.get('accountId');
            String contactId = (String) myData.get('contactId');
            String phoneSalesOptions = (String) myData.get('phoneSalesOptions');
            String eventOptions = (String) myData.get('eventOptions');
            String retailOptions = (String) myData.get('retailOptions');
            String d2dOptions = (String) myData.get('d2dOptions');
            String documentId = (String) myData.get('documentId');
            String mduOptions = (String) myData.get('mduOptions');

            if (phoneSalesOptions == null)
                phoneSalesOptions = '';
            if (eventOptions == null)
                eventOptions = '';
            if (retailOptions == null)
                retailOptions = '';
            if (d2dOptions == null)
                d2dOptions = '';
            if (mduOptions == null)
                mduOptions = '';

            Map<Object, Object> userData = (Map<Object, Object>) myData.get('userData');
            String firstName = (String) userData.get('FirstNameCreate');
            Date birthdate = Date.valueOf(String.valueOf(userData.get('BirthdateCreate')));
            String middleName = (String) userData.get('MiddleNameCreate');
            Date startDate = Date.valueOf(String.valueOf(userData.get('Start_Date__cCreate')));
            String lastName = (String) userData.get('LastNameCreate');
            String mailingStreet = (String) userData.get('MailingStreet');
            String ssn = (String) userData.get('SsnCreate');
            String mailingState = (String) userData.get('MailingStateCreate');
            String county = (String) userData.get('County');
            String mailingCountry = (String) userData.get('MailingCountryCreate');
            String email = (String) userData.get('ConfirmEmailCreate');
            String mobilePhone = (String) userData.get('MobilePhoneCreate');
            String mailingZipCode = (String) userData.get('MailingZipcodeCreate');
            String functionalRole = (String) userData.get('FunctionalRole');
            String repType = (String) userData.get('RepresentativeType');
            String callCenterType = (String) userData.get('CallCenterType');
            Boolean isCreate = String.isBlank(contactId);
            Boolean dtvAllowed =
                phoneSalesOptions.contains('DIRECTV') ||
                eventOptions.contains('DIRECTV') ||
                retailOptions.contains('DIRECTV') ||
                d2dOptions.contains('DIRECTV');
            Boolean ownerIsActive;
            List<Contact> existingEmailContact = new List<Contact>();
            if (String.isNotBlank(email) && isCreate) {
                existingEmailContact = [
                    SELECT Id, Chuzo_Member__c, FSL_Member__c, Resource_Type__c, Owner.IsActive
                    FROM Contact
                    WHERE Email = :email AND Account.RecordType.DeveloperName = 'POE_Dealer'
                ];
            }

            if (!existingEmailContact.isEmpty()) {
                Contact existingContact = existingEmailContact[0];
                Boolean isChuzoMember = existingContact.Chuzo_Member__c;
                Boolean isFSLMember = existingContact.FSL_Member__c;
                ownerIsActive = existingContact.Owner.IsActive;
                if (isChuzoMember) {
                    throw new DmlException('The email is already in use in another contact');
                }
                if (isFSLMember) {
                    String resourceType = existingContact.Resource_Type__c;
                    Boolean isDispatcher = resourceType == 'Dispatcher' || resourceType == 'Dispatcher and Technician';
                    Boolean isTechnician = resourceType == 'Technician';
                    Boolean isOfficeManager =
                        !String.isBlank(functionalRole) && !functionalRole.contains('Office Representative');
                    if ((isDispatcher && !isOfficeManager) || (isTechnician && isOfficeManager)) {
                        Contact duplicateContact = existingContact.clone(false, true, false, false);
                        duplicateContact.AccountId = accountId;
                        insert duplicateContact;
                        contactId = duplicateContact.Id;
                    }
                }
            }

            if (isCreate) {
                phoneSalesOptions = removeDirectv(phoneSalesOptions);
                eventOptions = removeDirectv(eventOptions);
                retailOptions = removeDirectv(retailOptions);
                d2dOptions = removeDirectv(d2dOptions);
            } else {
                List<Contact> cons = [
                    SELECT
                        Id,
                        AccountId,
                        POE_Programs_Available__c,
                        POE_Event_Programs__c,
                        POE_Retail_Programs__c,
                        MDU_Programs_Available__c,
                        D2D_Programs__c,
                        FSL_Member__c,
                        Chuzo_Member__c,
                        Owner.IsActive
                    FROM Contact
                    WHERE Id = :contactId
                ];
                if (!cons.isEmpty()) {
                    Contact con = cons[0];
                    ownerIsActive = con.Owner.IsActive;
                    accountId = con.AccountId;

                    if (con.POE_Programs_Available__c != null) {
                        String programsAvailable = con.POE_Programs_Available__c.toUpperCase();
                        if (!programsAvailable.contains('DIRECTV')) {
                            phoneSalesOptions = removeDirectv(phoneSalesOptions);
                        }
                    }

                    if (con.POE_Event_Programs__c != null) {
                        String eventPrograms = con.POE_Event_Programs__c.toUpperCase();
                        if (!eventPrograms.contains('DIRECTV')) {
                            eventOptions = removeDirectv(eventOptions);
                        }
                    }

                    if (con.POE_Retail_Programs__c != null) {
                        String retailPrograms = con.POE_Retail_Programs__c.toUpperCase();
                        if (!retailPrograms.contains('DIRECTV')) {
                            retailOptions = removeDirectv(retailOptions);
                        }
                    }

                    if (con.D2D_Programs__c != null) {
                        String d2dPrograms = con.D2D_Programs__c.toUpperCase();
                        if (!d2dPrograms.contains('DIRECTV')) {
                            d2dOptions = removeDirectv(d2dOptions);
                        }
                    }
                }
            }

            phoneSalesOptions = phoneSalesOptions.replace('Optimum', 'Altice');
            eventOptions = eventOptions.replace('Optimum', 'Altice');
            retailOptions = retailOptions.replace('Optimum', 'Altice');
            d2dOptions = d2dOptions.replace('Optimum', 'Altice');
            mduOptions = mduOptions.replace('Optimum', 'Altice');
            phoneSalesOptions = removeDirectv(phoneSalesOptions);
            eventOptions = removeDirectv(eventOptions);
            retailOptions = removeDirectv(retailOptions);
            d2dOptions = removeDirectv(d2dOptions);
            mduOptions = removeDirectv(mduOptions);

            phoneSalesOptions = mapSpectrumToApi(phoneSalesOptions);
            eventOptions = mapSpectrumToApi(eventOptions);
            retailOptions = mapSpectrumToApi(retailOptions);
            d2dOptions = mapSpectrumToApi(d2dOptions);
            mduOptions = mapSpectrumToApi(mduOptions);

            Contact updatedContact = new Contact(
                Id = contactId,
                AccountId = accountId,
                POE_Programs_Available__c = phoneSalesOptions,
                POE_Event_Programs__c = eventOptions,
                POE_Retail_Programs__c = retailOptions,
                D2D_Programs__c = d2dOptions,
                FirstName = firstName,
                MiddleName = middleName,
                LastName = lastName,
                MailingStreet = mailingStreet,
                vlocity_cmt__SSN__c = ssn,
                MailingState = mailingState,
                MailingCountry = mailingCountry,
                MailingPostalCode = mailingZipCode,
                POE_County__c = county,
                MobilePhone = mobilePhone,
                POE_Functional_Role__c = functionalRole,
                POE_Representative_Type__c = repType,
                POE_Call_Center_Type__c = callCenterType,
                Birthdate = birthdate,
                POE_Start_Date__c = startDate,
                POE_Allow_DTV_Sell__c = dtvAllowed,
                MDU_Programs_Available__c = String.isBlank(mduOptions) ? '' : mduOptions
            );

            if (isCreate) {
                updatedContact.Email = email;
            }

            if (isCreate) {
                updatedContact.POE_RO_Status__c = INITIAL_STATUS;
            }

            if (ownerIsActive != null && !ownerIsActive) {
                User owner = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
                updatedContact.OwnerId = owner.Id;
            }

            try {
                upsert updatedContact;
            } catch (Exception e) {
                throw e;
            }

            if (documentId != null) {
                ContentDocumentLink doc = new ContentDocumentLink(
                    LinkedEntityId = updatedContact.Id,
                    ContentDocumentId = documentId,
                    ShareType = 'I'
                );
                insert doc;
            }

            if (isCreate) {
                RecordType repOnboardingRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'Rep_Onboarding'];
                Group queue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Customer_Service_Team'];
                Case onboardingCase = new Case(
                    AccountId = accountId,
                    ContactId = updatedContact.Id,
                    POE_ICLRep__c = updatedContact.Id,
                    Type = 'Onboarding',
                    Subject = 'New Rep Onboarding',
                    Origin = 'Chuzo',
                    RecordTypeId = repOnboardingRT.Id,
                    OwnerId = queue.Id
                );
                insert onboardingCase;

                Group accountGroup = [
                    SELECT Id
                    FROM Group
                    WHERE Type = 'Regular' AND Name = :('Dealer-' + accountId)
                    LIMIT 1
                ];
                CaseSharingService.ShareInput shareInput = new CaseSharingService.ShareInput();
                shareInput.recordId = onboardingCase.Id;
                shareInput.groupId = accountGroup.Id;
                shareInput.accessLevel = 'Edit';
                CaseSharingService.shareCaseWithGroup(new List<CaseSharingService.ShareInput>{ shareInput });
            } else {
                List<NetworkMember> fslNetworkMemberList = [
                    SELECT MemberId
                    FROM NetworkMember
                    WHERE Network.Name = :FIELD_SERVICE_NETWORK_NAME AND Member.ContactId = :updatedContact.Id
                ];

                if (!fslNetworkMemberList.isEmpty()) {
                    System.enqueueJob(
                        new POE_AddRepPermissionsQueueable(updatedContact.Id, fslNetworkMemberList[0].MemberId)
                    );
                }
            }
        } catch (Exception e) {
            System.debug(e);
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static ResponseWrapper getMobilePhoneRegex() {
        try {
            ResponseWrapper res = new ResponseWrapper();

            POE_Chuzo_Regular_Expressions__mdt regex = [
                SELECT RegEx__c
                FROM POE_Chuzo_Regular_Expressions__mdt
                WHERE DeveloperName = 'Mobile_Phone_Format_RegEx'
                LIMIT 1
            ];

            res.result = new Map<String, Object>{ 'mobilePhoneRegex' => regex.RegEx__c };
            return res;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper createReactivationCaseWithContactId(Map<String, Object> myData) {
        ResponseWrapper response = new ResponseWrapper();
        try {
            if (myData == null || !myData.containsKey('contactId')) {
                response.result = new Map<String, Object>{
                    'status' => 'error',
                    'message' => 'Missing contactId in input data'
                };
                return response;
            }

            Id contactId = (Id) myData.get('contactId');
            Boolean userWasActive = checkUserWasActive(contactId);

            List<User> users = [SELECT AccountId FROM User WHERE Id = :System.UserInfo.getUserId()];
            if (users.isEmpty()) {
                response.result = new Map<String, Object>{ 'status' => 'error', 'message' => 'Current user not found' };
                return response;
            }
            User currentUser = users[0];

            String accountId = currentUser.AccountId;
            RecordType repOnboardingRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'Rep_Onboarding' LIMIT 1];
            Group queue = [
                SELECT Id
                FROM Group
                WHERE Type = 'Queue' AND DeveloperName = 'Customer_Service_Team'
                LIMIT 1
            ];

            Case reactivationCase = new Case(
                AccountId = accountId,
                ContactId = contactId,
                POE_ICLRep__c = contactId,
                Type = 'Onboarding',
                Origin = 'Chuzo',
                RecordTypeId = repOnboardingRT.Id,
                Was_this_user_active_in_the_past__c = userWasActive,
                OwnerId = queue.Id
            );
            insert reactivationCase;

            Group accountGroup = [
                SELECT Id
                FROM Group
                WHERE Type = 'Regular' AND Name = :('Dealer-' + accountId)
                LIMIT 1
            ];
            CaseSharingService.ShareInput shareInput = new CaseSharingService.ShareInput();
            shareInput.recordId = reactivationCase.Id;
            shareInput.groupId = accountGroup.Id;
            shareInput.accessLevel = 'Edit';
            CaseSharingService.shareCaseWithGroup(new List<CaseSharingService.ShareInput>{ shareInput });

            response.result = new Map<String, Object>{ 'status' => 'success', 'caseId' => reactivationCase.Id };
            return response;
        } catch (Exception e) {
            System.debug(e);
            response.result = new Map<String, Object>{
                'status' => 'error',
                'message' => 'Error creating reactivation case: ' + e.getMessage()
            };
            return response;
        }
    }

    public static Boolean checkUserWasActive(Id contactId) {
        List<User> userRecords = [
            SELECT Id
            FROM User
            WHERE ContactId = :contactId AND Contact.Chuzo_Member__c = FALSE
            LIMIT 1
        ];
        return !userRecords.isEmpty();
    }

    @AuraEnabled(cacheable=true)
    public static Contact getContactById(Id contactId) {
        return [
            SELECT
                Id,
                FirstName,
                LastName,
                Birthdate,
                MiddleName,
                POE_Start_Date__c,
                MailingStreet,
                MailingState,
                MobilePhone,
                Email,
                MailingPostalCode,
                POE_Functional_Role__c,
                AccountId,
                POE_RO_Status__c,
                POE_Representative_Type__c,
                POE_Event_Programs__c,
                POE_Retail_Programs__c,
                MDU_Programs_Available__c,
                D2D_Programs__c,
                POE_Call_Center_Type__c,
                POE_County__c,
                vlocity_cmt__SSN__c,
                POE_Programs_Available__c
            FROM Contact
            WHERE Id = :contactId
            LIMIT 1
        ];
    }

    public class ResponseWrapper {
        @AuraEnabled
        public Map<String, Object> result;
    }

    private static String mapSpectrumToApi(String input) {
        if (String.isBlank(input))
            return input;
        List<String> values = input.split(';');
        for (Integer i = 0; i < values.size(); i++) {
            if (values[i] == 'Spectrum')
                values[i] = 'Spectrum API';
        }
        return String.join(values, ';');
    }

    private static String removeDirectv(String input) {
        if (String.isBlank(input))
            return input;
        List<String> values = input.split(';');
        List<String> filtered = new List<String>();
        for (String v : values) {
            if (v != 'DIRECTV')
                filtered.add(v);
        }
        return String.join(filtered, ';');
    }
}
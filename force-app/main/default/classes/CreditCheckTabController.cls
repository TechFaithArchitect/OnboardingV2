public without sharing class CreditCheckTabController {
    public static final string SPECTRUM_FAMILY_VALUE = System.Label.CHARTER_SPECTRUM;

    @AuraEnabled
    public static ResponseWrapper updateOpportunity(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();

            Boolean creditCheckLimitReached = (Boolean) myData.get('creditCheckLimitReached');
            Id oppId = (String) myData.get('Id');

            Opportunity oppBlockedByCCLimit = new Opportunity(
                Id = oppId,
                POE_Credit_Check_Limit_Reached__c = creditCheckLimitReached
            );
            update oppBlockedByCCLimit;

            response.result = new Map<String, Object>{ 'status' => true };
            return response;
        } catch (Exception exc) {
            throw new AuraHandledException(exc.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper getSSNAgreement(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String oppId = (String) myData.get('ContextId');
            Opportunity opp = [SELECT POE_SSN_Agreement__c, POE_Program__c FROM Opportunity WHERE Id = :oppId LIMIT 1];

            response.result = new Map<String, Object>{ 'Opportunity' => opp };
            return response;
        } catch (AuraHandledException e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper setSSNAgreement(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String oppId = (String) myData.get('ContextId');
            Boolean isSSNAgreement = (Boolean) myData.get('value');

            Opportunity opp = new Opportunity(Id = oppId, POE_SSN_Agreement__c = isSSNAgreement);
            update opp;

            response.result = new Map<String, Object>{ 'Opportunity' => opp };
            return response;
        } catch (AuraHandledException e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper getSSNFraudRules(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String oppId = (String) myData.get('ContextId');
            String partner = (String) myData.get('partner');

            List<POE_Providers_Identifier__mdt> partnerIdentifierList = [
                SELECT Id, Identifier__c
                FROM POE_Providers_Identifier__mdt
                WHERE DeveloperName = :partner
            ];

            Id consumerRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('PersonAccount')
                .getRecordTypeId();

            Opportunity opp = [
                SELECT Id, POE_QuantityOfAttempts__c, POE_Reference_Number__c, POE_Credit_Check_Limit_Reached__c
                FROM Opportunity
                WHERE Id = :oppId
            ];

            List<Fraud_Validation_Rules__c> rules = [
                SELECT Id, Name, Number_Of_Times__c
                FROM Fraud_Validation_Rules__c
                WHERE Name = 'SSNRun'
            ];

            response.result = new Map<String, Object>{
                'refNum' => opp.POE_Reference_Number__c,
                'limit' => rules.size() > 0 ? rules[0].Number_Of_Times__c : null,
                'recType' => consumerRTId,
                'offer' => partnerIdentifierList.size() > 0 ? partnerIdentifierList[0].Identifier__c : null,
                'attempts' => opp.POE_QuantityOfAttempts__c,
                'creditLimit' => opp.POE_Credit_Check_Limit_Reached__c
            };

            if (partner.toLowerCase() == 'directv') {
                String dtvEncriptionKey = [
                    SELECT Id, POE_Public_K__c
                    FROM Encryption_Keys__mdt
                    WHERE DeveloperName = 'DIRECTV'
                ]
                .POE_Public_K__c;
                response.result.put('key', dtvEncriptionKey);
            }

            return response;
        } catch (AuraHandledException e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper saveFlagIP(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String oppId = (String) myData.get('ContextId');
            String ip = (String) myData.get('IP');

            Opportunity opp = new Opportunity(Id = oppId, POE_Fraud_Flag_IP__c = ip);
            update opp;

            response.result = new Map<String, Object>{ 'Opportunity' => opp };
            return response;
        } catch (AuraHandledException e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper getProviderPhoneNumber(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String provider = (String) myData.get('provider');
            String use = (String) myData.get('use');

            Chuzo_Provider_Phone_Numbers__mdt phone = [
                SELECT Id, Phone__c
                FROM Chuzo_Provider_Phone_Numbers__mdt
                WHERE Provider__c = :provider AND Used_For__c = :use
                LIMIT 1
            ];

            response.result = new Map<String, Object>{ 'Phone' => phone };
            return response;
        } catch (AuraHandledException e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper saveCreditFreeze(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String oppId = (String) myData.get('ContextId');

            Opportunity opp = new Opportunity(Id = oppId, POE_CreditFreeze__c = true);
            update opp;

            response.result = new Map<String, Object>{ 'Opportunity' => opp };
            return response;
        } catch (AuraHandledException e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper saveAccountInformation(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String preferredContactMethod = (String) myData.get('preferredContactMethod');
            String preferredContactTime = (String) myData.get('preferredContactTime');
            Boolean addressDiscrepancy = (Boolean) myData.get('addressDiscrepancy');
            String oppId = (String) myData.get('ContextId');
            String recordTypeId = (String) myData.get('recordTypeId');
            String accName = (String) myData.get('accName');
            String identification = (String) myData.get('identification');
            Map<Object, Object> creditCheck = (Map<Object, Object>) myData.get('creditCheck');
            Map<Object, Object> accountDetails = (Map<Object, Object>) creditCheck?.get('accountDetails');
            Map<Object, Object> billingCreditCheckAddress = (Map<Object, Object>) accountDetails
                ?.get('billingCreditCheckAddress');
            String billingStreet = (String) billingCreditCheckAddress?.get('billingAddress');
            String billingAptNumber = (String) billingCreditCheckAddress?.get('billingAptNumber');
            String billingCity = (String) billingCreditCheckAddress?.get('billingCity');
            String billingState = (String) billingCreditCheckAddress?.get('billingState');
            String billingStateName = (String) billingCreditCheckAddress?.get('billingStateName');
            String billingZip = (String) billingCreditCheckAddress?.get('billingZip');
            Map<Object, Object> shippingServiceAddresss = (Map<Object, Object>) accountDetails
                ?.get('shippingServiceAddresss');
            String shippingStreet = (String) shippingServiceAddresss?.get('shippingAddress');
            String shippingAptNumber = (String) shippingServiceAddresss?.get('shippingAptNumber');
            String shippingCity = (String) shippingServiceAddresss?.get('shippingCity');
            String shippingState = (String) shippingServiceAddresss?.get('shippingState');
            String shippingStateName = (String) shippingServiceAddresss?.get('shippingStateName');
            String shippingZip = (String) shippingServiceAddresss?.get('shippingZip');
            Map<Object, Object> customerDetails = (Map<Object, Object>) creditCheck?.get('customerDetails');
            Map<Object, Object> contactInformation = (Map<Object, Object>) customerDetails?.get('contactInformation');
            String firstName = (String) contactInformation?.get('firstName');
            String middleName = (String) contactInformation?.get('middleName');
            String lastName = (String) contactInformation?.get('lastName');
            String email = (String) contactInformation?.get('email');
            String contactPhone = (String) contactInformation?.get('contactPhone');
            List<Account> accountList = new List<Account>();

            Id personAccountRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('PersonAccount')
                .getRecordTypeId();

            Opportunity queryOpp = [SELECT Id, AccountId, Account.Name FROM Opportunity WHERE Id = :oppId LIMIT 1];

            if (!String.isBlank(queryOpp.AccountId) && queryOpp.Account.Name != 'Customer To Be Determined') {
                accountList = [SELECT Id FROM Account WHERE Id = :queryOpp.AccountId];
            } else {
                accountList = [
                    SELECT Id, Name
                    FROM Account
                    WHERE
                        Name = :accName
                        AND RecordTypeId = :recordTypeId
                        AND ShippingPostalCode = :shippingZip
                        AND ShippingCity = :shippingCity
                        AND ShippingStreet = :shippingStreet
                        AND Phone = :contactPhone
                        AND BillingPostalCode = :billingZip
                        AND BillingCity = :billingCity
                        AND BillingStreet = :billingStreet
                        AND ((ShippingStateCode = :shippingState
                        AND BillingStateCode = :billingState)
                        OR (ShippingState = :shippingStateName
                        AND BillingState = :billingStateName))
                ];
            }

            Account accToUpsert = new Account(
                RecordTypeId = personAccountRTId,
                FirstName = firstName,
                LastName = lastName,
                MiddleName = middleName,
                PersonEmail = email,
                Phone = contactPhone,
                ShippingPostalCode = shippingZip,
                ShippingCity = shippingCity,
                ShippingStreet = shippingStreet,
                ShippingStateCode = shippingState,
                Shipping_Address_Line_2__c = shippingAptNumber,
                BillingPostalCode = billingZip,
                BillingCity = billingCity,
                BillingStreet = billingStreet,
                BillingStateCode = billingState,
                Billing_Address_Line_2__c = billingAptNumber,
                Preferred_Contact_Method__c = preferredContactMethod,
                Preferred_Contact_Time__c = preferredContactTime
            );
            if (accountList.size() > 0) {
                accToUpsert.Id = accountList[0].Id;
            }
            Database.UpsertResult accUpsertResult = Database.upsert(accToUpsert, Account.Fields.Id, false);
            if (!accUpsertResult.isSuccess()) {
                Database.Error error = accUpsertResult.getErrors()[0];
                response.result = new Map<String, Object>{ 'errorMessage' => error.getMessage(), 'error' => true };
                return response;
            }

            Opportunity opp = new Opportunity(
                Id = oppId,
                POE_Identification_Method__c = identification,
                AccountId = accToUpsert.Id
            );
            Database.UpsertResult oppUpsertResult = Database.upsert(opp, Opportunity.Fields.Id, false);
            if (!oppUpsertResult.isSuccess()) {
                Database.Error error = oppUpsertResult.getErrors()[0];
                response.result = new Map<String, Object>{ 'errorMessage' => error.getMessage(), 'error' => true };
                return response;
            }

            response.result = new Map<String, Object>{ 'Account' => accToUpsert, 'Opportunity' => opp };
            return response;
        } catch (AuraHandledException e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper saveNewOrder(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            Date timeStamp = Date.valueOf(String.valueOf(myData.get('timeStamp')));
            String oppId = (String) myData.get('ContextId');
            String accId = (String) myData.get('AccountId');
            String family = (String) myData.get('family');
            String representative = (String) myData.get('representative');
            String pricebookName = (String) myData.get('Pricebook');
            String productName = (String) myData.get('ProductName');
            String programOtherDetail = (String) myData.get('ProgramOtherDetail');
            Boolean addressDiscrepancy = (Boolean) myData.get('addressDiscrepancy');
            List<Object> adders = (List<Object>) myData.get('Adders');
            List<Object> services = (List<Object>) myData.get('Services');
            Map<Object, Object> creditCheck = (Map<Object, Object>) myData.get('creditCheck');
            Map<Object, Object> accountDetails = (Map<Object, Object>) creditCheck?.get('accountDetails');
            Map<Object, Object> billingCreditCheckAddress = (Map<Object, Object>) accountDetails
                ?.get('billingCreditCheckAddress');
            String billingStreet = (String) billingCreditCheckAddress?.get('billingAddress');
            String billingAptNumber = (String) billingCreditCheckAddress?.get('billingAptNumber');
            String billingCity = (String) billingCreditCheckAddress?.get('billingCity');
            String billingState = (String) billingCreditCheckAddress?.get('billingState');
            String billingZip = (String) billingCreditCheckAddress?.get('billingZip');
            Map<Object, Object> shippingServiceAddresss = (Map<Object, Object>) accountDetails
                ?.get('shippingServiceAddresss');
            String shippingStreet = (String) shippingServiceAddresss?.get('shippingAddress');
            String shippingAptNumber = (String) shippingServiceAddresss?.get('shippingAptNumber');
            String shippingCity = (String) shippingServiceAddresss?.get('shippingCity');
            String shippingState = (String) shippingServiceAddresss?.get('shippingState');
            String shippingZip = (String) shippingServiceAddresss?.get('shippingZip');
            String referralCodeId = (String) myData.get('referralCodeId');
            Id stdOrderRTId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName()
                .get('StandardOrder')
                .getRecordTypeId();
            String phone = (String) myData.get('phone');
            String email = (String) myData.get('email');

            List<Pricebook2> pricebookList = [SELECT Id FROM Pricebook2 WHERE Name = :pricebookName];
            Order ord = new Order(
                AccountId = accId,
                OpportunityId = oppId,
                RecordTypeId = stdOrderRTId,
                POE_Program__c = family,
                POE_RepTitle__c = representative,
                Status = 'Draft',
                Type = 'Closed Won',
                EffectiveDate = timeStamp,
                Pricebook2Id = pricebookList.size() > 0 ? pricebookList[0].Id : null,
                POE_Program_Other_Detail__c = programOtherDetail,
                BillingStreet = billingStreet,
                BillingCity = billingCity,
                BillingStateCode = billingState,
                BillingPostalCode = billingZip,
                ShippingStreet = shippingStreet,
                ShippingCity = shippingCity,
                ShippingStateCode = shippingState,
                ShippingPostalCode = shippingZip,
                Referral_Code__c = referralCodeId,
                Email__c = email,
                Phone__c = phone
            );
            insert ord;

            List<PricebookEntry> pricebookEntryList = [
                SELECT Id, UnitPrice, Pricebook2Id
                FROM PricebookEntry
                WHERE Name = :productName
            ];
            OrderItem ordItem = new OrderItem(
                OrderId = ord.Id,
                Quantity = 1,
                PricebookEntryId = pricebookEntryList.size() > 0 ? pricebookEntryList[0].Id : null,
                UnitPrice = pricebookEntryList.size() > 0 ? pricebookEntryList[0].UnitPrice : null
            );
            insert ordItem;

            if (family == 'Windstream' && adders != null && adders.size() > 0) {
                createOrderItems(ord.Id, adders);
            } else if (family == 'EarthLink' && services != null && services.size() > 0) {
                createOrderItems(ord.Id, services);
            }

            if (!Auth.CommunitiesUtil.isGuestUser()) {
                POE_ACI_Statistic__c statistic = [
                    SELECT Id, Order__c
                    FROM POE_ACI_Statistic__c
                    WHERE Opportunity__c = :oppId
                    LIMIT 1
                ];
                statistic.Order__c = ord.Id;
                update statistic;
            }

            if (addressDiscrepancy != null && addressDiscrepancy) {
                Opportunity opp = new Opportunity(Id = oppId, POE_AddressDiscrepancy__c = addressDiscrepancy);
                update opp;
            }

            response.result = new Map<String, Object>{ 'Order' => ord, 'OrderItem' => ordItem };
            return response;
        } catch (AuraHandledException e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static List<OrderItem> createOrderItems(Id orderId, List<Object> products) {
        List<OrderItem> orderItems = new List<OrderItem>();
        List<String> productNames = new List<String>();

        for (Object product : products) {
            Map<Object, Object> productMap = (Map<Object, Object>) product;
            productNames.add((String) productMap.get('Name'));
        }

        Map<String, PricebookEntry> pbEntriesByName = new Map<String, PricebookEntry>();
        for (PricebookEntry pbEntry : [
            SELECT Id, Name, Product2Id, UnitPrice
            FROM PricebookEntry
            WHERE Name IN :productNames
        ]) {
            pbEntriesByName.put(pbEntry.Name, pbEntry);
        }

        for (Object product : products) {
            Map<Object, Object> productMap = (Map<Object, Object>) product;
            PricebookEntry pbEntry = pbEntriesByName.get((String) productMap.get('Name'));
            orderItems.add(
                new OrderItem(
                    Quantity = 1,
                    OrderId = orderId,
                    PricebookEntryId = pbEntry.Id,
                    UnitPrice = pbEntry.UnitPrice,
                    Product2Id = pbEntry.Product2Id
                )
            );
        }

        insert orderItems;
        return orderItems;
    }

    @AuraEnabled
    public static ResponseWrapper saveACICreditCheck(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String oppId = (String) myData.get('ContextId');
            POE_ACI_Statistic__c statistic = [
                SELECT Id, Credit_Check__c
                FROM POE_ACI_Statistic__c
                WHERE Opportunity__c = :oppId
                LIMIT 1
            ];
            statistic.Credit_Check__c = 1;
            update statistic;

            return response;
        } catch (AuraHandledException e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper getOppSensitiveData(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String oppId = (String) myData.get('ContextId');
            Map<String, Object> ccData = POECCEncryptionService.decryptCreditCheckData(oppId);
            if (!ccData.isEmpty()) {
                response.result = new Map<String, Object>{
                    'ccDlState' => ccData.get('ccDlState'),
                    'ccDlExpirationDate' => ccData.get('ccDlExpirationDate'),
                    'ccDriversLicenseNumber' => ccData.get('ccDriversLicenseNumber'),
                    'ccDob' => ccData.get('ccDob'),
                    'ccSSN' => ccData.get('ccSSN')
                };
            }
            return response;
        } catch (AuraHandledException e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper sendPCISMS(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            POE_Callout_Config_API__mdt twilioConfig = POE_Callout_Config_API__mdt.getInstance('Twilio');
            Map<String, Object> input = new Map<String, Object>{
                'To' => (String) myData.get('clientPhone'),
                'From' => twilioConfig.Phone__c,
                'Body' => (String) myData.get('body'),
                'AccountId' => twilioConfig.User__c,
                'Password' => twilioConfig.Password__c
            };

            POESendPCISMS sendPCISMSVl = new POESendPCISMS();
            Boolean success = sendPCISMSVl.invokeMethod(null, input, null, null);

            String oppId = (String) myData.get('opportunityId');
            Account acc = [SELECT Account.Id, Account.POE_SMS_Opt_In__pc FROM Opportunity WHERE Id = :oppId].Account;

            acc.POE_SMS_Opt_In__pc = true;
            update acc;

            response.result = new Map<String, Object>{ 'success' => success, 'error' => success ? 'OK' : 'ERROR' };
            return response;
        } catch (AuraHandledException e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper sendCreditCheckPciEmail(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String email = (String) myData.get('pciEmail');
            String body = (String) myData.get('body');
            body = body == null ? '' : body;

            OrgWideEmailAddress orgWideEmail = [
                SELECT Id
                FROM OrgWideEmailAddress
                WHERE Address = 'no-reply@chuzo.com'
            ];
            Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
            emailMessage.setOrgWideEmailAddressId(orgWideEmail.Id);
            emailMessage.setToAddresses(new List<String>{ email });
            emailMessage.setSubject(System.Label.PCI_Email_Subject);
            emailMessage.setHtmlBody(System.Label.PCI_Email_Body.replace('{HREF}', body));

            Messaging.SendEmailResult emailResult = Messaging.sendEmail(
                new List<Messaging.SingleEmailMessage>{ emailMessage }
            )[0];

            response.result = new Map<String, Object>{ 'error' => !emailResult.isSuccess() };
            if (!emailResult.isSuccess()) {
                response.result.put('errorMessage', emailResult.getErrors()[0].getMessage());
            }

            return response;
        } catch (AuraHandledException e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper sendLeadConsentEmail(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String email = (String) myData.get('pciEmail');
            String body = (String) myData.get('body');
            String type = (String) myData.get('type');
            body = body == null ? '' : body;

            OrgWideEmailAddress orgWideEmail = [
                SELECT Id
                FROM OrgWideEmailAddress
                WHERE Address = 'no-reply@chuzo.com'
            ];
            Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
            emailMessage.setOrgWideEmailAddressId(orgWideEmail.Id);
            emailMessage.setToAddresses(new List<String>{ email });
            if (type == 'chuzo') {
                emailMessage.setSubject(System.Label.Chuzo_Consent_Email_Subject);
                emailMessage.setHtmlBody(System.Label.Chuzo_Consent_Email_Body.replace('{HREF}', body));
            } else {
                emailMessage.setSubject(System.Label.Lead_Consent_Email_Subject);
                emailMessage.setHtmlBody(System.Label.Lead_Consent_Email_Body.replace('{HREF}', body));
            }

            Messaging.SendEmailResult emailResult = Messaging.sendEmail(
                new List<Messaging.SingleEmailMessage>{ emailMessage }
            )[0];

            response.result = new Map<String, Object>{ 'error' => !emailResult.isSuccess() };
            if (!emailResult.isSuccess()) {
                response.result.put('errorMessage', emailResult.getErrors()[0].getMessage());
            }

            return response;
        } catch (AuraHandledException e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper IPSaveOrderDTV(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            Id stdOrderRecTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName()
                .get('StandardOrder')
                .getRecordTypeId();
            Id orderId = (Id) myData.get('OrderId');
            if (orderId != null) {
                Order previousOrder = new Order(Id = orderId);
                delete previousOrder;
            }
            Id contextId = (Id) myData.get('ContextId');
            Id accountId = (Id) myData.get('AccountId');
            String family = (String) myData.get('family');
            String representative = (String) myData.get('representative');
            String pricebookName = (String) myData.get('Pricebook');
            String productName = (String) myData.get('ProductName');
            Date timeStamp = Date.valueOf((String) myData.get('timeStamp'));
            String identification = (String) myData.get('identification');
            String creditScoreResult = (String) myData.get('creditScoreResult');
            Pricebook2 pricebook = [
                SELECT Id, (SELECT Id, UnitPrice FROM PricebookEntries WHERE Name = :productName)
                FROM Pricebook2
                WHERE Name = :pricebookName
            ];
            Map<Object, Object> creditCheck = (Map<Object, Object>) myData.get('creditCheck');
            Map<Object, Object> accountDetails = (Map<Object, Object>) creditCheck?.get('accountDetails');
            Map<Object, Object> billingCreditCheckAddress = (Map<Object, Object>) accountDetails
                ?.get('billingCreditCheckAddress');
            String billingStreet = (String) billingCreditCheckAddress?.get('billingAddress');
            String billingCity = (String) billingCreditCheckAddress?.get('billingCity');
            String billingState = (String) billingCreditCheckAddress?.get('billingState');
            String billingZip = (String) billingCreditCheckAddress?.get('billingZip');
            Map<Object, Object> shippingServiceAddresss = (Map<Object, Object>) accountDetails
                ?.get('shippingServiceAddresss');
            String shippingStreet = (String) shippingServiceAddresss?.get('shippingAddress');
            String shippingCity = (String) shippingServiceAddresss?.get('shippingCity');
            String shippingState = (String) shippingServiceAddresss?.get('shippingState');
            String shippingZip = (String) shippingServiceAddresss?.get('shippingZip');
            String referralCodeId = (String) myData.get('referralCodeId');
            Boolean isGuestUser = (Boolean) myData.get('isGuestUser');
            String phone = (String) myData.get('phone');
            String email = (String) myData.get('email');
            Boolean isSpectrumBuyflow = SPECTRUM_FAMILY_VALUE == family;
            Order newOrder = new Order(
                AccountId = accountId,
                OpportunityId = contextId,
                POE_Program__c = family,
                POE_RepTitle__c = representative,
                RecordTypeId = stdOrderRecTypeId,
                EffectiveDate = timeStamp,
                Pricebook2Id = pricebook.Id,
                Status = 'Draft',
                Type = 'Closed Won',
                BillingStreet = billingStreet,
                BillingCity = billingCity,
                BillingStateCode = billingState,
                BillingPostalCode = billingZip,
                ShippingStreet = shippingStreet,
                ShippingCity = shippingCity,
                ShippingStateCode = shippingState,
                ShippingPostalCode = shippingZip,
                Referral_Code__c = referralCodeId,
                Phone__c = phone,
                Email__c = email
            );
            if (String.isNotBlank(referralCodeId)) {
                newOrder.Referral_Code__c = referralCodeId;
            }
            insert newOrder;
            if (isSpectrumBuyflow) {
                List<OpportunityLineItem> opportunityLineItems = [
                    SELECT PricebookEntryId, Product2Id, Product2.Name, PricebookEntry.UnitPrice
                    FROM OpportunityLineItem
                    WHERE Opportunity.Id = :contextId
                ];

                Map<String, OrderItem> orderItemsMap = new Map<String, OrderItem>();

                if (!opportunityLineItems.isEmpty()) {
                    for (OpportunityLineItem oppLineItem : opportunityLineItems) {
                        OrderItem ordItem = new OrderItem(
                            OrderId = newOrder.Id,
                            Quantity = 1,
                            PricebookEntryId = oppLineItem.PricebookEntryId,
                            POE_Status__c = 'Draft',
                            UnitPrice = oppLineItem.PricebookEntry.UnitPrice
                        );
                        orderItemsMap.put(oppLineItem.Product2.Name, ordItem);
                    }
                }

                if (!orderItemsMap.isEmpty()) {
                    insert orderItemsMap.values();
                }
                response.result = new Map<String, Object>{ 'Order' => newOrder, 'OrderItems' => orderItemsMap };
            } else {
                OrderItem newOrderItem = new OrderItem(
                    OrderId = newOrder.Id,
                    Quantity = 1,
                    PricebookEntryId = pricebook.pricebookEntries.size() > 0 ? pricebook.pricebookEntries[0].Id : null,
                    UnitPrice = pricebook.pricebookEntries.size() > 0 ? pricebook.pricebookEntries[0].UnitPrice : null
                );
                insert newOrderItem;

                List<OpportunityLineItem> oppLineItem = [
                    SELECT Id
                    FROM OpportunityLineItem
                    WHERE PricebookEntry.Name = :productName AND OpportunityId = :contextId
                ];

                if (!oppLineItem.isEmpty()) {
                    OpportunityLineItem oppProduct = oppLineItem[0];
                    oppProduct.Selected_Product__c = newOrderItem.Id;
                    update oppProduct;
                } else {
                    OpportunityLineItem opportunityProduct = new OpportunityLineItem(
                        OpportunityId = contextId,
                        Quantity = 1,
                        Selected_Product__c = newOrderItem.Id,
                        PricebookEntryId = pricebook.pricebookEntries.size() > 0
                            ? pricebook.pricebookEntries[0].Id
                            : null,
                        UnitPrice = pricebook.pricebookEntries.size() > 0
                            ? pricebook.pricebookEntries[0].UnitPrice
                            : null
                    );
                    insert opportunityProduct;
                }
                response.result = new Map<String, Object>{ 'Order' => newOrder, 'OrderItem' => newOrderItem };
            }

            if (!isGuestUser) {
                POE_ACI_Statistic__c aciStatistic = [
                    SELECT Id, Product_Selection__c, Order__c
                    FROM POE_ACI_Statistic__c
                    WHERE Opportunity__c = :contextId
                    LIMIT 1
                ];

                aciStatistic.Order__c = newOrder.Id;
                update aciStatistic;
            }

            Opportunity opportunity = new Opportunity(
                Id = contextId,
                POE_Credit_Risk_Score__c = creditScoreResult,
                POE_Identification_Method__c = identification
            );
            update opportunity;

            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper getAccountOnProbation() {
        try {
            ResponseWrapper response = new ResponseWrapper();
            Id runningUserId = UserInfo.getUserId();

            User runningUser = [SELECT Id, Account.On_Probation__c FROM User WHERE Id = :runningUserId];

            response.result = new Map<String, Object>{ 'onProbation' => runningUser.Account.On_Probation__c };

            return response;
        } catch (AuraHandledException e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper setFraudFlag(Map<String, Object> myData) {
        try {
            String contextId = (String) myData.get('ContextId');

            ResponseWrapper response = new ResponseWrapper();

            Opportunity oppToUpdate = new Opportunity(
                Id = contextId,
                POE_FraudObservation__c = true,
                StageName = 'Security Stop'
            );

            update oppToUpdate;

            response.result = new Map<String, Object>{ 'Opportunity' => oppToUpdate };

            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper customerReachedCap(Map<String, Object> myData) {
        String email = (String) myData.get('Email');
        Boolean capReached = false;
        Boolean runningInASandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;

        ResponseWrapper response = new ResponseWrapper();
        Date orderDate = Date.today().addMonths(-12);

        List<Order> createdOrders = [
            SELECT Id
            FROM Order
            WHERE
                Account.PersonEmail = :email
                AND CreatedDate > :orderDate
                AND (Status = 'Pending Installation'
                OR Status = 'Activated')
        ];

        capReached = createdOrders.size() >= 3 && !runningInASandbox;

        response.result = new Map<String, Object>{ 'capReached' => capReached };

        return response;
    }

    @AuraEnabled(cacheable=true)
    public static ResponseWrapper getPOBoxRegEx() {
        try {
            ResponseWrapper res = new ResponseWrapper();

            POE_Chuzo_Regular_Expressions__mdt regex = [
                SELECT RegEx__c
                FROM POE_Chuzo_Regular_Expressions__mdt
                WHERE DeveloperName = 'PO_Box_RegEx'
                LIMIT 1
            ];

            res.result = new Map<String, Object>{ 'poBoxRegEx' => regex.RegEx__c };
            return res;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class ResponseWrapper {
        @AuraEnabled
        public Map<String, Object> result;
    }
}
global without sharing class POEUpsertIframeClientData implements vlocity_cmt.VlocityOpenInterface {
    global Boolean invokeMethod(
        String methodName,
        Map<String, Object> inputMap,
        Map<String, Object> outMap,
        Map<String, Object> options
    ) {
        Boolean result = true;

        try {
            if ('upsertClient'.equalsIgnoreCase(methodName)) {
                upsertClient(inputMap, outMap, options);
            } else {
                result = false;
            }
        } catch (Exception e) {
            result = false;
        }
        return result;
    }

    public Map<String, Object> upsertClient(
        Map<String, Object> inputMap,
        Map<String, Object> outMap,
        Map<String, Object> options
    ) {
        String recordId = (String) inputMap.get('recordId');
        String firstName = (String) inputMap.get('firstName');
        String lastName = (String) inputMap.get('lastName');
        String street = (String) inputMap.get('street');
        String addressLine2 = (String) inputMap.get('addressLine2');
        String city = (String) inputMap.get('city');
        String state = (String) inputMap.get('state');
        String stateName = (String) inputMap.get('stateName');
        String zipCode = (String) inputMap.get('zipCode');
        String phone = (String) inputMap.get('phone');
        String mobile = (String) inputMap.get('mobile');
        if (phone == null || phone == '') {
            phone = mobile;
        }
        String email = (String) inputMap.get('email');
        String origin = (String) inputMap.get('origin');
        String program = (String) inputMap.get('program');
        String programOtherDetail = (String) inputMap.get('programOtherDetail');
        String programOtherProvider = (String) inputMap.get('programOtherProvider');
        String description = (String) inputMap.get('productDescription');
        Boolean isCallOrder = Boolean.valueOf(inputMap.get('isCallOrder'));
        if (addressLine2 != null && addressLine2 != '') {
            street += ' ' + addressLine2;
        }
        Boolean consent = Boolean.valueOf(inputMap.get('consent') ?? false);

        String fullName = firstName + ' ' + lastName;
        Id consRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get('Person Account')
            .getRecordTypeId();
        Id orderRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName()
            .get('Standard Order')
            .getRecordTypeId();
        List<Account> existingAccount = new List<Account>();
        String orderType = '';
        if (program == 'Other') {
            orderType = 'Other';
        } else {
            orderType = 'Closed Won';
        }
        String accountId = '';
        String representativeType = '';
        if (origin == 'phonesales') {
            representativeType = 'Phone Sales';
        } else if (origin == 'retail') {
            representativeType = 'Retail';
        } else if (origin == 'event') {
            representativeType = 'Event';
        } else {
            representativeType = 'Door To Door';
        }
        List<Account> accountUpdate = new List<Account>();

        Opportunity queryOpp = [SELECT Id, AccountId, Account.Name FROM Opportunity WHERE Id = :recordId LIMIT 1];

        if(!String.isBlank(queryOpp.AccountId) && queryOpp.Account.Name != 'Customer To Be Determined' && !Test.isRunningTest()) {
            existingAccount = [SELECT Id, FirstName, LastName, Consent_to_Automated_Communications__c FROM Account WHERE Id = :queryOpp.AccountId];
        } else {
            existingAccount = [
                SELECT
                    Id,
                    FirstName,
                    LastName,
                    BillingStreet,
                    BillingCity,
                    BillingState,
                    BillingStateCode,
                    BillingPostalCode,
                    ShippingStreet,
                    ShippingCity,
                    BillingCountry,
                    BillingCountryCode,
                    ShippingCountry,
                    ShippingCountryCode,
                    ShippingState,
                    ShippingStateCode,
                    ShippingPostalCode,
                    POE_Secondary_Phone__c,
                    Consent_to_Automated_Communications__c,
                    PersonEmail
                FROM Account
                WHERE
                    Name = :fullName
                    AND RecordTypeId = :consRecordTypeId
                    AND BillingStreet = :street
                    AND BillingCity = :city
                    AND (BillingStateCode = :state
                    OR BillingState = :stateName)
                    AND BillingPostalCode = :zipCode
                    AND ShippingStreet = :street
                    AND ShippingCity = :city
                    AND (ShippingStateCode = :state
                    OR ShippingState = :stateName)
                    AND ShippingPostalCode = :zipCode
                    AND Phone = :phone
            ];
        }
        if (existingAccount.isEmpty()) {
            Account customer = new Account();
            customer.FirstName = firstName;
            customer.LastName = lastName;
            customer.BillingStreet = street;
            customer.BillingCity = city;
            customer.BillingStateCode = state;
            customer.BillingPostalCode = zipCode;
            customer.Billing_Address_Line_2__c = addressLine2;
            customer.BillingCountry = 'United States';
            customer.ShippingCountry = 'United States';
            customer.Shipping_Address_Line_2__c = addressLine2;
            customer.ShippingStreet = street;
            customer.ShippingCity = city;
            customer.ShippingStateCode = state;
            customer.ShippingPostalCode = zipCode;
            customer.Phone = phone;
            customer.POE_Secondary_Phone__c = mobile;
            customer.PersonEmail = email;
            customer.RecordTypeId = consRecordTypeId;
            customer.Consent_to_Automated_Communications__c = consent;
            insert customer;
            accountId = customer.Id;
        } else {
            for (Account cust : existingAccount) {
                if (cust.Consent_to_Automated_Communications__c) {
                    consent = true;
                }
                cust.FirstName = firstName;
                cust.LastName = lastName;
                cust.BillingStreet = street;
                cust.BillingCity = city;
                cust.BillingStateCode = state;
                cust.BillingPostalCode = zipCode;
                cust.BillingCountry = 'United States';
                cust.ShippingCountry = 'United States';
                cust.Shipping_Address_Line_2__c = addressLine2;
                cust.Billing_Address_Line_2__c = addressLine2;
                cust.ShippingStreet = street;
                cust.ShippingCity = city;
                cust.ShippingStateCode = state;
                cust.ShippingPostalCode = zipCode;
                cust.Phone = phone;
                cust.POE_Secondary_Phone__c = mobile;
                cust.Consent_to_Automated_Communications__c = consent;
                cust.PersonEmail = email;
                accountId = cust.Id;
                accountUpdate.add(cust);
            }
            update accountUpdate;
        }

        Opportunity opp = [SELECT Id, AccountId, Referral_Code__r.Id FROM Opportunity WHERE Id = :recordId];
        opp.AccountId = accountId;
        String referralCodeId;
        if (opp.Referral_Code__r != null) {
            referralCodeId = opp.Referral_Code__r.Id;
        }

        update opp;

        Pricebook2 stdPriceBook = [SELECT Id, Name FROM Pricebook2 WHERE isStandard = TRUE LIMIT 1];

        List<Order> existingOrders = [SELECT Id, OpportunityId FROM Order WHERE OpportunityId = :opp.Id];
        Order ord = new Order();

        if (existingOrders.isEmpty()) {
            ord.AccountId = accountId;
            ord.OpportunityId = recordId;
            ord.BillingStreet = street;
            ord.BillingCity = city;
            ord.BillingStateCode = state;
            ord.BillingPostalCode = zipCode;
            ord.ShippingStreet = street;
            ord.ShippingCity = city;
            ord.ShippingStateCode = state;
            ord.ShippingPostalCode = zipCode;
            ord.POE_Program__c = program;
            ord.Type = orderType;
            ord.Pricebook2Id = stdPriceBook.Id;
            ord.RecordTypeId = orderRecordTypeId;
            ord.POE_RepTitle__c = representativeType;
            ord.Phone__c = phone;
            ord.Email__c = email;
            ord.EffectiveDate = System.today();
            ord.Status = 'Draft';
            ord.POE_Program_Other_Detail__c = programOtherDetail;
            ord.POE_Program_Other_Provider__c = programOtherProvider;
            ord.POE_Call_Order__c = isCallOrder;
            ord.POE_Description__c = description;
            if (String.isNotBlank(referralCodeId)) {
                ord.Referral_Code__c = referralCodeId;
            }
            insert ord;
        } else {
            ord.Id = existingOrders[0].Id;
            ord.AccountId = accountId;
            ord.OpportunityId = recordId;
            ord.BillingStreet = street;
            ord.BillingCity = city;
            ord.BillingStateCode = state;
            ord.BillingPostalCode = zipCode;
            ord.ShippingStreet = street;
            ord.ShippingCity = city;
            ord.ShippingStateCode = state;
            ord.ShippingPostalCode = zipCode;
            ord.Phone__c = phone;
            ord.Email__c = email;
            ord.POE_Program__c = program;
            ord.Type = orderType;
            ord.Pricebook2Id = stdPriceBook.Id;
            ord.RecordTypeId = orderRecordTypeId;
            ord.POE_RepTitle__c = representativeType;
            ord.EffectiveDate = System.today();
            ord.POE_Program_Other_Detail__c = programOtherDetail;
            ord.POE_Program_Other_Provider__c = programOtherProvider;
            ord.Status = 'Draft';
            ord.POE_Call_Order__c = isCallOrder;
            ord.POE_Description__c = description;
            if (String.isNotBlank(referralCodeId)) {
                ord.Referral_Code__c = referralCodeId;
            }
            update ord;
        }

        outMap.put('Opportunity', opp);
        outMap.put('Order', ord);
        return outMap;
    }
}
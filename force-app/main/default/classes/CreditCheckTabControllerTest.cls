@isTest
public class CreditCheckTabControllerTest {
    @TestSetup
    static void makeData() {
        Id personAccountRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('PersonAccount')
            .getRecordTypeId();

        Account acc = new Account(
            FirstName = 'test',
            LastName = 'test',
            PersonEmail = 'test@test.com',
            RecordTypeId = personAccountRTId
        );
        insert acc;

        Opportunity opp = new Opportunity(
            AccountId = acc.Id,
            Maps_PostalCode__c = '1234',
            Maps_Street__c = 'Test street',
            Maps_AptNumber__c = '1234',
            Maps_Building__c = '4',
            Maps_City__c = 'Test city',
            Maps_Country__c = 'test country',
            Maps_Floor__c = '3',
            Maps_Latitude__c = 1.23151,
            Maps_Longitude__c = 2.4214,
            Maps_State__c = 'Texas',
            Name = 'Test Opportunity',
            POE_Clicker_Origin__c = 'phonesales',
            StageName = 'Contact',
            CloseDate = Date.today(),
            POE_Credit_Check_Limit_Reached__c = false,
            POE_SSN_Agreement__c = false,
            POE_Fraud_Flag_IP__c = null,
            POE_QuantityOfAttempts__c = 0
        );
        insert opp;

        String unencryptedTestCCData = '{"sensitiveData":{"ccDob":"1991-09-20","ccSSN":"123456789","ccDlExpirationDate":"2050-09-20","ccDlState":"CA","ccDriversLicenseNumber":"Test"}}';
        Map<String, Object> creditCheckDataMap = (Map<String, Object>) JSON.deserializeUntyped(unencryptedTestCCData);
        creditCheckDataMap.put('opportunityId', opp.Id);
        POECCEncryptionService.ResponseWrapper result = POECCEncryptionService.encryptAndSaveCreditCheckData(
            creditCheckDataMap
        );

        POE_ACI_Statistic__c oppStatistic = new POE_ACI_Statistic__c(Opportunity__c = opp.Id);
        insert oppStatistic;

        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        update standardPricebook;

        Product2 prod = new Product2(Name = 'Test');
        insert prod;

        PricebookEntry pe = new PricebookEntry(
            Product2Id = prod.Id,
            Pricebook2Id = standardPricebook.Id,
            UnitPrice = 100,
            isActive = true
        );
        insert pe;

        Fraud_Validation_Rules__c ssnValidationRule = new Fraud_Validation_Rules__c(
            Name = 'SSNRun',
            Number_Of_Times__c = 0
        );
        insert ssnValidationRule;

        OpportunityLineItem oppLineItem = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pe.Id,
            UnitPrice = pe.UnitPrice,
            Quantity = 1
        );
        insert oppLineItem;
    }

    @isTest
    static void updateOpportunityTest() {
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;

        Test.startTest();
        CreditCheckTabController.ResponseWrapper response = CreditCheckTabController.updateOpportunity(
            new Map<String, Object>{ 'Id' => oppId, 'creditCheckLimitReached' => true }
        );
        Test.stopTest();

        Opportunity updatedOpp = [SELECT Id, POE_Credit_Check_Limit_Reached__c FROM Opportunity WHERE Id = :oppId];
        Assert.isTrue(
            updatedOpp.POE_Credit_Check_Limit_Reached__c,
            'The Opportunity\'s POE_Credit_Check_Limit_Reached__c field was not updated as expected.'
        );
        Assert.isNotNull(response.result, 'The result map is null.');
        Assert.isTrue((Boolean) response.result.get('status'), 'The result status is not true on success.');
    }

    @isTest
    static void setSSNAgreementTest() {
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;

        Test.startTest();
        CreditCheckTabController.ResponseWrapper response = CreditCheckTabController.setSSNAgreement(
            new Map<String, Object>{ 'ContextId' => oppId, 'value' => true }
        );
        Test.stopTest();

        Opportunity updatedOpp = [SELECT Id, POE_SSN_Agreement__c FROM Opportunity WHERE Id = :oppId];
        Assert.isTrue(
            updatedOpp.POE_SSN_Agreement__c,
            'The Opportunity\'s POE_SSN_Agreement__c field was not updated as expected.'
        );
    }

    @isTest
    static void getSSNFraudRulesTest() {
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;

        Test.startTest();
        CreditCheckTabController.ResponseWrapper response = CreditCheckTabController.getSSNFraudRules(
            new Map<String, Object>{ 'ContextId' => oppId, 'partner' => 'directv' }
        );
        Test.stopTest();

        Assert.isTrue(response.result.containsKey('refNum'), 'The "refNum" key was not included in the result Map');
        Assert.isTrue(response.result.containsKey('limit'), 'The "limit" key was not included in the result Map');
        Assert.isTrue(response.result.containsKey('recType'), 'The "recType" key was not included in the result Map');
        Assert.isTrue(response.result.containsKey('offer'), 'The "offer" key was not included in the result Map');
        Assert.isTrue(response.result.containsKey('attempts'), 'The "attempts" key was not included in the result Map');
        Assert.isTrue(response.result.containsKey('key'), 'The "key" key was not included in the result Map');
    }

    @isTest
    static void saveFlagIPTest() {
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        String testIp = '255.255.255.255';

        Test.startTest();
        CreditCheckTabController.ResponseWrapper response = CreditCheckTabController.saveFlagIP(
            new Map<String, Object>{ 'ContextId' => oppId, 'IP' => testIp }
        );
        Test.stopTest();

        Opportunity updatedOpp = [SELECT Id, POE_Fraud_Flag_IP__c FROM Opportunity WHERE Id = :oppId];
        Assert.areEqual(
            testIp,
            updatedOpp.POE_Fraud_Flag_IP__c,
            'The Opportunity\'s POE_Fraud_Flag_IP__c field was not updated as expected.'
        );
    }

    @isTest
    static void saveAccountInformationTest() {
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        String identification = 'Social Security Number';

        Map<Object, Object> billingCreditCheckAddressMap = new Map<Object, Object>{
            'billingAddress' => 'test',
            'billingAptNumber' => '12',
            'billingCity' => 'test',
            'billingState' => 'CA',
            'billingZip' => '11000'
        };
        Map<Object, Object> accountDetailsMap = new Map<Object, Object>{
            'billingCreditCheckAddress' => billingCreditCheckAddressMap
        };
        Map<Object, Object> contactInformationMap = new Map<Object, Object>{
            'firstName' => 'test',
            'middleName' => 'test',
            'lastName' => 'test',
            'email' => 'test@test.com',
            'contactPhone' => '123412341'
        };
        Map<Object, Object> customerDetailsMap = new Map<Object, Object>{
            'contactInformation' => contactInformationMap
        };
        Map<Object, Object> creditCheckMap = new Map<Object, Object>{
            'accountDetails' => accountDetailsMap,
            'customerDetails' => customerDetailsMap
        };
        Test.startTest();
        CreditCheckTabController.ResponseWrapper response = CreditCheckTabController.saveAccountInformation(
            new Map<String, Object>{
                'ContextId' => oppId,
                'addressDiscrepancy' => true,
                'recordTypeId' => Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                    .get('PersonAccount')
                    .getRecordTypeId(),
                'accName' => 'Test',
                'creditCheck' => creditCheckMap,
                'identification' => identification
            }
        );
        Test.stopTest();

        Account resultAcc = (Account) response.result.get('Account');
        Assert.isNotNull(resultAcc, 'The response did not include the created Account.');
        Assert.isTrue((Boolean) String.isNotBlank(resultAcc.Id), 'The Account was not created or its Id is blank.');

        Opportunity updatedOpp = [SELECT Id, POE_Identification_Method__c, AccountId FROM Opportunity LIMIT 1];
        Assert.areEqual(resultAcc.Id, updatedOpp.AccountId, 'The Opportunity was not related to the inserted Account.');
        Assert.areEqual(
            identification,
            updatedOpp.POE_Identification_Method__c,
            'The Opportunity\'s POE_Identification_Method__c field was not updated as expected.'
        );
    }

    @isTest
    static void saveNewOrderTest() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Account acc = new Account(Name = 'test');
        insert acc;

        opp.AccountId = acc.Id;
        update opp;

        Product2 prod = [SELECT Name FROM Product2 LIMIT 1];

        String identification = 'Social Security Number';

        Map<Object, Object> billingCreditCheckAddressMap = new Map<Object, Object>{
            'billingAddress' => 'test',
            'billingAptNumber' => '12',
            'billingCity' => 'test',
            'billingState' => 'CA',
            'billingZip' => '11000'
        };
        Map<Object, Object> accountDetailsMap = new Map<Object, Object>{
            'billingCreditCheckAddress' => billingCreditCheckAddressMap
        };
        Map<Object, Object> creditCheckMap = new Map<Object, Object>{ 'accountDetails' => accountDetailsMap };
        List<Object> services = new List<Object>{ new Map<Object, Object>{ 'Name' => prod.Name } };

        Test.startTest();
        CreditCheckTabController.ResponseWrapper response = CreditCheckTabController.saveNewOrder(
            new Map<String, Object>{
                'ContextId' => opp.Id,
                'timeStamp' => Date.today(),
                'AccountId' => acc.Id,
                'family' => 'EarthLink',
                'Pricebook' => [SELECT Name FROM Pricebook2 WHERE IsStandard = TRUE LIMIT 1]
                .Name,
                'ProductName' => prod.Name,
                'addressDiscrepancy' => true,
                'Services' => services,
                'recordTypeId' => Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                    .get('PersonAccount')
                    .getRecordTypeId(),
                'creditCheck' => creditCheckMap
            }
        );
        Test.stopTest();

        Order resultOrd = (Order) response.result.get('Order');
        Assert.isNotNull(resultOrd, 'The response did not include the created Order.');
        Assert.isTrue((Boolean) String.isNotBlank(resultOrd.Id), 'The Order was not created or its Id is blank.');
        OrderItem resultOrdItem = (OrderItem) response.result.get('OrderItem');
        Assert.isNotNull(resultOrdItem, 'The response did not include the created OrderItem.');
        Assert.isTrue(String.isNotBlank(resultOrdItem.Id), 'The OrderItem was not created or its Id is blank.');

        Integer orderItemCount = [SELECT COUNT() FROM OrderItem];
        Assert.areEqual(2, orderItemCount, 'The OrderItem from the Services array was not created.');

        POE_ACI_Statistic__c statistic = [
            SELECT Id, Order__c
            FROM POE_ACI_Statistic__c
            WHERE Opportunity__c = :opp.Id
            LIMIT 1
        ];
        Assert.areEqual(
            resultOrd.Id,
            statistic.Order__c,
            'The Ids from the created Order and the ACI Statistic for the Opportunity do not match.'
        );

        Opportunity updatedOpp = [SELECT POE_AddressDiscrepancy__c FROM Opportunity WHERE Id = :opp.Id];
        Assert.isTrue(
            updatedOpp.POE_AddressDiscrepancy__c,
            'The POE_AddressDiscrepancy__c field of the Opportunity record was not updated as expected.'
        );
    }

    @isTest
    static void saveACICreditCheckTest() {
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;

        Test.startTest();
        CreditCheckTabController.ResponseWrapper response = CreditCheckTabController.saveACICreditCheck(
            new Map<String, Object>{ 'ContextId' => oppId }
        );
        Test.stopTest();

        POE_ACI_Statistic__c statistic = [
            SELECT Id, Credit_Check__c
            FROM POE_ACI_Statistic__c
            WHERE Opportunity__c = :oppId
            LIMIT 1
        ];
        Assert.areEqual(
            1,
            statistic.Credit_Check__c,
            'The ACI Statistic\'s Credit_Check__c field was not updated as expected.'
        );
    }

    @isTest
    static void getOppSensitiveDataTest() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        CreditCheckTabController.ResponseWrapper response = CreditCheckTabController.getOppSensitiveData(
            new Map<String, Object>{ 'ContextId' => opp.Id }
        );
        Test.stopTest();

        Assert.isNotNull(response.result, 'The response did not include a result Map.');

        String resultBirthdate = (String) response.result.get('ccDob');
        String resultDLExpirationDate = (String) response.result.get('ccDlExpirationDate');
        String resultDLState = (String) response.result.get('ccDlState');
        String resultDLNumber = (String) response.result.get('ccDriversLicenseNumber');
        String resultSSN = (String) response.result.get('ccSSN');

        Assert.areEqual(
            '1991-09-20',
            resultBirthdate,
            'The result\'s ccDob field does not match the Opportunity\'s encrypted field.'
        );
        Assert.areEqual(
            '2050-09-20',
            resultDLExpirationDate,
            'The result\'s resultDLExpirationDate field does not match the Opportunity\'s encrypted field.'
        );
        Assert.areEqual(
            'CA',
            resultDLState,
            'The result\'s ccDlState field does not match the Opportunity\'s encrypted field.'
        );
        Assert.areEqual(
            'Test',
            resultDLNumber,
            'The result\'s ccDriversLicenseNumber field does not match the Opportunity\'s encrypted field.'
        );
        Assert.areEqual(
            '123456789',
            resultSSN,
            'The result\'s ccSSN field does not match the Opportunity\'s encrypted field.'
        );
    }

    @isTest
    static void sendPCISMSTest() {
        Test.setMock(HttpCalloutMock.class, new POESMSHttpCalloutMock());
        Test.startTest();
        CreditCheckTabController.ResponseWrapper response = CreditCheckTabController.sendPCISMS(
            new Map<String, Object>{
                'clientPhone' => '111111111',
                'body' => 'Test',
                'opportunityId' => [SELECT Id FROM Opportunity LIMIT 1]
                .Id
            }
        );
        Test.stopTest();

        Assert.isTrue((Boolean) response.result.get('success'), 'The result was not successful when expected.');
    }

    @isTest
    static void sendCreditCheckPciEmailTest() {
        String testEmail = 'test@example.com';
        String testBody = 'https://www.test.com';

        Test.startTest();
        CreditCheckTabController.ResponseWrapper response = CreditCheckTabController.sendCreditCheckPciEmail(
            new Map<String, Object>{ 'pciEmail' => testEmail, 'body' => testBody }
        );
        Integer emailInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        Assert.areEqual(1, emailInvocations, 'No email was sent or email invocations were not updated as expected.');
        Assert.isFalse(
            (Boolean) response.result.get('error'),
            'The response includes an error when the operation was successful.'
        );
    }

    @isTest
    static void getProviderPhoneNumberTest() {
        Test.startTest();
        CreditCheckTabController.ResponseWrapper response = CreditCheckTabController.getProviderPhoneNumber(
            new Map<String, Object>{ 'provider' => 'Windstream', 'use' => 'Review' }
        );
        Test.stopTest();

        Assert.areEqual(
            null,
            response.result.get('error'),
            'The response includes an error when the operation was successful.'
        );
    }

    @isTest
    static void saveCreditFreezeTest() {
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        Test.startTest();
        CreditCheckTabController.ResponseWrapper response = CreditCheckTabController.saveCreditFreeze(
            new Map<String, Object>{ 'ContextId' => oppId }
        );
        Test.stopTest();

        Assert.areEqual(
            null,
            response.result.get('error'),
            'The response includes an error when the operation was successful.'
        );
    }

    @isTest
    static void IPSaveOrderDTVTest() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Account acc = new Account(Name = 'test');
        insert acc;

        opp.AccountId = acc.Id;
        update opp;

        Product2 prod = [SELECT Name FROM Product2 LIMIT 1];

        String identification = 'Social Security Number';

        Map<Object, Object> billingCreditCheckAddressMap = new Map<Object, Object>{
            'billingAddress' => 'test',
            'billingAptNumber' => '12',
            'billingCity' => 'test',
            'billingState' => 'CA',
            'billingZip' => '11000'
        };
        Map<Object, Object> accountDetailsMap = new Map<Object, Object>{
            'billingCreditCheckAddress' => billingCreditCheckAddressMap
        };
        Map<Object, Object> creditCheckMap = new Map<Object, Object>{ 'accountDetails' => accountDetailsMap };
        List<Object> services = new List<Object>{ new Map<Object, Object>{ 'Name' => prod.Name } };

        Test.startTest();
        CreditCheckTabController.ResponseWrapper response = CreditCheckTabController.IPSaveOrderDTV(
            new Map<String, Object>{
                'ContextId' => opp.Id,
                'timeStamp' => String.valueOf(Date.today()),
                'AccountId' => acc.Id,
                'isGuestUser' => false,
                'family' => 'DirecTV',
                'Pricebook' => [SELECT Name FROM Pricebook2 WHERE IsStandard = TRUE LIMIT 1]
                .Name,
                'ProductName' => prod.Name,
                'identification' => 'Social Security Number',
                'creditScoreResult' => 'High',
                'addressDiscrepancy' => true,
                'Services' => services,
                'recordTypeId' => Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                    .get('PersonAccount')
                    .getRecordTypeId(),
                'creditCheck' => creditCheckMap,
                'phone' => '4543453453',
                'email' => 'test@orderdtv.com',
                'consent' => false
            }
        );
        Test.stopTest();

        Order resultOrd = (Order) response.result.get('Order');
        Assert.isNotNull(resultOrd, 'The response did not include the created Order.');
        Assert.isTrue(String.isNotBlank(resultOrd.Id), 'The Order was not created or its Id is blank.');
        OrderItem resultOrdItem = (OrderItem) response.result.get('OrderItem');
        Assert.isNotNull(resultOrdItem, 'The response did not include the created OrderItem.');
        Assert.isTrue(String.isNotBlank(resultOrdItem.Id), 'The OrderItem was not created or its Id is blank.');

        Integer orderItemCount = [SELECT COUNT() FROM OrderItem];
        Assert.areEqual(1, orderItemCount, 'The OrderItem was not created.');

        POE_ACI_Statistic__c statistic = [
            SELECT Id, Order__c
            FROM POE_ACI_Statistic__c
            WHERE Opportunity__c = :opp.Id
            LIMIT 1
        ];
        Assert.areEqual(
            resultOrd.Id,
            statistic.Order__c,
            'The Ids from the created Order and the ACI Statistic for the Opportunity do not match.'
        );
    }

    @isTest
    static void saveOrderSpectrumBuyflowTest() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Account acc = new Account(Name = 'test');
        insert acc;

        opp.AccountId = acc.Id;
        update opp;

        Product2 prod = [SELECT Name FROM Product2 LIMIT 1];

        String identification = 'Social Security Number';

        Map<Object, Object> billingCreditCheckAddressMap = new Map<Object, Object>{
            'billingAddress' => 'test',
            'billingAptNumber' => '12',
            'billingCity' => 'test',
            'billingState' => 'CA',
            'billingZip' => '11000'
        };
        Map<Object, Object> accountDetailsMap = new Map<Object, Object>{
            'billingCreditCheckAddress' => billingCreditCheckAddressMap
        };
        Map<Object, Object> creditCheckMap = new Map<Object, Object>{ 'accountDetails' => accountDetailsMap };
        List<Object> services = new List<Object>{ new Map<Object, Object>{ 'Name' => prod.Name } };

        Test.startTest();
        CreditCheckTabController.ResponseWrapper response = CreditCheckTabController.IPSaveOrderDTV(
            new Map<String, Object>{
                'ContextId' => opp.Id,
                'timeStamp' => String.valueOf(Date.today()),
                'AccountId' => acc.Id,
                'isGuestUser' => false,
                'family' => 'Charter/Spectrum',
                'Pricebook' => [SELECT Name FROM Pricebook2 WHERE IsStandard = TRUE LIMIT 1]
                .Name,
                'ProductName' => prod.Name,
                'identification' => 'Social Security Number',
                'creditScoreResult' => 'High',
                'addressDiscrepancy' => true,
                'Services' => services,
                'recordTypeId' => Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                    .get('PersonAccount')
                    .getRecordTypeId(),
                'creditCheck' => creditCheckMap,
                'phone' => '4543453453',
                'email' => 'test@orderdtv.com',
                'consent' => false
            }
        );
        Test.stopTest();

        Order resultOrd = (Order) response.result.get('Order');
        Assert.isNotNull(resultOrd, 'The response did not include the created Order.');

        Assert.areNotEqual(resultOrd.Id, null, 'The Order was not created or its Id is null.');

        Map<String, OrderItem> resultOrdItems = (Map<String, OrderItem>) response.result.get('OrderItems');
        Assert.isNotNull(resultOrdItems, 'The response did not include the created OrderItems.');
        Assert.isTrue(!resultOrdItems.isEmpty(), 'No OrderItems were created for the Order.');

        POE_ACI_Statistic__c statistic = [
            SELECT Id, Order__c
            FROM POE_ACI_Statistic__c
            WHERE Opportunity__c = :opp.Id
            LIMIT 1
        ];
        System.assertEquals(
            resultOrd.Id,
            statistic.Order__c,
            'The OrderId in the ACI Statistic does not match the created Order.'
        );
    }

    @isTest
    static void getAccountOnProbationTest() {
        Test.startTest();
        CreditCheckTabController.ResponseWrapper response = CreditCheckTabController.getAccountOnProbation();
        Test.stopTest();

        Assert.isTrue(
            response.result.containsKey('onProbation'),
            'The "onProbation" key was not included in the result Map'
        );
    }

    @isTest
    static void setFraudFlag_test() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        test.startTest();
        CreditCheckTabController.ResponseWrapper response = CreditCheckTabController.setFraudFlag(
            new Map<String, Object>{ 'ContextId' => opp.Id }
        );
        test.stopTest();

        Opportunity responseOpp = (Opportunity) response.result.get('Opportunity');

        Assert.areEqual(opp.Id, responseOpp.Id, 'Ids do not match');
        Assert.isTrue(responseOpp.POE_FraudObservation__c, 'Fraud flag do not match');
        Assert.areEqual('Security Stop', responseOpp.StageName, 'Stage do not match');
    }

    @isTest
    static void customerReachedCap() {
        Test.startTest();
        CreditCheckTabController.ResponseWrapper response = CreditCheckTabController.customerReachedCap(
            new Map<String, Object>{ 'Email' => 'test@test.com' }
        );
        Test.stopTest();

        Assert.isFalse((Boolean) response.result.get('capReached'), 'Orders cap reached');
    }

    @isTest
    static void getPOBoxRegExTest() {
        Test.startTest();
        CreditCheckTabController.ResponseWrapper res = CreditCheckTabController.getPOBoxRegEx();
        Test.stopTest();

        Assert.isNotNull(res.result.get('poBoxRegEx'), 'No regular expression was returned in the poBoxRegEx field.');
    }

    @IsTest
    static void testSuccessfulGetSSNAgreement() {
        Map<String, Object> myData = new Map<String, Object>{ 'ContextId' => [SELECT Id FROM Opportunity LIMIT 1].Id };
        Test.startTest();
        CreditCheckTabController.ResponseWrapper response = CreditCheckTabController.getSSNAgreement(myData);
        Test.stopTest();
        Map<String, Object> resultMap = (Map<String, Object>) response.result;
        Opportunity resultOpportunity = (Opportunity) resultMap.get('Opportunity');
        Assert.areNotEqual(null, resultOpportunity, 'Opportunity should be returned');
        Assert.areEqual(false, resultOpportunity.POE_SSN_Agreement__c, 'Agreement should match');
    }
}
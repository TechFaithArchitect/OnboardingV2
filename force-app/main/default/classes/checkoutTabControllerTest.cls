@isTest
public class checkoutTabControllerTest {
    @TestSetup
    static void makeData() {
        Opportunity opp = new Opportunity(Name = 'test opp', StageName = 'Presentation', CloseDate = Date.today());
        insert opp;
        String unencryptedTestCCData = '{"creditCardData":{"useSameCardAsAutoPay":false,"hasAutoPay":false,"hasACH":true,"upFront":{"ccNumber":"5555555555554444","firstName":"Test","lastName":"Name","ccMonth":12,"ccYear":26,"ccv":542,"cardholderName":"Test Name","zipCode":54323,"type":"Visa"},"ach":{"achAccountFirstName":"Test","achAccountLastName":"Name","achBankRoutingNumber":"123456789","achBankAccountNumber":"1234567890","achAccountType":"Checking","achAccountClass":"Personal"},"autoPay":{}}}';
        Map<String, Object> creditCardDataMap = (Map<String, Object>) JSON.deserializeUntyped(unencryptedTestCCData);
        creditCardDataMap.put('opportunityId', opp.Id);
        POECCEncryptionService.ResponseWrapper result = POECCEncryptionService.encryptAndSaveCreditCardData(
            creditCardDataMap
        );
    }

    @isTest
    static void test_getCreditCardTypes() {
        test.startTest();
        checkoutTabController.ResponseWrapper response = checkoutTabController.getCreditCardTypes();
        test.stopTest();

        List<Credit_Card_Types__mdt> result = (List<Credit_Card_Types__mdt>) response.result.get(
            'Credit_Card_Types__mdt'
        );
        system.debug(result);

        system.assertEquals(false, result.isEmpty(), 'result array shouldn\'t be empty');
    }

    @isTest
    static void test_getCreditCardInformation() {
        Id opp = [SELECT Id FROM Opportunity LIMIT 1].Id;

        test.startTest();
        checkoutTabController.ResponseWrapper response = checkoutTabController.getCreditCardInformation(
            new Map<String, Object>{ 'ContextId' => opp }
        );
        test.stopTest();
        Map<String, Object> result = (Map<String, Object>) response.result;
        System.assert.isFalse(result.isEmpty(), 'CC Data is not empty');
        System.assert.areEqual('5555555555554444', (String) result.get('ccNumber'), 'Expected CC number');
    }

    @isTest
    static void test_getEarthlinkKeys() {
        Map<String, String> mapInput = new Map<String, String>();
        mapInput.put('env', 'dev');
        mapInput.put('program', 'spectrum');
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CheckoutTabControllerHttpCalloutMock());
        checkoutTabController.ResponseWrapper response = checkoutTabController.getEarthlinkKeys(mapInput);
        Test.stopTest();

        System.assertEquals('4', (String) response.result.get('L'), 'L values don\'t match');
        System.assertEquals('2', (String) response.result.get('E'), 'E values don\'t match');
        System.assertEquals(
            '12312312312312312312312312312312',
            (String) response.result.get('K'),
            'K values don\'t match'
        );
        System.assertEquals('12345678', (String) response.result.get('key_id'), 'keyId values don\'t match');
        System.assertEquals('3', (String) response.result.get('phase'), 'Phase values don\'t match');
    }
    @isTest
    static void testUpdateAccountBillingAddress() {
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

        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId());

        Product2 prod = new Product2(Name = 'Test');
        insert prod;

        PricebookEntry pe = new PricebookEntry(
            Product2Id = prod.Id,
            Pricebook2Id = standardPricebook.Id,
            UnitPrice = 100,
            isActive = true
        );
        insert pe;

        Id stdOrderRTId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName()
            .get('StandardOrder')
            .getRecordTypeId();

        Order order = new Order(
            Name = acc.Name,
            EffectiveDate = System.today(),
            Status = 'Draft',
            Type = 'Closed Won',
            RecordTypeId = stdOrderRTId,
            OpportunityId = opp.Id,
            AccountId = acc.Id,
            Pricebook2Id = standardPricebook.Id
        );
        insert order;

        Order ord = [
            SELECT
                Id,
                AccountId,
                BillingPostalCode,
                BillingCity,
                BillingState,
                BillingStateCode,
                BillingStreet,
                BillingCountry
            FROM Order
            WHERE AccountId = :acc.Id
            LIMIT 1
        ];

        Map<Object, Object> billingCheckOutAddress = new Map<Object, Object>();
        billingCheckOutAddress.put('billingAddress', '12410 Alameda Trace Cir');
        billingCheckOutAddress.put('billingAptNumber', 'Apt W1721');
        billingCheckOutAddress.put('billingCity', 'Austin');
        billingCheckOutAddress.put('billingState', 'TX');
        billingCheckOutAddress.put('billingStateName', 'Texas');
        billingCheckOutAddress.put('billingCountry', 'United States');
        billingCheckOutAddress.put('billingZip', '78727');

        Map<String, Object> myData = new Map<String, Object>();
        myData.put('recordId', opp.Id);
        myData.put('billingCheckOutAddress', billingCheckOutAddress);

        Test.startTest();
        checkoutTabController.updateOrderAndAccountBillingAddress(myData);
        Test.stopTest();

        Account accToCheck = [
            SELECT Id, BillingPostalCode, BillingCity, BillingState, BillingStateCode, BillingStreet, BillingCountry
            FROM Account
            WHERE Id = :acc.Id
        ];
        Order ordToCheck = [
            SELECT Id, BillingPostalCode, BillingCity, BillingState, BillingStateCode, BillingStreet, BillingCountry
            FROM Order
            WHERE Id = :ord.Id
        ];

        System.assert.areEqual(
            billingCheckOutAddress.get('billingZip'),
            accToCheck.BillingPostalCode,
            'Code does not match'
        );
        System.assert.areEqual(
            billingCheckOutAddress.get('billingZip'),
            ordToCheck.BillingPostalCode,
            'Code does not match'
        );
    }
}
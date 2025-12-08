@isTest
private class POECCEncryptionServiceTest {
    @isTest
    static void testGetOpportunityProgram() {
        Opportunity opp = new Opportunity(
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
            POE_Program__c = 'Earthlink'
        );
        insert opp;

        POECCEncryptionService.ResponseWrapper result = POECCEncryptionService.getOpportunityProgram(
            new Map<String, Object>{ 'contextId' => opp.Id }
        );

        Assert.areEqual('Earthlink', (String) result.result.get('program'), 'Program retrieved');
    }

    @isTest
    static void testEncryptAndSaveCreditCardData() {
        Opportunity opp = new Opportunity(
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
            POE_Program__c = 'Earthlink'
        );
        insert opp;
        String unencryptedTestCCData = '{"creditCardData":{"useSameCardAsAutoPay":false,"hasAutoPay":false,"upFront":{"ccNumber":"5555555555554444","firstName":"Test","lastName":"Name","ccMonth":12,"ccYear":26,"ccv":542,"cardholderName":"Test Name","zipCode":54323,"type":"Visa"},"autoPay":{}}}';
        Map<String, Object> creditCardDataMap = (Map<String, Object>) JSON.deserializeUntyped(unencryptedTestCCData);
        creditCardDataMap.put('opportunityId', opp.Id);
        test.startTest();
        POECCEncryptionService.ResponseWrapper result = POECCEncryptionService.encryptAndSaveCreditCardData(
            creditCardDataMap
        );
        test.stopTest();
        Assert.areEqual(true, result.result.get('success'), 'Successfully encrypted data');
    }

    @isTest
    static void testDecryptCreditCardData() {
        Opportunity opp = new Opportunity(
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
            POE_Program__c = 'Earthlink'
        );
        insert opp;
        String unencryptedTestCCData = '{"creditCardData":{"useSameCardAsAutoPay":false,"hasAutoPay":false,"upFront":{"ccNumber":"5555555555554444","firstName":"Test","lastName":"Name","ccMonth":12,"ccYear":26,"ccv":542,"cardholderName":"Test Name","zipCode":54323,"type":"Visa"},"autoPay":{}}}';
        Map<String, Object> creditCardDataMap = (Map<String, Object>) JSON.deserializeUntyped(unencryptedTestCCData);
        creditCardDataMap.put('opportunityId', opp.Id);
        POECCEncryptionService.ResponseWrapper encryptResult = POECCEncryptionService.encryptAndSaveCreditCardData(
            creditCardDataMap
        );

        String oppId = opp.Id;
        test.startTest();
        Map<String, Object> result = POECCEncryptionService.decryptCreditCardData(oppId);
        Map<String, Object> upFrontData = (Map<String, Object>) result.get('upFront');
        test.stopTest();
        Assert.isFalse(upFrontData.isEmpty(), 'CC Data is not empty');
        Assert.areEqual('5555555555554444', (String) upFrontData.get('ccNumber'), 'Expected CC number');
    }

    @isTest
    static void testEncryptAndSaveCreditCheckData() {
        Opportunity opp = new Opportunity(
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
            POE_Program__c = 'Earthlink'
        );
        insert opp;
        String unencryptedTestCCData = '{"sensitiveData":{"ccDob":"1991-09-20","ccSSN":"123456789","ccDlExpirationDate":"","ccDlState":"","ccDriversLicenseNumber":""}}';
        Map<String, Object> creditCheckDataMap = (Map<String, Object>) JSON.deserializeUntyped(unencryptedTestCCData);
        creditCheckDataMap.put('opportunityId', opp.Id);
        test.startTest();
        POECCEncryptionService.ResponseWrapper result = POECCEncryptionService.encryptAndSaveCreditCheckData(
            creditCheckDataMap
        );
        test.stopTest();
        Assert.areEqual(true, result.result.get('success'), 'Successfully encrypted data');
    }

    @isTest
    static void testDecryptCreditCheckData() {
        Opportunity opp = new Opportunity(
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
            POE_Program__c = 'Earthlink'
        );
        insert opp;
        String unencryptedTestCCData = '{"sensitiveData":{"ccDob":"1991-09-20","ccSSN":"123456789","ccDlExpirationDate":"","ccDlState":"","ccDriversLicenseNumber":""}}';
        Map<String, Object> creditCheckDataMap = (Map<String, Object>) JSON.deserializeUntyped(unencryptedTestCCData);
        creditCheckDataMap.put('opportunityId', opp.Id);
        POECCEncryptionService.ResponseWrapper encryptResult = POECCEncryptionService.encryptAndSaveCreditCheckData(
            creditCheckDataMap
        );

        String oppId = opp.Id;
        test.startTest();
        Map<String, Object> result = POECCEncryptionService.decryptCreditCheckData(oppId);
        test.stopTest();
        Assert.isFalse(result.isEmpty(), 'CreditCheck Data is not empty');
        Assert.areEqual('123456789', (String) result.get('ccSSN'), 'Expected CC number');
    }
}
@isTest
public with sharing class POE_TermsAndConditionsControllerTest {

    private static final String TEST_TERMS_AND_CONDITIONS = 'Terms Test';
    
    @TestSetup
    static void setup() {
        Opportunity opp = new Opportunity(
            Name = 'test opp', 
            StageName = 'Presentation', 
            CloseDate = Date.today(),
            POE_Cart_Terms_And_Conditions__c = JSON.serialize(TEST_TERMS_AND_CONDITIONS)
        );
        insert opp;

        Chuzo_Settings__c settings = new Chuzo_Settings__c(
            Chuzo_Terms_Public_Page_Path__c = 'test'
        );
        insert settings;
    }

    @isTest
    static void confirmTermsAgreementTest() {
        Opportunity opp = [
            SELECT Id
            FROM Opportunity
            LIMIT 1
        ];

        Test.startTest();
        POE_TermsAndConditionsController.confirmTermsAgreement(opp.Id);
        Test.stopTest();

        Opportunity updatedOpp = [
            SELECT POE_Terms_and_Conditions_Accepted__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];
        Assert.isTrue(
            updatedOpp.POE_Terms_and_Conditions_Accepted__c, 
            'The Terms and Conditions Accepted checkbox in the Opportunity was not checked.'
        );
    }

    @isTest
    static void getTermsAndConditionsTest() {
        Opportunity opp = [
            SELECT Id
            FROM Opportunity
            LIMIT 1
        ];

        Test.startTest();
        POE_TermsAndConditionsController.ResponseWrapper response;
        response = POE_TermsAndConditionsController.getTermsAndConditions(opp.Id);
        Test.stopTest();

        String responseTerms = (String) response.result.get('terms');
        System.debug(responseTerms);
        Assert.areEqual(
            TEST_TERMS_AND_CONDITIONS, responseTerms, 
            'The terms and conditions included in the response are not correct.'
        );
    }

    @isTest
    static void saveTermsAndConditionsTest() {
        Opportunity opp = [
            SELECT Id
            FROM Opportunity
            LIMIT 1
        ];
        String updatedTerms = TEST_TERMS_AND_CONDITIONS.substring(5);

        Test.startTest();
        POE_TermsAndConditionsController.saveTermsAndConditions(opp.Id, JSON.serialize(updatedTerms));
        Test.stopTest();

        Opportunity updatedOpp = [
            SELECT Id, POE_Terms_and_Conditions_Accepted__c, POE_Cart_Terms_And_Conditions__c
            FROM Opportunity
            LIMIT 1
        ];
        Assert.areEqual(
            updatedTerms, 
            (String) JSON.deserializeUntyped(updatedOpp.POE_Cart_Terms_And_Conditions__c),
            'The Cart Terms and Conditions field in the Opportunity does not match the input.'
        );
        Assert.isFalse(
            updatedOpp.POE_Terms_and_Conditions_Accepted__c, 
            'The Terms and Conditions Accepted checkbox in the Opportunity was checked.'
        );
    }

    @isTest
    static void sendTermsAndConditionSMSTest() {
        Test.setMock(HttpCalloutMock.class, new POESMSHttpCalloutMock());
        Test.startTest();
        POE_TermsAndConditionsController.ResponseWrapper response;
        response = POE_TermsAndConditionsController.sendTermsAndConditionSMS(
            new Map<String, Object> {
                'clientPhone' => '111111111',
                'body' => 'Test'
            }
        );
        Test.stopTest();

        Assert.isTrue(
            (Boolean) response.result.get('success'), 
            'The result was not successful when expected.'
        );
    }

    @isTest
    static void sendTermsAndConditionEmail() {
        String testEmail = 'test@example.com';
        String testBody = 'https://www.test.com';

        Test.startTest();
        POE_TermsAndConditionsController.ResponseWrapper response;
        response = POE_TermsAndConditionsController.sendTermsAndConditionEmail(
            new Map<String, Object>{ 
                'email' => testEmail, 
                'body' => testBody 
            }
        );
        Integer emailInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        Assert.areEqual(
            1, emailInvocations,
            'No email was sent or email invocations were not updated as expected.'
        );
        Assert.isTrue(
            (Boolean) response.result.get('success'),
            'The response was not successful when the email was sent.'
        );
    }

    @isTest
    static void getTermsAgreementTest() {
        Opportunity notAgreedOpp = [
            SELECT Id, POE_Terms_and_Conditions_Accepted__c
            FROM Opportunity
            LIMIT 1
        ];

        Opportunity agreedOpp = new Opportunity(
            Name = 'test opp', 
            StageName = 'Presentation', 
            CloseDate = Date.today(),
            POE_Terms_and_Conditions_Accepted__c = true
        );
        insert agreedOpp;

        Test.startTest();
        POE_TermsAndConditionsController.ResponseWrapper notAgreedRes;
        notAgreedRes = POE_TermsAndConditionsController.getTermsAgreement(notAgreedOpp.Id);
        POE_TermsAndConditionsController.ResponseWrapper agreedRes;
        agreedRes = POE_TermsAndConditionsController.getTermsAgreement(agreedOpp.Id);
        Test.stopTest();

        Assert.areEqual(
            notAgreedOpp.POE_Terms_and_Conditions_Accepted__c, 
            (Boolean) notAgreedRes.result.get('termsAgreed'),
            'The terms agreement in the response did not match the Terms and Conditions Accepted checkbox in the Opportunity.'
        );
        Assert.areEqual(
            agreedOpp.POE_Terms_and_Conditions_Accepted__c, 
            (Boolean) agreedRes.result.get('termsAgreed'),
            'The terms agreement in the response did not match the Terms and Conditions Accepted checkbox in the Opportunity.'
        );
    }

    @isTest
    static void getTermsAndConditionsPathTest() {
        String oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        String termsPath = Chuzo_Settings__c.getOrgDefaults().Chuzo_Terms_Public_Page_Path__c;
        Test.startTest();
        POE_TermsAndConditionsController.ResponseWrapper response;
        response = POE_TermsAndConditionsController.getTermsAndConditionsPath(oppId);
        Test.stopTest();

        String responsePath = (String) response.result.get('termsAndConditionsPath');
        Assert.isTrue(
            responsePath.contains(termsPath),
            'The path included in the response does not match the custom setting.'
        );
    }
}
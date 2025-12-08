@isTest
public class POE_PublicRecordAccessUtilityTest {
    
    @TestSetup
    static void setup() {
        Opportunity opp = new Opportunity(
            Name = 'test opp', 
            StageName = 'Presentation', 
            CloseDate = Date.today()
        );
        insert opp;
    }

    @isTest
    static void encryptRecordIdTest() {
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        Test.startTest();
        String encryptedRecordId = POE_PublicRecordAccessUtility.encryptRecordId(oppId);
        Test.stopTest();

        Assert.areNotEqual(oppId, encryptedRecordId, 'The encoded record Id is equal to the original Id');
    }

    @isTest
    static void decryptRecordIdTest() {
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        Test.startTest();
        String encryptedRecordId = POE_PublicRecordAccessUtility.encryptRecordId(oppId);
        String decryptedRecordId = POE_PublicRecordAccessUtility.decryptRecordId(encryptedRecordId);
        Test.stopTest();

        Assert.areEqual(oppId, decryptedRecordId, 'The decoded record Id did not match the original Id.');
    }

    @isTest
    static void isEncryptedIdTest() {
        String oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        String encryptedRecordId = POE_PublicRecordAccessUtility.encryptRecordId(oppId);

        Test.startTest();
        Boolean isEncryptedId = POE_PublicRecordAccessUtility.isEncryptedId(encryptedRecordId);
        Test.stopTest();

        Assert.isTrue(isEncryptedId, 'The encrypted Id was not identified correctly.');
    }
}
@isTest
public with sharing class POE_CreateNewFollowUpTaskTest {
    @TestSetup
    static void makeData() {
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;

        Opportunity opp = new Opportunity();
        opp.CloseDate = System.today();
        opp.Name = 'Test Opportunity';
        opp.AccountId = acc.Id;
        opp.StageName = 'Opportunity';
        opp.Maps_PostalCode__c = '72212';
        insert opp;
    }
    @isTest
    private static void testInitialSave() {
        List<Opportunity> opps = [SELECT Id FROM Opportunity LIMIT 1];
        String oppId = opps[0].Id;
        Date d = Date.today();
        DateTime dt = DateTime.now();
        Test.startTest();
        Boolean saveSuccessful = POE_CreateNewFollowUpTask.createNewTask(oppId, 'test', dt, d, 'test');
        Test.stopTest();
        System.assertEquals(true, saveSuccessful, 'Task saved successfully');
    }
    @isTest
    private static void testInitialSaveFail() {
        List<Opportunity> opps = [SELECT Id FROM Opportunity LIMIT 1];
        String oppId = opps[0].Id;
        Date d = Date.today();
        DateTime dt = DateTime.now();
        Test.startTest();
        Boolean saveSuccessful = POE_CreateNewFollowUpTask.createNewTask(
            oppId,
            'test',
            dt,
            d,
            '===================================================================================================Some string which is longer than 255 characters===================================================================================================================================================================================================================Some string which is longer than 255 characters===================================================================================================================================================================================================================Some string which is longer than 255 characters================================================================================================================'
        );
        Test.stopTest();
        System.assertEquals(false, saveSuccessful, 'Task failed to be saved');
    }
}
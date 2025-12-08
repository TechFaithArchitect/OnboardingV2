@isTest
public class FSL_ShiftsDeletionBatchTest {
    public static final Integer daysBeforeDeletingShifts = 10;

    @testSetup
    static void setupData() {
        FSL_Settings__c settings = new FSL_Settings__c(Days_Before_Deleting_Shifts__c = daysBeforeDeletingShifts);
        insert settings;

        List<Shift> shifts = new List<Shift>{
            new Shift(StartTime = Date.today().addDays(-2), EndTime = Date.today().addDays(-1)),
            new Shift(StartTime = Date.today().addDays(-5), EndTime = Date.today().addDays(-4)),
            new Shift(StartTime = Date.today().addDays(-8), EndTime = Date.today().addDays(-7)),
            new Shift(StartTime = Date.today().addDays(-15), EndTime = Date.today().addDays(-14)),
            new Shift(StartTime = Date.today().addDays(-20), EndTime = Date.today().addDays(-19))
        };
        insert shifts;
    }

    @isTest
    static void testBatchWithCustomSettings() {
        Test.startTest();
        Database.executeBatch(new FSL_ShiftsDeletionBatch(), 100);
        Test.stopTest();

        Date cutoffDate = Date.today().addDays(-daysBeforeDeletingShifts);
        List<Shift> remainingShifts = [
            SELECT  Id, StartTime
            FROM    Shift
            WHERE   StartTime > :cutoffDate
        ];

        Assert.areEqual(3, remainingShifts.size(), '3 shift records should remain after the cutoff date.');
    }

    @isTest
    static void testBatchWithDefaultSettings() {
        delete [SELECT Id FROM FSL_Settings__c LIMIT 1];

        Test.startTest();
        Database.executeBatch(new FSL_ShiftsDeletionBatch(), 100);
        Test.stopTest();

        Date cutoffDate = Date.today().addDays(-7);
        List<Shift> remainingShifts = [
            SELECT  Id, StartTime
            FROM    Shift
            WHERE   StartTime > :cutoffDate
        ];

        Assert.areEqual(2, remainingShifts.size(), '2 shift records should remain after the default cutoff date.');
    }

    @isTest
    static void testErrorHandling() {
        FSL_ShiftsDeletionBatch.throwException = true;
        List<Shift> allShifts = [SELECT Id, StartTime, EndTime FROM Shift];

        Test.startTest();
        Database.executeBatch(new FSL_ShiftsDeletionBatch(), 100);
        Test.stopTest();

        List<PV_Error_Log__c> errorLogs = [
            SELECT  Line_Number__c, Message__c, Stack_Trace__c, Type_Name__c, CreatedDate
            FROM    PV_Error_Log__c
            WHERE   Type_Name__c = 'FSL_ShiftsDeletionBatch.execute'
        ];

        Assert.areEqual(1, errorLogs.size(), 'Should have created an error log');
    }
}
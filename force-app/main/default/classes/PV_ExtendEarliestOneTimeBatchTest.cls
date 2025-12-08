@isTest
public class PV_ExtendEarliestOneTimeBatchTest {
    @TestSetup
    static void createTestData() {
        WorkType workType = PV_TestDataFactory.createWorkType('DIRECTV Install',true);
        WorkType workTypeExcluded = PV_TestDataFactory.createWorkType('DIRECTV Install',true);
        workTypeExcluded.Extended_Start_Time_Exclusion__c = true;
        update workTypeExcluded;

        WorkOrder workOrder = new WorkOrder();
        workOrder.WorkTypeId = workType.Id;
        workOrder.Vendor__c = 'T-Mobile';
        insert workOrder;
    }
    
    @isTest
    static void executeTest() {
        Test.startTest();
        WorkType workTypeExcluded = [SELECT Id FROM WorkType WHERE Extended_Start_Time_Exclusion__c = true];
        WorkOrder workOrder = new WorkOrder();
        workOrder.WorkTypeId = workTypeExcluded.Id;
        workOrder.Vendor__c = 'T-Mobile';
        insert workOrder;

        Id batchJobId = Database.executeBatch(new PV_ExtendEarliestStartTimeOneTimeBatch(), 200);
        Test.stopTest();
    }

    @isTest
    static void executeScheduleTest() {
        Test.startTest();
        PV_ExtendEarliestStartTimeOneTimeBatch scheduleObj = new PV_ExtendEarliestStartTimeOneTimeBatch();
        String sch = '0 30 23 * * ?';
        System.schedule('Test schedule', sch, scheduleObj);
        Test.stopTest();
    }
}
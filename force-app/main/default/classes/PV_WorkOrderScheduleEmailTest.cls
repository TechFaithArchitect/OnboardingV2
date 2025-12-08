@isTest
public class PV_WorkOrderScheduleEmailTest {
    @testSetup
    static void setupMethod() {
        String firstName = String.valueOf(Math.round((Math.random() * (9000) + 1000)));
        String lastName = String.valueOf(Math.round((Math.random() * (9000) + 1000)));
        //Create WorkType, Account, Contact
        WorkType wt = PV_TestDataFactory.createWorkType('T-Mobile Commercial Service Call - 12 Hour', true);
        Account acc = PV_TestDataFactory.createAccount('Test Account', true);
        Contact cont = PV_TestDataFactory.createContact(firstName, lastName, true, acc);

        //Create WorkOrder
        WorkOrder wo = new WorkOrder();
        wo.WorkTypeId = wt.Id;
        wo.Vendor__c = 'T-Mobile';
        wo.Sales_Rep_Email__c = 'test@yopmail.com';
        wo.SIM_Email__c = 'test@yopmail.com';
        wo.ContactId = cont.Id;
        insert wo;
    }

    @isTest
    static void testWorkOrderScheduleEmail() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        //Create EmailRequest
        PV_WorkOrderScheduleNotificationEmail.EmailRequest er = new PV_WorkOrderScheduleNotificationEmail.EmailRequest();
        er.workOrderId = wo.id;
        er.body = 'test body';
        er.subject = 'test subject';

        List<PV_WorkOrderScheduleNotificationEmail.EmailRequest> erList = new List<PV_WorkOrderScheduleNotificationEmail.EmailRequest>();
        erList.add(er);

        Test.startTest();
        PV_WorkOrderScheduleNotificationEmail.sendEmailonWorkOrderScheduling(erList);
        Test.stopTest();
    }
}
@isTest
public class PV_AuditServiceTest {

    @testSetup
    static void testData() {
        Test.startTest();
        
        Account acc = PV_TestDataFactory.createAccount('Test Account', true);
        Contact con = PV_TestDataFactory.createContact('Test', 'contact_01',true,acc);
        OperatingHours opHrs = PV_TestDataFactory.createOperatingHours('East - Mon-Fri 8am - 5pm', true);
        ServiceTerritory pst = PV_TestDataFactory.createParentServiceTerritory(true, 'ST-01',opHrs);
        ServiceTerritory childServiceTerritory = PV_TestDataFactory.createServiceTerritoryForAccount(true, acc, pst);
        User user = PV_TestDataFactory.createTechnicianUser(true,con);

        System.runAs(user) {
            PV_TestDataFactory.assignPermissionSetGroupToUser(true, user, 'FSL_Technician');
        }

        WorkType wt = PV_TestDataFactory.createWorkType('DIRECTV Commercial Install',true);
        WorkOrder wo = PV_TestDataFactory.createWorkOrder(user,wt,true);
        
        // List<ServiceAppointment> saList = new List<ServiceAppointment>();
        
        // ServiceAppointment sa = new ServiceAppointment();
        // sa.ParentRecordId = wo.Id;
        // sa.FSSK__FSK_Work_Order__c = wo.Id;sa.ServiceTerritoryId = pst.Id;
        // sa.WorkTypeId = wt.Id;
        // saList.add(sa);
        
        // sa.EarliestStartTime = system.now();
        // sa.DueDate = System.today().adddays(3);
        // insert saList;
        
        Audit_Question__c audQuestion = new Audit_Question__c();
        audQuestion.Type__c = 'Dropdown';
        audQuestion.is_active__c = true;
        audQuestion.Header__c = 'Question 1';
        audQuestion.Question__c = 'Audit type';
        audQuestion.Options__c = 'New,Existing';
        audQuestion.Order__c = 1;
        insert audQuestion;

        Test.stopTest();
    }
    
    @isTest
    static void testgetCompletedAudit() {
        Test.startTest();
        WorkOrder wo = [select id from WorkOrder limit 1];
        PV_AuditService.getCompletedAudit(wo.id);
        Test.stopTest();
    }
    
    @isTest
    static void testfetchAuditQuestions() {
        Test.startTest();    
        WorkOrder workOrder = [SELECT Id, WorkTypeId FROM WorkOrder LIMIT 1];
        PV_AuditService.fetchAuditQuestions(workOrder.WorkTypeId);
        Test.stopTest();
    }
    
    @isTest
    static void testfetchRelatedAudit() {
        Test.startTest();
        WorkOrder wo = [select id from WorkOrder limit 1];
        
        Audit__c au = new Audit__c();
        au.Work_Order__c=wo.id;
        insert au;
        PV_AuditService.fetchRelatedAudit(au.id);
        Test.stopTest();
    }
    
    @isTest
    static void testinsertAudit() {
        Test.startTest();
        WorkOrder wo = [select id from WorkOrder limit 1];
        
        PV_AuditService.insertAudit(wo.id);
        PV_AuditService.insertAudit('sdsdadewderdere');
        Test.stopTest();
    }
    
    @isTest
    static void testhandleAudit() {
        Test.startTest();
        Audit_Question__c question = [SELECT Id from Audit_Question__c limit 1];
        List<Audit_Response__c> auditResponses = new List<Audit_Response__c>();
        Audit_Response__c ar = new Audit_Response__c();
        ar.Response__c = 'Pass';
        ar.Audit_Question__c = question.id;
        auditResponses.add(ar);
        PV_AuditService.handleAudit(auditResponses,false);
        Test.stopTest();
    }

    @isTest
    static void testGetCompletedAuditError() {
        Test.startTest();
        PV_AuditService.throwException = true;
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        
        try {
            PV_AuditService.getCompletedAudit(wo.id);
            System.assert(false, 'Should have thrown an exception');
        } catch(Exception e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Exception message was wrong');
        }
        Test.stopTest();
    }

    @isTest
    static void testHandleAuditError() {
        Test.startTest();
        PV_AuditService.throwException = true;

        Audit_Question__c question = [SELECT Id FROM Audit_Question__c LIMIT 1];
        List<Audit_Response__c> auditResponses = new List<Audit_Response__c>();
        Audit_Response__c ar = new Audit_Response__c();
        ar.Response__c = 'Pass';
        ar.Audit_Question__c = question.id;
        auditResponses.add(ar);

        try {
            PV_AuditService.handleAudit(auditResponses,false);
            System.assert(false, 'Should have thrown an exception');
        } catch(Exception e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Exception message was wrong');
        }
        Test.stopTest();
    }

    @isTest
    static void getAuditConfigurationTest() {
        Test.startTest();
        
        WorkOrder workOrder = [SELECT Id FROM WorkOrder LIMIT 1];
        PV_AuditService.insertAudit(workOrder.Id);
        PV_AuditService.getAuditConfiguration(workOrder.Id);

        Audit_Question__c question = [SELECT Id from Audit_Question__c LIMIT 1];
        Audit__c audit = [SELECT Id FROM Audit__c LIMIT 1];

        List<Audit_Response__c> auditResponses = new List<Audit_Response__c>();
        Audit_Response__c response = new Audit_Response__c();
        response.Audit__c = audit.Id;
        response.Response__c = 'Pass';
        response.Audit_Question__c = question.id;
        auditResponses.add(response);
        PV_AuditService.handleAudit(auditResponses,false);

        PV_AuditService.getAuditConfiguration(workOrder.Id);
        Test.stopTest();
    }
}
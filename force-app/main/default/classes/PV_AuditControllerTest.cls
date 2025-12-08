@isTest
public class PV_AuditControllerTest {
    
    @isTest
    static void getAuditTest(){
       Test.startTest();
       WorkType wt= PV_TestDataFactory.createWorkType('TestWorkOrder',true);
       WorkOrder wo =PV_TestDataFactory.createWorkOrder([select id from User where id=:UserInfo.getUserId()],wt,true);
       PV_AuditController.Payload py=PV_AuditController.getAudit(wo.id);
       Boolean access=PV_AuditController.getCompletedAudit(wo.id);
       Test.StopTest();
    }
    
    @isTest
    static void updateAuditTest(){
        
       Test.startTest();         
       WorkType wt= PV_TestDataFactory.createWorkType('TestWorkOrder',true);
       WorkOrder wo =PV_TestDataFactory.createWorkOrder([select id from User where id=:UserInfo.getUserId()],wt,true);
       Audit__c au=new Audit__c();
       au.Work_Order__c=wo.id;
       insert au;
       PV_AuditController.updateAudit(au);
       Test.StopTest(); 
        
    }
    
     @isTest
    static void auditOptionsTest(){      
          List<PV_AuditController.PicklistOptions> auditOptions= PV_AuditController.auditOptions();
    }
    
    
     @isTest
    static void qualityOptionsTest(){
          List<PV_AuditController.PicklistOptions> auditOptions= PV_AuditController.qualityOptions();
    }
    @isTest
    static void auditResultTest(){
          List<PV_AuditController.PicklistOptions> auditOptions= PV_AuditController.auditResult();
    }
    
    

}
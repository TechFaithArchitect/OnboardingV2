@isTest
public class PV_SharinPixImageToFileControllerTest {
    
    @TestSetup
    static void makeTestData() {
        Id recordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        Account pAcc = new Account();
        pAcc.FirstName = 'Test';
        pAcc.LastName = 'Person Account123';
        pAcc.RecordTypeID = recordTypeId;
        insert pAcc;
        
        Account acc= PV_TestDataFactory.createAccount('Test Account', true);        
        contact con = PV_TestDataFactory.createContact('Test', 'contact_01',true,acc);
        User usr = PV_TestDataFactory.createTechnicianUser(true,con);
        WorkType wt = PV_TestDataFactory.createWorkType('ImpSkill',true);
        WorkOrder wo = PV_TestDataFactory.createWorkOrder(usr,wt,true);
        
        wo.AccountId = pAcc.Id;
        Update wo;
        
        List<sharinpix__SharinPixImage__c> siList = new List<sharinpix__SharinPixImage__c>();
        
        sharinpix__SharinPixImage__c si1 = new sharinpix__SharinPixImage__c();
        si1.sharinpix__ImageURLFull__c = 'https://p.sharinpix.com/3/52676fc/YXBwLnNoYXJpbnBpeC5jb20vaW1hZ2VzL2Q0MWVmYmYwLTM1YmUtNGQ2My1iN2RmLWQzMWU2OTk1NjliOS90aHVtYm5haWxzL2Z1bGwtMTViZGU5NDY5OGQuanBn/bts.png';
        si1.Work_Order_Image__c = wo.Id;
        si1.sharinpix__Processed__c = true;
        //si1.sharinpix__DisplayTags__c = 'Pole_Mount';
        si1.Limit_to_size__c = 'https://p.sharinpix.com/3/fd11a89/YXBwLnNoYXJpbnBpeC5jb20vaW1hZ2VfZXh0ZXJuYWxfdXJscy83NGFjOWJkOS1iY2MyLTRjNmQtODhhZi1hYzc1ZWNhMjg1YjQ/74ac9bd9-bcc2-4c6d-88af-ac75eca285b4.jpg';
        siList.add(si1);        
        insert siList;
        
    }    
    
    @isTest
    static void getImageFromUrlTest(){
        
        sharinpix__SharinPixImage__c siId = [SElECT Id, sharinpix__ImageURLFull__c,Work_Order_Image__c,sharinpix__DisplayTags__c,sharinpix__Processed__c from sharinpix__SharinPixImage__c WHERE sharinpix__ImageURLFull__c = 'https://p.sharinpix.com/3/52676fc/YXBwLnNoYXJpbnBpeC5jb20vaW1hZ2VzL2Q0MWVmYmYwLTM1YmUtNGQ2My1iN2RmLWQzMWU2OTk1NjliOS90aHVtYm5haWxzL2Z1bGwtMTViZGU5NDY5OGQuanBn/bts.png'];
        List<Id> sids = new List<Id>();
        List<PV_SharinPixImageToFileController.InputVariable> ipList = new List<PV_SharinPixImageToFileController.InputVariable>();
        PV_SharinPixImageToFileController.InputVariable ip = new PV_SharinPixImageToFileController.InputVariable ();
        ip.SharinPixImageId = siId.Id;
        ipList.add(ip);
        sids.add(siId.Id);
        
        Test.setMock(HttpCalloutMock.class, new PV_API_ResponseMock());
        PV_SharinPixImageToFileController.getUrlFromRecord(ipList);
    }
    
}
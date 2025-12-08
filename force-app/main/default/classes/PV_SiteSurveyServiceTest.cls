@isTest
public class PV_SiteSurveyServiceTest {
    @testSetup
    static void testData() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Account acc = PV_TestDataFactory.createAccount('Test Account', true);
            contact con = PV_TestDataFactory.createContact('Test', 'contact_01', true, acc);
            OperatingHours opHrs = PV_TestDataFactory.createOperatingHours('East - Mon-Fri 8am - 5pm', true);
            ServiceTerritory pst = PV_TestDataFactory.createParentServiceTerritory(true, 'ST-01', opHrs);
            ServiceTerritory childServiceTerritory = PV_TestDataFactory.createServiceTerritoryForAccount(true, acc, pst);
            User usr = PV_TestDataFactory.createTechnicianUser(true, con);
            PV_TestDataFactory.assignPermissionSetGroupToUser(true, usr, 'FSL_Technician');
            ServiceResource serviceRes = PV_TestDataFactory.createServiceResource(true, acc, con, usr);
            ServiceTerritoryMember stm = PV_TestDataFactory.createServiceTerritoryMember(true, serviceRes, childServiceTerritory, 'P');
            WorkType wt = PV_TestDataFactory.createWorkType('ImpSkill', false);
            wt.Site_Survey_Allowed_For_Closeout__c = true;
            insert wt;
            WorkOrder wo = PV_TestDataFactory.createWorkOrder(usr, wt, true);
            
            ServiceAppointment sa = new ServiceAppointment();
            sa.ParentRecordId = wo.Id;
            sa.FSSK__FSK_Work_Order__c = wo.Id;
            sa.ServiceTerritoryId = pst.Id;
            sa.WorkTypeId = wt.Id;
            insert sa;
            
            Site_Survey_Question__c siteQuestion = new Site_Survey_Question__c();
            siteQuestion.Type__c = 'Dropdown';
            siteQuestion.is_active__c = true;
            siteQuestion.Header__c = 'Question 1';
            siteQuestion.Question__c = 'Mount Conditions';
            siteQuestion.Options__c = 'New,Existing';
            siteQuestion.Order__c = 1;
            siteQuestion.Vendor_Type__c = 'T-Mobile';
            insert siteQuestion;
        }
    }
    
    @isTest
    static void testMethod1() {
        List<Site_Survey_Question__c> siteQuestion = [SELECT Id, Name, Type__c, Vendor_Type__c, Work_Type__c FROM Site_Survey_Question__c];
        List<ServiceAppointment> sa = [SELECT Id FROM ServiceAppointment];
        List<Site_Survey_Response__c> ssr = new List<Site_Survey_Response__c>();
        Site_Survey_Response__c ssResponse = new Site_Survey_Response__c();
        ssResponse.question__c = siteQuestion[0].Id;
        ssResponse.response__c = 'test Response';
        ssResponse.Service_Appointment__c = sa[0].Id;
        ssr.add(ssResponse);
        Test.startTest();
        PV_SiteSurveyService.fetchSurveyQuestions(siteQuestion[0].Vendor_Type__c, null);
        PV_SiteSurveyService.createSurveyResponses(ssr);
        PV_SiteSurveyService.getVendorType(sa[0].Id);
        PV_SiteSurveyService.getResponse(sa[0].Id);
        PV_SiteSurveyService.getSurveyResponse(sa[0].Id, siteQuestion[0].Vendor_Type__c, null);
        Test.stopTest(); 
    }
    
    @isTest
    static void testException(){
        List<Site_Survey_Question__c> siteQuestion = [SELECT Id, Name, Type__c FROM Site_Survey_Question__c];
        List<Site_Survey_Response__c> ssr = new List<Site_Survey_Response__c>();
        Site_Survey_Response__c ssResponse = new Site_Survey_Response__c();
        ssResponse.response__c = 'ssr';
        ssr.add(ssResponse);
        Test.startTest();
            try {
                PV_SiteSurveyService.createSurveyResponses(ssr);
            } catch(exception ex) {
                Assert.areEqual('Script-thrown exception', ex.getMessage());
            }
        Test.stopTest();
    }
}
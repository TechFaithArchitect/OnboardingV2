@isTest
public class PV_WorkTypeSRCountHandlerTest {
    public static final String TEST_ACCOUNT_1_NAME = 'Test Account 1';
    public static final String TEST_ACCOUNT_2_NAME = 'Test Account 2';
    public static final String SERVICE_TERRITORY_FLOW_API_NAME = 'ServiceTerritory_Record_Flow_Territory_Inactivation';

    @TestSetup
    static void makeTestData() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Account acc1 = PV_TestDataFactory.createAccount(TEST_ACCOUNT_1_NAME, true);
            Account acc2 = PV_TestDataFactory.createAccount(TEST_ACCOUNT_2_NAME, true);
            contact con = PV_TestDataFactory.createContact('Test', 'contact_01', true, acc1);
            User usr = PV_TestDataFactory.createTechnicianUser(true, con);
            OperatingHours opHrs = PV_TestDataFactory.createOperatingHours('East - Mon-Fri 8am - 5pm', true);
            ServiceTerritory pst1 = PV_TestDataFactory.createParentServiceTerritory(true, 'ST-0001',opHrs);
            ServiceTerritory cst1 = PV_TestDataFactory.createServiceTerritoryForAccount(true, acc1, pst1);
            ServiceTerritory cst2 = PV_TestDataFactory.createServiceTerritoryForAccount(true, acc2, pst1);

            WorkType wt1 = PV_TestDataFactory.createWorkType('T-Mobile Site Survey',true);
            WorkType wt2 = PV_TestDataFactory.createWorkType('T-Mobile Home Office Install - Cellular Gateway Only',true);
            WorkType wt3 = PV_TestDataFactory.createWorkType('T-Mobile Commercial Install - w/ External Antenna',true);
            
            Work_Type_SR_Count__c wsr1 = new Work_Type_SR_Count__c();
            wsr1.No_of_skilled_resources__c = 1;
            wsr1.Service_Resource_Percentage__c = 50;
            wsr1.Service_Territory__c = cst1.Id;
            wsr1.Work_Type__c = wt1.Id;
            insert wsr1;

            Work_Type_SR_Count__c wsr2 = new Work_Type_SR_Count__c();
            wsr2.No_of_skilled_resources__c = 1;
            wsr2.Service_Resource_Percentage__c = 50;
            wsr2.Service_Territory__c = cst1.Id;
            wsr2.Work_Type__c = wt2.Id;
            insert wsr2;

            Work_Type_SR_Count__c wsr3 = new Work_Type_SR_Count__c();
            wsr3.No_of_skilled_resources__c = 1;
            wsr3.Service_Resource_Percentage__c = 50;
            wsr3.Service_Territory__c = cst2.Id;
            wsr3.Work_Type__c = wt1.Id;
            insert wsr3;

            Work_Type_SR_Count__c wsr4 = new Work_Type_SR_Count__c();
            wsr4.No_of_skilled_resources__c = 1;
            wsr4.Service_Resource_Percentage__c = 50;
            wsr4.Service_Territory__c = cst2.Id;
            wsr4.Work_Type__c = wt2.Id;
            insert wsr4;
        }
    }

    @isTest
    static void handleTerritoryInactivationTest() {
        List<Work_Type_SR_Count__c> initialWorkTypeSRCount = [SELECT Id FROM Work_Type_SR_Count__c];
        
        List<Work_Type_SR_Count__c> childTerritory1WorkTypeSRCount = [
            SELECT  Id 
            FROM    Work_Type_SR_Count__c 
            WHERE   Service_Territory__r.Account__r.Name = :TEST_ACCOUNT_1_NAME
        ];

        ServiceTerritory childTerritory1 = [SELECT Id, IsActive FROM ServiceTerritory WHERE Account__r.Name = :TEST_ACCOUNT_1_NAME LIMIT 1];
        childTerritory1.IsActive = false;
        update childTerritory1;

        Integer numberOfRecords = initialWorkTypeSRCount.size() - childTerritory1WorkTypeSRCount.size();
        List<Work_Type_SR_Count__c> finalWorkTypeSRCount = [SELECT Id, Service_Resource_Percentage__c FROM Work_Type_SR_Count__c];

        FlowDefinitionView activeFlow = [SELECT Id, ActiveVersionId FROM FlowDefinitionView WHERE ApiName = :SERVICE_TERRITORY_FLOW_API_NAME LIMIT 1];

        if (activeFlow.ActiveVersionId != null) {
            Assert.areEqual(numberOfRecords, finalWorkTypeSRCount.size(), 'Records have not been deleted correctly');
        }
    }
}
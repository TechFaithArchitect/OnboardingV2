@isTest
public with sharing class ShiftsCreationInAdvanceBatchTest {

    @TestSetup
    static void Setup(){
        Account acc = PV_TestDataFactory.createAccount('Test ABCD', true);
        Contact con = PV_TestDataFactory.createContact('firstName', 'lastName',true,acc);
        User usr = PV_TestDataFactory.createTechnicianUser(true,con);

        System.runAs(usr){
            PV_TestDataFactory.assignPermissionSetGroupToUser(true, usr, 'FSL_Technician');
        }
        
        ServiceResource sr = PV_TestDataFactory.createServiceResource(true,acc,con,usr);
        sr.Manager__c = UserInfo.getUserId();
        update sr;

        OperatingHours opHrs= PV_TestDataFactory.createOperatingHours('East - Mon-Fri 8am - 5pm', true);
        ServiceTerritory pst = PV_TestDataFactory.createParentServiceTerritory(true, 'ST-01',opHrs);
        ServiceTerritory childServiceTerritory = PV_TestDataFactory.createServiceTerritoryForAccount(true, acc, pst);

        ServiceTerritoryMember stm = PV_TestDataFactory.createServiceTerritoryMember(true,sr,childServiceTerritory,'P');

        List<Shift> testShifts = new List<Shift>();
        for(Integer i = 1; i <= 5; i++) {
            //create Shift
            Shift newShift = new Shift(
                StartTime = Date.today().addDays(i),
                EndTime = Date.today().addDays(i+1),
                ServiceResourceId = sr.Id,
                ServiceTerritoryId = childServiceTerritory.Id,
                CurrencyIsoCode = 'USD',
                Status = 'Tentative',
                TimeSlotType = 'Normal');
            testShifts.add(newShift);
        }

        insert testShifts;

        FSL_Settings__c settings = new FSL_Settings__c(
            Shifts_First_Day_of_the_Week__c = 1,
            Shift_Weeks_In_Advance__c = 4
        );
        insert settings;

    }
    

    @isTest
    static void testScheduling() {
        Test.startTest();
        FSL_Settings__c settings = FSL_Settings__c.getOrgDefaults();
        Integer weekStart = Integer.valueOf(settings.Shifts_First_Day_of_the_Week__c) + 1;
        ShiftsCreationInAdvanceBatch batchInstance = new ShiftsCreationInAdvanceBatch();
        String cronExpression = '0 0 2 ? * ' + weekStart + ' *';
        String jobId = System.schedule('ShiftsCreationInAdvanceBatch_Test', cronExpression, batchInstance);
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        Test.stopTest();

        Assert.areEqual(0, ct.TimesTriggered, 'Class was not scheduled.');
        Assert.areEqual(cronExpression, ct.CronExpression, 'Class was not scheduled.');

    }

    @isTest
    static void testBatchExecution() {
        Test.startTest();
        ShiftsCreationInAdvanceBatch batchInstance = new ShiftsCreationInAdvanceBatch();
        Database.executeBatch(batchInstance);
        Test.stopTest();

        List<Shift> result = [SELECT Id, StartTime FROM Shift];
        Assert.isTrue(result.size() > 5, 'The new Shifts were not created correctly');
        
    }
}
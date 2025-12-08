@isTest
public with sharing class PV_ShiftCreationControllerTest {
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
                StartTime = Date.today().addDays(i + 7),
                EndTime = Date.today().addDays(i + 8),
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
    static void getResourceShiftsTest() {
        
        ServiceResource selectedResource = [SELECT Id FROM ServiceResource LIMIT 1];

        Test.startTest();
        List<PV_ShiftCreationController.ShiftWrapper> resultList = PV_ShiftCreationController.getResourceShifts(selectedResource.Id, 'America/Montevideo');
        Test.stopTest();

        //Assert.isTrue(resultList.size() > 0, 'Sifts not queried correctly');

    }

    @isTest
    static void createNewResourceShiftsTest() {
        Shift testShift = new Shift();
        testShift.startTime = Datetime.now().addDays(1);
        testShift.EndTime = Datetime.now().addDays(2);
        testShift.TimeSlotType =  'Normal';
        testShift.ServiceTerritoryId = [Select Id from ServiceTerritory where Name = 'ST-01'].id;

        List<Shift> testShifts = new List<Shift>();
        testShifts.add(testShift);

        ServiceResource selectedResource = [SELECT Id FROM ServiceResource LIMIT 1];

        Test.startTest();
        Boolean result = PV_ShiftCreationController.createNewResourceShifts(selectedResource.Id, testShifts, 'America/Montevideo');
        Test.stopTest();
        List<Shift> resultShifts = [SELECT Id FROM Shift WHERE ServiceResourceId = :selectedResource.Id];

        Assert.areEqual(4, resultShifts.size());
    }

}
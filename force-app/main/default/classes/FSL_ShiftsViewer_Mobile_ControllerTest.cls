@isTest
public with sharing class FSL_ShiftsViewer_Mobile_ControllerTest {
    @testSetup
    static void setup() {
        Account acc = PV_TestDataFactory.createAccount('Test Account', true);
        Contact con = PV_TestDataFactory.createContact('Test', 'Contact_01' + Math.random(), true, acc);
        User usr = PV_TestDataFactory.createTechnicianUser(true, con);
        System.runAs(usr) {
            PV_TestDataFactory.assignPermissionSetGroupToUser(true, usr, 'FSL_Technician');
        }
        ServiceResource sr = PV_TestDataFactory.createServiceResource(true, acc, con, usr);
        OperatingHours opHrs = PV_TestDataFactory.createOperatingHours('Test Hours', true);
        ServiceTerritory st = PV_TestDataFactory.createParentServiceTerritory(true, 'Test Territory', opHrs);
        ServiceTerritoryMember stm = PV_TestDataFactory.createServiceTerritoryMember(true, sr, st, 'P');
        FSL_Settings__c settings = new FSL_Settings__c(
            Shifts_First_Day_of_the_Week__c = 1,
            Shift_Weeks_In_Advance__c = 4
        );
        insert settings;
        Shift shift = new Shift(
            StartTime = DateTime.now().addDays(1),
            EndTime = DateTime.now().addDays(1).addHours(8),
            ServiceResourceId = sr.Id,
            ServiceTerritoryId = st.Id,
            Status = 'Confirmed',
            TimeSlotType = 'Normal'
        );
        insert shift;
    }

    @isTest
    static void testGetMyShifts_CurrentWeek() {
        User usr = [SELECT Id FROM User WHERE FirstName = 'Test_' LIMIT 1];

        List<Fsl_ShiftsViewer_Mobile_Controller.ShiftDisplayWrapper> shifts;
        System.runAs(usr) {
            Test.startTest();
            shifts = Fsl_ShiftsViewer_Mobile_Controller.getMyShifts(true);
            Test.stopTest();
        }

        Assert.areEqual(1, shifts.size(), 'Should return one shift for current week');
    }

    @isTest
    static void testGetMyShifts_NextWeek() {
        User usr = [SELECT Id FROM User WHERE FirstName = 'Test_' LIMIT 1];

        List<Fsl_ShiftsViewer_Mobile_Controller.ShiftDisplayWrapper> shifts;
        System.runAs(usr) {
            Test.startTest();
            shifts = Fsl_ShiftsViewer_Mobile_Controller.getMyShifts(false);
            Test.stopTest();
        }

        Assert.areEqual(0, shifts.size(), 'Should return no shifts for next week');
    }

    @isTest
    static void testGetMyShifts_NoServiceResource() {
        Account acc = PV_TestDataFactory.createAccount('TestNoSR Account', true);
        Contact con = PV_TestDataFactory.createContact('NoSRTest', 'Contact_02' + Math.random(), true, acc);
        User usr = PV_TestDataFactory.createTechnicianUser(false, con);
        usr.FirstName = 'NoSRTest';
        usr.LastName = 'User' + Math.random();
        usr.CommunityNickname = 'NoSRTestUser' + Math.random();
        insert usr;

        List<Fsl_ShiftsViewer_Mobile_Controller.ShiftDisplayWrapper> shifts;
        System.runAs(usr) {
            Test.startTest();
            shifts = Fsl_ShiftsViewer_Mobile_Controller.getMyShifts(true);
            Test.stopTest();
        }

        Assert.areEqual(0, shifts.size(), 'Should return no shifts if no ServiceResource');
    }
}
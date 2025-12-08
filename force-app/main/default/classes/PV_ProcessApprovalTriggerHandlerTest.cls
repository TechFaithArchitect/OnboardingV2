/**
* @description       : Class for Managing Service Resources
* @author            : Impaqtive DevTeam
* @last modified on  : 11-05-2023
* @last modified by  : Impaqtive DevTeam
* Modifications Log
* Ver   Date         Author            	   Modification
* 1.0   11/05/2023   Impaqtive DevTeam     Initial Version
**/

@isTest
public class PV_ProcessApprovalTriggerHandlerTest {
    
    @isTest
    static void ProcessApprovalTriggerTest(){

        Account acc = PV_TestDataFactory.createAccount('Test ABC', true);
        Contact partnerContact = PV_TestDataFactory.createContact('TestFirstName', 'TestLastName', false, acc);
        OperatingHours opHrs = PV_TestDataFactory.createOperatingHours('TestHours', true);
        ServiceTerritory st = PV_TestDataFactory.createParentServiceTerritory(true, 'TestTerritory', opHrs);
        PV_ManageServiceResources.ServiceTerritoryMembership st1 = new PV_ManageServiceResources.ServiceTerritoryMembership();
        st1.StartDate = String.valueOf(Date.today());
        st1.TerritoryId = st.Id;
        st1.TerritoryType = 'Primary';
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartArray();
        gen.writeStartObject();
        gen.writeNumberField('IndexId', 0);
        gen.writeStringField('StartDate', st1.StartDate);
        gen.writeStringField('TerritoryId', st1.TerritoryId);
        gen.writeStringField('TerritoryType', st1.TerritoryType);
        gen.writeEndObject();
        gen.writeEndArray();
        String jsonString = gen.getAsString();

        Process_Approval__c pa = new Process_Approval__c();
        Id rtId = [SELECT Id FROM RecordType WHERE SobjectType = 'Process_Approval__c' AND DeveloperName = 'Service_Resource_Approval' LIMIT 1].Id;
        pa.RecordTypeId = rtId;
        pa.Resource_Type__c = 'Technician';
        pa.Background_Check_Date__c = Date.today();
        pa.Drug_Screen_Date__c = Date.today();
        pa.Service_memberships__c = jsonString;
        pa.Skill__c = 'Basic';  
        pa.Skill_Start_Date__c = Date.today();
        pa.Include_in_Scheduling_Optimization__c = true;
        pa.First_Name__c = 'TestFirstName';
        pa.Last_Name__c = 'TestLastName';
        pa.ID_DirecTV__c = '12345';
        pa.ID_Viasat__c = '67890';
        pa.Account__c = acc.Id;
        pa.Email__c = 'test@example.com';
        pa.Phone__c = '1234567890';
        pa.Time_Zone__c = 'GMT';
        pa.Vendor_Type__c = partnerContact.Vendor_Type__c;
        pa.DIRECTV_Expiration__c = Date.today().addYears(1);
        pa.Viasat_Expiration__c = Date.today().addYears(1);
        insert pa;

        List<Shift> shiftList = new List<Shift>();
        for (Integer i = 0; i < 3; i++) {
            Shift shift = new Shift();
            shift.Process_Approval__c = pa.Id;
            shift.StartTime = DateTime.now().addDays(i);
            shift.EndTime = DateTime.now().addDays(i).addHours(8);
            shift.TimeSlotType = 'Normal';
            shift.ServiceTerritoryId = st.Id;
            shiftList.add(shift);
        }
        insert shiftList;

        pa.Status__c = 'Approved';
        update pa;

        List<Shift> associatedShifts = [SELECT Id, StartTime, EndTime, TimeSlotType, ServiceTerritoryId 
                                        FROM Shift WHERE Process_Approval__c = :pa.Id];
        System.assertEquals(3, associatedShifts.size(), 'Should have 3 Shifts');
    }
    
    @isTest
    public static void processApprovalLocationTest() {

        Account acc = PV_TestDataFactory.createAccount('Test ABCD', true);

        Process_Approval__c pa = new Process_Approval__c();
        Id rtId = [SELECT Id FROM RecordType WHERE SobjectType = 'Process_Approval__c' AND DeveloperName = 'Location_Approval' LIMIT 1].Id;
        pa.RecordTypeId = rtId;
        pa.Account__c = acc.Id;
        pa.Location_Name__c = 'Test Location';
        pa.Location_Type__c = 'Warehouse';
        pa.Inventory_Location__c = true;
        pa.Mobile_Location__c = false;
        insert pa;

        pa.Status__c = 'Approved';
        update pa;

    }
}
@isTest
public class FSL_TypeformTriggerHandlerTest {

    @testSetup
    static void setupTestData() {

        WorkOrder wo = new WorkOrder(
        	Status = 'Unscheduled'
        );
        insert wo;
    
        Typeform_Responses__c response = new Typeform_Responses__c(
            Additional_Phone_Number__c = '1234567890',
            Address__c = '123 Main St',
            Address_Line_2__c = 'Apt 4B',
            Appliance_Scheduled_For_Installation__c = 'Washing Machine',
            Are_water_and_power_fully_functional__c = 'Yes',
            City_Town__c = 'San Francisco',
            Country__c = 'USA',
            CurrencyIsoCode = 'USD',
            Email__c = 'test@example.com',
            First_Name__c = 'John',
            Is_the_installation_area_free__c = 'Yes',
            Last_Name__c = 'Doe',
            Phone_Number__c = '9876543210',
            Response_ID__c = 'RESP-12345',
            State_Region_Province__c = 'CA',
            Work_Order_Id__c = wo.Id, 
            Zip_Post_Code__c = '94105'
        );
        insert response;
    }
    
    @isTest
    static void testAssignWorkOrder() {
   
        Typeform_Responses__c response = [SELECT Id, Work_Order_Id__c, Work_Order__c 
                                          FROM Typeform_Responses__c];

        Test.startTest();
        FSL_TypeformTriggerHandler.assignWorkOrder(new List<Typeform_Responses__c>{response});
        Test.stopTest();

        response = [SELECT Id, Work_Order_Id__c, Work_Order__c 
                    FROM Typeform_Responses__c];

        System.assertEquals(response.Work_Order_Id__c, response.Work_Order__c, 
                            'Work_Order__c should match Work_Order_Id__c after handler execution.');
    }
}
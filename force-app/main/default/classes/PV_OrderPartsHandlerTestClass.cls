@isTest
private class PV_OrderPartsHandlerTestClass {
    @testSetUp static void setup(){
        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        testAccount.Division__c = 'DOM';
        testAccount.Region__c = 'COLR';
        testAccount.Territory__c = 'COLT';
        testAccount.P10_Invoice_Account__c = 'TestAccountDOM';
        insert testAccount;
        
        Account a = [SELECT id, Name ,Division__c FROM Account WHERE Division__c = 'DOM'];
        Order__c testOrder = new Order__c(Account_Name__c = a.Id, 
                                          Mode_of_Delivery__c = 'Ground',
                                          Warehouse__c = 'CA');
        insert testOrder;
        
        Product__c testProduct = new Product__c(Name = 'Test Order',
                                                Minimum_Selling_Price__c = 500, 
                                                List_Price__c = 700);
        insert testProduct;
        
        Product__c p = [SELECT id,Name,Minimum_Selling_Price__c,List_Price__c FROM Product__c WHERE Name = 'Test Order'];
        Order__c o = [SELECT id, Mode_of_Delivery__c,Warehouse__c FROM Order__c WHERE Warehouse__c = 'CA'];
        
        Line_Item__c testLineItem1 = new Line_Item__c(Order__c = o.Id,
                                                      Price__c = 450,
                                                      MSP__c = 500,
                                                      Item__c = p.Id,
                                                      Requested_Quantity__c=1);
        insert testLineItem1;
        Line_Item__c testLineItem2 = new Line_Item__c(Order__c = o.Id,
                                                      Price__c = 400,
                                                      MSP__c = 500,
                                                      Item__c = p.Id,
                                                      Requested_Quantity__c=1);
        insert testLineItem2; 
    }
    private static testMethod void afterDeleteMethod(){
        Line_Item__c l1 = [SELECT id, Order__c,Price__c,Item__c,Requested_Quantity__c FROM Line_Item__c WHERE Price__c = 450];
        delete l1;
    }
}
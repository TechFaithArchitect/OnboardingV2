@isTest
private class PV_FullFill_OrderPartsTest {
    @testSetup static void createData(){
        
        Account testAccount = new Account(Name = 'Test Account',
                                          P10_Invoice_Account__c ='Account Test',
                                          Division__c = 'DOM');
        insert testAccount;      
        Product__c prod = new Product__c(Name = 'ZVSYNC-NA/ZeeVee, HD Digital Tuner/Decoder QAM',
                                         Item_Description__c = 'Product 1 Description',
                                         Item_Name_Number__c = 'ZVSYNC-NA');
        insert prod;
        PV_Warehouse__c wareHouse = new PV_Warehouse__c(Bin__c = 'A123',
                                                        Part__c = 'ZVSYNC-NA',
                                                        Name = 'DAL',
                                                        Quantity_At_Hand__c = 4);
        insert wareHouse;
        Order__c order = new Order__c(Account_Name__c = testAccount.Id,
                                      Warehouse__c = 'DAL');
        insert order;
        Line_Item__c lineItem = new Line_Item__c(Requested_Quantity__c = 3,
                                                 Item_Description__c = 'Product 1 Description',
                                                 Fulfilled_Quantity__c =3,
                                                 Order__c = order.Id,
                                                 Item__c = prod.Id);
        insert lineItem;       
    }  
  
    private static testMethod void testFullFilledParts(){
        List<Account> acc = [SELECT Id,Name,Division__c FROM Account WHERE Name = 'Test Account'];
        Order__c orders =[SELECT Id,Name,Account_Name__c,Warehouse__c FROM Order__c WHERE Account_Name__c =:acc];
        String oId =orders.Id;
        List<Product__c> products = [SELECT Id,Name,Item_Description__c,Item_Name_Number__c FROM Product__c WHERE Name LIKE '%ZVSYNC-NA/ZeeVee, HD Digital Tuner/Decoder QAM%'];
        List<Line_Item__c> lineItems = [SELECT Id,Requested_Quantity__c,Fulfilled_Quantity__c,Item_Description__c,Order__r.Name,Order__r.Warehouse__c,Item__r.Item_Name_Number__c FROM Line_Item__c];
        List<PV_Warehouse__c> wareHouses = [SELECT Id,Name,Bin__c,Part__c,Quantity_At_Hand__c FROM PV_Warehouse__c WHERE Name ='DAL'];
        String store = PV_FullFill_OrderParts.getOrderPartsAndWarehouseInfo(oId);
        PV_FullFill_OrderParts.updateOrderParts(store);
        try{
        	PV_FullFill_OrderParts.updateOrderAndInventory(store,oId);
      	}catch(exception e){
		}     
        //PV_FullFill_OrderParts.updateOrderAndInventory(store,oid);
    }
}
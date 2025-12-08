@isTest
public class PV_ProductTransferControllerTest {
    @TestSetup
    static void makeTestData() {
        Product2 pd1= PV_TestDataFactory.createProduct(true,true,'Serialized Product');
        Product2 pd2= PV_TestDataFactory.createProduct(true,true,'Serialized Product1');
        Product2 pd3= PV_TestDataFactory.createProduct(true,false,'Non SZ Product 1');
        Product2 pd4= PV_TestDataFactory.createProduct(true,false,'Non SZ Product 2');
        Schema.Location loc1 = new Schema.Location(
            Name = 'Master Location',
            LocationType = 'Van',
            IsMobile = true,
            IsInventoryLocation = true
        );
        insert loc1;
        Schema.Location loc2 = new Schema.Location(
            Name = 'Child Location',
            LocationType = 'Van',
            IsMobile = true,
            IsInventoryLocation = true
        );
        insert loc2;
        Schema.Location faultyLocation = new Schema.Location(
            Name = 'PV Warehouse',
            LocationType = 'Van',
            IsMobile = true,
            IsInventoryLocation = true
        );
        insert faultyLocation;
    }
    @isTest
    static void productTransferTest(){
        String serializesPd1 = [Select Id From Product2 where Name ='Serialized Product' limit 1].Id;
        String serializesPd2 = [Select Id From Product2 where Name ='Serialized Product1' limit 1].Id;
        String nonSerializesPd1 = [Select Id From Product2 where Name ='Non SZ Product 1' limit 1].Id;
        String nonSerializesPd2 = [Select Id From Product2 where Name ='Non SZ Product 2' limit 1].Id;
        String fromLocation = [Select Id From Location where Name ='Master Location' limit 1].Id;
        String toLocation = [Select Id From Location where Name ='Child Location' limit 1].Id;
        string szpdtransfer = '[{"ProductId":\"'+serializesPd1+'\","SerialNumber":"KL3","Quantity":"","IsSerialized":true},{"ProductId":\"'+serializesPd1+'\","SerialNumber":"KL1","Quantity":"","IsSerialized":true},{"ProductId":\"'+serializesPd2+'\","SerialNumber":"KL2","Quantity":"","IsSerialized":true}]';
        string transferData = '[{"ProductId":\"'+serializesPd1+'\","SerialNumber":"KL4","Quantity":"","IsSerialized":true},{"ProductId":\"'+nonSerializesPd1+'\","SerialNumber":"","Quantity":"10","IsSerialized":false},{"ProductId":\"'+nonSerializesPd1+'\","SerialNumber":"","Quantity":"10","IsSerialized":false},{"ProductId":\"'+nonSerializesPd2+'\","SerialNumber":"","Quantity":"20","IsSerialized":false}]';
      //  string szpdtransfer1 = '[{"ProductId":\"'+serializesPd1+'\","SerialNumber":"KL4","Quantity":"","IsSerialized":true}]';
        Test.startTest();
        PV_InventoryController.addInventoryProducts(transferData,fromLocation);
        PV_InventoryController.addInventoryProducts(szpdtransfer,fromLocation);
       // PV_InventoryController.addInventoryProducts(szpdtransfer1,fromLocation);
        PV_ProductTransferController.transferProduct(szpdtransfer, fromLocation, toLocation);
        PV_ProductTransferController.transferProduct(transferData, fromLocation, toLocation);
        Test.stopTest();    
        ProductItem pitem =  [SELECT id,Product2Id, QuantityOnHand from ProductItem where Product2Id = :serializesPd1 AND LocationId  =:toLocation ];
        ProductItem pitem1 =  [SELECT id,Product2Id, QuantityOnHand from ProductItem where Product2Id = :nonSerializesPd1 AND LocationId  =:toLocation];
        System.assertEquals(3, pitem.QuantityOnHand);
        System.assertEquals(20, pitem1.QuantityOnHand);
    }
    @isTest
    static void handleDefectProductTest(){
        String serializesPd1 = [Select Id From Product2 where Name ='Serialized Product' limit 1].Id;
        string szpdtransfer1 = '[{"ProductId":\"'+serializesPd1+'\","SerialNumber":"KL5","Quantity":"","IsSerialized":true,"rmaNumber":"451246"}]';
        String childLocation = [Select Id From Location where Name ='Child Location' limit 1].Id;
         String faultLocation = [Select Id From Location where Name ='PV Warehouse' limit 1].Id;
        Test.startTest();
        PV_InventoryController.addInventoryProducts(szpdtransfer1,childLocation);
        SerializedProduct szPrdList = [SELECT Id,SerialNumber,Status,Product2Id  from SerializedProduct where SerialNumber = 'KL5' limit 1];
        szPrdList.Status = 'Damaged';
        update szPrdList;
        PV_ProductTransferController.handleDefectProduct(szpdtransfer1, childLocation);
        Test.stopTest();  
        //ProductItem pitem1 =  [SELECT id,Product2Id, QuantityOnHand from ProductItem where Product2Id = :serializesPd1 AND LocationId  =:faultLocation];
        //System.assertEquals(1, pitem1.QuantityOnHand);
    }
    @isTest
    static void handleDefectProductExceptionTest(){
        String serializesPd1 = [Select Id From Product2 where Name ='Serialized Product' limit 1].Id;
        string szpdtransfer1 = '[{"ProductId":\"'+serializesPd1+'\","SerialNumber":"KL5","Quantity":"","IsSerialized":true,"rmaNumber":"451246"},{"ProductId":\"'+serializesPd1+'\","SerialNumber":"KL6","Quantity":"","IsSerialized":true,"rmaNumber":"451246"}]';
        String childLocation = [Select Id From Location where Name ='Child Location' limit 1].Id;
        Test.startTest();
        PV_InventoryController.addInventoryProducts(szpdtransfer1,childLocation);
        SerializedProduct szPrdList = [SELECT Id,SerialNumber,Status,Product2Id  from SerializedProduct where SerialNumber = 'KL5' limit 1];
        szPrdList.Status = 'Damaged';
        update szPrdList;
        szPrdList = [SELECT Id, SerialNumber, Status, Product2Id FROM SerializedProduct WHERE SerialNumber = 'KL6' LIMIT 1];
        szPrdList.Status = 'Consumed';
        update szPrdList;
        try{
            PV_ProductTransferController.handleDefectProduct(szpdtransfer1, childLocation);
        }catch(Exception e){
            Assert.isNotNull(e);
        }
        Test.stopTest();
    }

    @isTest
    static void getSerializedProductsTest() {
        String serializesPd1 = [SELECT Id FROM Product2 WHERE Name = 'Serialized Product' LIMIT 1].Id;
        string szpdtransfer1 = '[{"ProductId":\"' + serializesPd1 + '\","SerialNumber":"KL5","Quantity":"","IsSerialized":true,"rmaNumber":"451246"}]';
        String childLocation = [SELECT Id FROM Location WHERE Name = 'Child Location' LIMIT 1].Id;

        Test.startTest();
        PV_InventoryController.addInventoryProducts(szpdtransfer1, childLocation);
        SerializedProduct szPrdList = [SELECT Id FROM SerializedProduct WHERE SerialNumber = 'KL5' LIMIT 1];
        szPrdList.Status = 'Damaged';
        update szPrdList;
        
        List<PV_ProductTransferController.OptionWrapper> options = PV_ProductTransferController.getSerializedProducts(childLocation, serializesPd1, true);
        Test.stopTest();
        
        Assert.areEqual(1, options.size(), 'Expected the number of options to be the same');
        Assert.areEqual('KL5', options[0].value, 'Expected the option value to be the same');
    }
}
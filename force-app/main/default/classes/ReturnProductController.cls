public without sharing class ReturnProductController {

    @AuraEnabled 
    public static FSL_AppUtils.ResponseWrapper returnProduct(String productName, String serialNumber, String reason, String workOrderId, String description){

        try {

            Product2 product = [SELECT Id, Name FROM Product2 WHERE Name = :productName LIMIT 1];

            Id userId = UserInfo.getUserId();

            List<ServiceResource> sr = [SELECT Id, RelatedRecordId, LocationId FROM ServiceResource WHERE RelatedRecordId = :userId LIMIT 1];

            List<ProductItem> pi = [SELECT Id, Product2Id, LocationId FROM ProductItem WHERE Product2Id = :product.Id AND LocationId = :sr[0].LocationId LIMIT 1];

            SerializedProduct sp = new SerializedProduct();
            sp.Product2Id = product.Id;
            sp.SerialNumber = serialNumber;
            sp.Status = 'Damaged';

            if(!pi.isEmpty()) {
                sp.ProductItemId = pi[0].Id;
            }else {

                ProductItem newPI = new ProductItem();
                newPI.LocationId = sr[0].LocationId;
                newPI.Product2Id = product.Id;
                newPI.QuantityOnHand = 0;

                insert newPI;
                sp.ProductItemId = newPI.Id;
            }

            insert sp;

            List<Asset> asset = [SELECT Id, Product2Id FROM Asset WHERE Product2Id = :product.Id LIMIT 1];
            ReturnOrderLineItem roLine = new ReturnOrderLineItem();


            if(!asset.isEmpty()) {
                asset[0].Status = 'Returned';
                asset[0].UsageEndDate = System.today();

                roLine.AssetId = asset[0].Id;

                update asset;
            }

            List<WorkOrder> wo = [SELECT Id, AccountId, ContactId, Street, postalCode, city, state  FROM WorkOrder WHERE Id = :workOrderId LIMIT 1];

            ReturnOrder ro = new ReturnOrder();
            ro.AccountId = wo[0].AccountId;
            ro.ContactId = wo[0].ContactId;
            ro.ShipFromStreet = wo[0].street;
            ro.ShipFromPostalCode = wo[0].postalCode;
            ro.ShipFromCity = wo[0].city;
            ro.ShipFromState = wo[0].state;
            ro.Status = 'Submited';
            ro.description = description;

            insert ro;

            roLine.DestinationLocationId = sr[0].LocationId;
            roLine.ProcessingPlan = 'Repair';
            roLine.Product2Id = product.Id;
            roLine.ProductItemId = sp.ProductItemId;
            roLine.QuantityReturned = 1;
            roLine.QuantityUnitOfMeasure = 'Each';
            roLine.ReasonForReturn = reason;
            roLine.ReturnOrderId = ro.Id;

            insert roLine;

            return new FSL_AppUtils.ResponseWrapper('SUCCESS', null, null);

        }catch(Exception e) {

            return new FSL_AppUtils.ResponseWrapper('ERROR', null, e.getMessage());
        }
    }
}
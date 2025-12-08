public without sharing class PV_InventoryController {
    
    @AuraEnabled(cacheable=false)
    public static List<SObjectResult> getResults(String searchTerm, String objectName) {
        List<SObjectResult> SObjectResultList = new List<SObjectResult>();
        String searchValue = '\'%' + String.escapeSingleQuotes(searchTerm) + '%\'';
        String query = '';
        
        if (objectName == 'Location') {
            String accountId = [SELECT AccountId FROM User WHERE Id = :UserInfo.getUserId()].AccountId;
            
            if (accountId != null) {
                query = 'SELECT Id, Name FROM ' + objectName + ' WHERE  Account__c = ' + '\'' + accountId + '\'' + ' AND Name LIKE ' + searchValue + ' LIMIT 5';
                System.debug('query'); System.debug(query);
            } else {
                query = 'SELECT Id, Name FROM ' + objectName + ' WHERE Name LIKE ' + searchValue + ' LIMIT 5';
            }
        } else if (objectName == 'Product2') {
            List<String> availableVendors = new List<String>();
            User user = getCurrentUser();

            query = 
                'SELECT Id, Name, ProductCode, FSL_Vendor__c ' +
                'FROM ' + objectName + ' ' +
                'WHERE FSL_Product__c = true ' +
                'AND (Name LIKE ' + searchValue + ' OR ProductCode LIKE ' + searchValue + ') '
            ;
            
            if (user.Contact.Account.Available_FSL_Vendors__c != null) {
                availableVendors = user.Contact.Account.Available_FSL_Vendors__c.split(';');
                query = query + 'AND FSL_Vendor__c IN :availableVendors LIMIT 5';
            } else if (!isCommunityUser()) {
                query = query + 'LIMIT 5';
            } else {
                query = query + 'LIMIT 0';
            }
        } else {
            query = 'SELECT Id, Name FROM ' + objectName + ' WHERE Name LIKE ' + searchValue + ' LIMIT 5';
        }

        for (sObject sObj : Database.Query(query)) {
            SObjectResultList.add(new SObjectResult((String) sObj.get('Name'), sObj.Id));
        }
        return SObjectResultList;
    }

    @AuraEnabled(cacheable=true)
    public static Boolean isCommunityUser() {
        User user = getCurrentUser();

        if (user.Contact == null) {
            return false;
        } else {
            return true;
        }
    }
    
    public static User getCurrentUser() {
        return [
            SELECT  Contact.Account.Available_FSL_Vendors__c
            FROM    User
            WHERE   Id = :UserInfo.getUserId()
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getScannerUrls() {
        Map<String, String> urls = new Map<String, String>();
        FSL_Settings__c settings = FSL_Settings__c.getInstance();

        if (settings != null) {
            urls.put('communityUrl', settings.Community_Scanner_Url__c);
            urls.put('internalUrl', settings.Internal_Scanner_URL__c);
        }

        return urls;
    }

    @AuraEnabled(cacheable=false)
    public static UserInformation getUserInformation() {
        String userProfile = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
        list<serviceresource> sr = [
            SELECT Id, RelatedRecordId, LocationId, Location.Name
            FROM serviceresource
            WHERE RelatedRecordId = :UserInfo.getUserId() AND ResourceType = 'T'
        ];
        UserInformation usrInf = new UserInformation();
        if (!sr.isEmpty() && (Permission_Set_Assignment__mdt.getInstance('SR_Permissions').Profile__c == userProfile)) {
            usrInf.locationId = sr[0].LocationId;
            usrInf.locationName = sr[0].Location.Name;
            usrInf.isTechnician = true;
        } else {
            usrInf.locationId = '';
            usrInf.locationName = '';
            usrInf.isTechnician = false;
        }
        return usrInf;
    }

    @AuraEnabled(cacheable=false)
    public static Boolean serializedProductCheck(String productId) {
        return [SELECT Id, IsSerialized FROM product2 WHERE Id = :productId].IsSerialized;
    }
    
    @AuraEnabled(cacheable=false)
    public static void addInventoryProducts(String productItemJson, String locationId) {
        try {
            List<ProductItemWrapper> productItemList = (List<ProductItemWrapper>) System.JSON.deserialize(productItemJson, List<ProductItemWrapper>.class);
            validateSerializedProduct(productItemList);
            
            List<SerializedProduct> serializedProductListForExistingProductItem = new List<SerializedProduct>();
            Map<Id, ProductItem> existingProductItemMap = new Map<Id, ProductItem>();
            Map<Id, ProductItem> nonSerializedProductItemCreateMap = new Map<Id, ProductItem>();
            Map<Id, ProductItem> newSerializedProductItemMap = new Map<Id, ProductItem>();
            Map<Id, List<SerializedProduct>> newSerializedProductMap = new Map<Id, List<SerializedProduct>>();
            
            for (ProductItem prdItem : [
                SELECT  Id, Product2Id, QuantityOnHand
                FROM    ProductItem
                WHERE   LocationId = :locationId
            ]) {
                existingProductItemMap.put(prdItem.Product2Id, prdItem);
            }

            for (ProductItemWrapper prdWrapper : productItemList) {
                ProductItem prdItem = new ProductItem();
                ProductItem srPrdItem = new ProductItem();
                SerializedProduct serializedProductWithPrdItem = new SerializedProduct();

                if (!prdWrapper.IsSerialized) {
                    // Check for this product item is already exist in this location
                    if (nonSerializedProductItemCreateMap.containsKey(prdWrapper.ProductId)) {
                        prdItem = nonSerializedProductItemCreateMap.get(prdWrapper.ProductId);
                        prdItem.QuantityOnHand += Decimal.valueOf(prdWrapper.Quantity);
                        nonSerializedProductItemCreateMap.put(prdWrapper.ProductId, prdItem);
                    } else {
                        if (existingProductItemMap.containsKey(prdWrapper.ProductId)) {
                            prdItem.Id = existingProductItemMap.get(prdWrapper.ProductId).Id;
                            prdItem.QuantityOnHand =
                                existingProductItemMap.get(prdWrapper.ProductId).QuantityOnHand +
                                Decimal.valueOf(prdWrapper.Quantity);
                        } else {
                            prdItem.LocationId = locationId;
                            prdItem.Product2Id = prdWrapper.ProductId;
                            prdItem.QuantityOnHand = Decimal.valueOf(prdWrapper.Quantity);
                        }
                        nonSerializedProductItemCreateMap.put(prdWrapper.ProductId, prdItem);
                    }
                } else {
                    // Serialized Product already exist in location or not
                    if (existingProductItemMap.containsKey(prdWrapper.ProductId)) {
                        serializedProductWithPrdItem.SerialNumber = prdWrapper.SerialNumber;
                        serializedProductWithPrdItem.Product2Id = prdWrapper.ProductId;
                        serializedProductWithPrdItem.ProductItemId = existingProductItemMap.get(prdWrapper.ProductId).Id;
                        serializedProductWithPrdItem.Status = 'Available';
                        serializedProductListForExistingProductItem.add(serializedProductWithPrdItem);
                    } else {
                        if (!newSerializedProductItemMap.containsKey(prdWrapper.ProductId)) {
                            srPrdItem.LocationId = locationId;
                            srPrdItem.Product2Id = prdWrapper.ProductId;
                            srPrdItem.QuantityOnHand = 0.00;
                            newSerializedProductItemMap.put(prdWrapper.ProductId, srPrdItem);
                        }

                        serializedProductWithPrdItem.SerialNumber = prdWrapper.SerialNumber;
                        serializedProductWithPrdItem.Product2Id = prdWrapper.ProductId;
                        serializedProductWithPrdItem.ProductItemId = null;
                        serializedProductWithPrdItem.Status = 'Available';

                        if (newSerializedProductMap.containsKey(prdWrapper.ProductId)) {
                            newSerializedProductMap.get(prdWrapper.ProductId).add(serializedProductWithPrdItem);
                        } else {
                            newSerializedProductMap.put(prdWrapper.ProductId, new List<SerializedProduct>{ serializedProductWithPrdItem });
                        }
                    }
                }
            }

            if (!nonSerializedProductItemCreateMap.values().isEmpty()) {
                upsert nonSerializedProductItemCreateMap.values();
            }
            if (!serializedProductListForExistingProductItem.isEmpty()) {
                insert serializedProductListForExistingProductItem;
            }
            if (!newSerializedProductItemMap.values().isEmpty()) {
                insert newSerializedProductItemMap.values();
                list<SerializedProduct> newSerializedProductList = new List<SerializedProduct>();
                for (ProductItem newPrdItem : newSerializedProductItemMap.values()) {
                    for (SerializedProduct srp : newSerializedProductMap.get(newPrdItem.Product2Id)) {
                        srp.ProductItemId = newPrdItem.Id;
                        newSerializedProductList.add(srp);
                    }
                }
                if (!newSerializedProductList.isEmpty()) {
                    insert newSerializedProductList;
                }
            }
        } catch (Exception ex) {
            system.debug(ex.getMessage());
            ExceptionUtil.publishException(
                'addInventoryProducts',
                ex.getLineNumber(),
                ex.getMessage(),
                ex.getStackTraceString()
            );
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static void validateSerializedProduct(list<ProductItemWrapper> productItemList) {
        Set<String> uniqueSerialNumberSet = new Set<String>();
        Map<String, List<String>> existingSeriaNumberMap = new Map<String, List<String>>();
        String duplicateEntry = '';

        for (ProductItemWrapper prdWrapper : productItemList) {
            if (prdWrapper.IsSerialized) {
                uniqueSerialNumberSet.add(prdWrapper.SerialNumber);
            }
        }

        if (!String.isBlank(duplicateEntry)) {
            throw newMessageException('Duplicate serial number:' + duplicateEntry + '. Please enter a different serial number.');
        }

        for (SerializedProduct srPrdt : [
            SELECT  SerialNumber, Product2Id
            FROM    SerializedProduct
            WHERE   SerialNumber IN :uniqueSerialNumberSet
        ]) {
            if (existingSeriaNumberMap.containsKey(srPrdt.Product2Id)) {
                existingSeriaNumberMap.get(srPrdt.Product2Id).add(srPrdt.SerialNumber);
            } else {
                existingSeriaNumberMap.put(srPrdt.Product2Id, new List<String>{ srPrdt.SerialNumber });
            }
        }

        String existingSerialNumber = '';
        for (ProductItemWrapper prdWrapper : productItemList) {
            if (prdWrapper.IsSerialized) {
                if (
                    existingSeriaNumberMap.containsKey(prdWrapper.ProductId) &&
                    existingSeriaNumberMap.get(prdWrapper.ProductId).contains(prdWrapper.SerialNumber)
                ) {
                    if (!String.isBlank(existingSerialNumber)) {
                        existingSerialNumber += ',';
                    }
                    existingSerialNumber += prdWrapper.SerialNumber;
                }
            }
        }
        
        if (!String.isBlank(existingSerialNumber)) {
            throw newMessageException('These serial numbers already exist:' + existingSerialNumber + '. Please enter a different serial number.');
        }
    }

    private static AuraHandledException newMessageException(String message) {
        AuraHandledException e = new AuraHandledException(message);
        e.setMessage(message);
        return e;
    }
    
    public class SObjectResult {
        @AuraEnabled
        public String recName;
        @AuraEnabled
        public Id recId;

        public SObjectResult(String recordName, Id recordtId) {
            recName = recordName;
            recId = recordtId;
        }
    }
    
    public class ProductItemWrapper {
        public String ProductName;
        public String ProductId;
        public String SerialNumber;
        public String Quantity;
        public String Location;
        public Boolean IsSerialized;
    }

    public class UserInformation {
        @AuraEnabled
        public String locationId;
        @AuraEnabled
        public String locationName;
        @AuraEnabled
        public Boolean isTechnician;
    }

    @AuraEnabled
    public static List<Product2> fetchProducts(String searchString, String vendor) {
        try {
            if (searchString != null && searchString.length() > 2) {
                List<List<Product2>> searchList = [FIND :searchString IN ALL FIELDS RETURNING Product2(Id, Name, ProductCode, IsSerialized WHERE IsActive = true AND FSL_Vendor__c = :vendor) LIMIT 20];
                return searchList[0];
            }
            return null;

        } catch(Exception err) {
            throw new AuraHandledException(err.getMessage());
        }
    }

    public static String filterProductsNotInTechnicianVan(String productsJson, String locationId) {
        List<ProductItemWrapper> productItemList = (List<ProductItemWrapper>) System.JSON.deserialize(productsJson, List<ProductItemWrapper>.class);
        List<ProductItemWrapper> filteredProducts = new List<ProductItemWrapper>();
        Set<String> serializedProductsInVan = new Set<String>();
        
        for (SerializedProduct serializedProduct : [SELECT SerialNumber FROM SerializedProduct WHERE ProductItem.LocationId = :locationId AND Status = 'Available']) {
            serializedProductsInVan.add(serializedProduct.SerialNumber);
        }
        
        for (ProductItemWrapper product : productItemList) {
            Boolean shouldInclude = !product.IsSerialized || (product.SerialNumber != null && !serializedProductsInVan.contains(product.SerialNumber));
            if (shouldInclude) {
                filteredProducts.add(product);
            }
        }
        
        return JSON.serialize(filteredProducts);
    }
}
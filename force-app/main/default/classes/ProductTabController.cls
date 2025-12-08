public without sharing class ProductTabController {
    public static final String SPECTRUM_PROGRAM = System.label.Spectrum_API;

    @AuraEnabled
    public static ResponseWrapper saveProduct(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String productName = '';
            Map<String, Object> output = new Map<String, Object>();
            String program = (String) myData.get('Program');
            String oppId = (String) myData.get('ContextId');
            String selectedPromoCodeLabel = (String) myData.get('selectedPromoCodeLabel');

            if (myData.get('Product') != null && program != SPECTRUM_PROGRAM) {
                Map<Object, Object> productMap = (Map<Object, Object>) myData.get('Product');
                productName = (String) productMap.get('Name');
                output = upsertProduct(productMap, oppId, program);
            }

            switch on program {
                when 'DirecTV' {
                    saveProgramProduct((List<Object>) myData.get('OtherProducts'), oppId, program);
                }
                when 'Windstream', 'Frontier' {
                    saveProgramProduct((List<Object>) myData.get('Adders'), null, null);
                }
                when 'EarthLink' {
                    saveProgramProduct((List<Object>) myData.get('Services'), null, null);
                }
                when 'Spectrum API' {
                    Map<Object, Object> spectrumProduct = (Map<Object, Object>) myData.get('Product');
                    productName = (String) spectrumProduct.get('Name');
                    List<Object> spectrumSubProducts = (List<Object>) spectrumProduct.get('subProducts');
                    if (spectrumSubProducts != null && !spectrumSubProducts.isEmpty()) {
                        saveProgramProduct(spectrumSubProducts, oppId, program);
                    } else {
                        upsertProduct(spectrumProduct, oppId, program);
                    }
                }
            }
            updateACIStatistics(oppId);
            updateStage(oppId, selectedPromoCodeLabel);

            Map<String, Object> result = new Map<String, Object>{ 'ProductName' => productName };
            response.result = result;
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @future(callout=false)
    public static void updateACIStatistics(String oppId) {
        try {
            if (!Auth.CommunitiesUtil.isGuestUser()) {
                POE_ACI_Statistic__c aciStatistic = [
                    SELECT Id, Product_Selection__c, Opportunity__r.Id, Opportunity__r.StageName
                    FROM POE_ACI_Statistic__c
                    WHERE Opportunity__c = :oppId
                    LIMIT 1
                ];
                aciStatistic.Product_Selection__c = 1;
                update aciStatistic;
            }
        } catch (Exception e) {
            System.debug('Error in future method: ' + e.getMessage());
        }
    }

    @future(callout=false)
    public static void updateStage(String oppId, String selectedPromoCodeLabel) {
        try {
            Opportunity opp = new Opportunity(Id = oppId, StageName = 'Presentation');
            if (selectedPromoCodeLabel != null) {
                opp.Earthlink_Sale_Type__c = selectedPromoCodeLabel;
            }
            update opp;
        } catch (Exception e) {
            System.debug('Error in future method: ' + e.getMessage());
        }
    }

    @future(callout=false)
    public static void lineItemsHandler(String oppId, Set<Id> entriesIds) {
        try {
            List<OpportunityLineItem> newLineItems = new List<OpportunityLineItem>();
            Map<String, PricebookEntry> pricebookEntriesByName = new Map<String, PricebookEntry>();
            List<OpportunityLineItem> oppLineItems = [
                SELECT Id, Name
                FROM OpportunityLineItem
                WHERE OpportunityId = :oppId
            ];
            if (oppLineItems.size() > 0) {
                delete oppLineItems;
            }
            for (PricebookEntry pe : [SELECT Id, Name, UnitPrice FROM PricebookEntry WHERE Id IN :entriesIds]) {
                newLineItems.add(
                    new OpportunityLineItem(
                        OpportunityId = oppId,
                        PricebookEntryId = pe.Id,
                        UnitPrice = pe.UnitPrice,
                        Quantity = 1
                    )
                );
            }
            if (newLineItems.size() > 0) {
                insert newLineItems;
            }
        } catch (Exception e) {
            System.debug('Error in future method: ' + e.getMessage());
        }
    }

    private static void saveProgramProduct(List<Object> products, String oppId, String program) {
        Map<String, String> familyByName = new Map<String, String>();
        Map<String, String> codeByName = new Map<String, String>();
        Map<String, String> descriptionByName = new Map<String, string>();
        Map<String, Decimal> priceByName = new Map<String, Decimal>();

        for (Object product : products) {
            Map<Object, Object> productMap = (Map<Object, Object>) product;
            String productName = (String) productMap.get('Name');
            productName = productName.toLowerCase();
            familyByName.put(productName, (String) productMap.get('Family'));
            codeByName.put(productName, (String) productMap.get('servRef'));
            descriptionByName.put(productName, (String) productMap.get('Description'));
            priceByName.put(productName, (Decimal) productMap.get('UnitPrice'));
        }

        Set<String> productNames = familyByName.keySet();
        List<Product2> productUpsertList = checkExistentProducts(
            productNames,
            familyByName,
            codeByName,
            descriptionByName
        );
        upsert productUpsertList;
        List<PriceBookEntry> priceBookUpsertList = checkExistentPriceBookEntries(productNames, priceByName);
        upsert priceBookUpsertList;

        if (program != null && (program == 'DirecTV' || program == SPECTRUM_PROGRAM)) {
            Set<Id> entriesIds = new Set<Id>();
            for (PriceBookEntry entry : priceBookUpsertList) {
                entriesIds.add(entry.Id);
            }
            lineItemsHandler(oppId, entriesIds);
        }
    }

    private static List<Product2> checkExistentProducts(
        Set<String> productNames,
        Map<String, String> familyByName,
        Map<String, String> codeByName,
        Map<String, String> descriptionByName
    ) {
        List<Product2> productUpsertList = new List<Product2>();
        Set<String> existentProductNames = new Set<String>();

        for (Product2 existentProduct : [
            SELECT Id, Name, ProductCode, Family, Description
            FROM Product2
            WHERE Name IN :productNames
        ]) {
            String productName = existentProduct.Name.toLowerCase();
            if (!existentProductNames.contains(productName)) {
                existentProductNames.add(productName);
                existentProduct.ProductCode = codeByName.get(productName);
                existentProduct.Family = familyByName.get(productName);
                existentProduct.Description = descriptionByName.get(productName);
                productUpsertList.add(existentProduct);
            }
        }

        for (String productName : productNames) {
            if (!(existentProductNames.contains(productName))) {
                Product2 newProduct = new Product2();
                String newName = productName.toLowerCase();
                newProduct.Name = newName.capitalize();
                newProduct.ProductCode = codeByName.get(productName);
                newProduct.Family = familyByName.get(productName);
                newProduct.Description = descriptionByName.get(productName);
                productUpsertList.add(newProduct);
            }
        }

        return productUpsertList;
    }

    private static List<PriceBookEntry> checkExistentPriceBookEntries(
        Set<String> productNames,
        Map<String, Decimal> priceByName
    ) {
        Pricebook2 standardPriceBook = [SELECT Id FROM Pricebook2 WHERE Name = 'Standard Price Book' LIMIT 1];
        List<PriceBookEntry> priceBookUpsertList = new List<PriceBookEntry>();
        Set<String> existentProductNames = new Set<String>();
        Set<String> newPriceBookEntryIds = new Set<String>();
        System.debug(priceByName);

        for (PriceBookEntry existentProduct : [
            SELECT Id, IsActive, UnitPrice, Product2.Name
            FROM PriceBookEntry
            WHERE PriceBook2Id = :standardPriceBook.Id AND Product2.Name IN :productNames
        ]) {
            String productName = existentProduct.Product2.Name.toLowerCase();
            if (!existentProductNames.contains(productName)) {
                existentProductNames.add(productName);
                existentProduct.IsActive = true;
                existentProduct.UnitPrice = (Decimal) priceByName.get(productName);
                priceBookUpsertList.add(existentProduct);
            }
        }

        for (String productName : productNames) {
            if (!(existentProductNames.contains(productName))) {
                newPriceBookEntryIds.add(productName);
            }
        }

        for (Product2 prod : [SELECT Id, Name FROM Product2 WHERE Name IN :newPriceBookEntryIds]) {
            PricebookEntry pbEntry = new PricebookEntry();
            pbEntry.IsActive = true;
            pbEntry.Pricebook2Id = standardPriceBook.Id;
            pbEntry.Product2Id = prod.Id;
            pbEntry.UnitPrice = (Decimal) priceByName.get(prod.Name.toLowerCase());
            priceBookUpsertList.add(pbEntry);
        }

        return priceBookUpsertList;
    }

    private static Map<String, Object> upsertProduct(Map<Object, Object> data, String oppId, String program) {
        Map<String, Object> response = new Map<String, Object>();
        OpportunityLineItem oppProduct;

        String productName = (String) data.get('Name');
        Pricebook2 standardPriceBook = [SELECT Id FROM Pricebook2 WHERE Name = 'Standard Price Book'];
        List<Product2> prods = [SELECT Id, Name FROM Product2 WHERE Name = :productName];

        if (prods.isEmpty()) {
            Product2 prod = new Product2();
            prod.Name = productName;
            prod.ProductCode = (String) data.get('servRef');
            prod.Family = (String) data.get('Family');
            prod.Description = (String) data.get('Description');
            insert prod;

            PricebookEntry pbEntry = new PricebookEntry();
            pbEntry.IsActive = true;
            pbEntry.Pricebook2Id = standardPriceBook.Id;
            pbEntry.Product2Id = prod.Id;
            pbEntry.UnitPrice = (Decimal) data.get('UnitPrice');
            insert pbEntry;

            if (program != null && (program == 'DirecTV' || program == 'Spectrum')) {
                oppProduct = new OpportunityLineItem(
                    OpportunityId = oppId,
                    PricebookEntryId = pbEntry.Id,
                    UnitPrice = pbEntry.UnitPrice,
                    Quantity = 1
                );
                insert oppProduct;
            }

            response.put('ProductName', prod.Name);
        } else {
            List<PricebookEntry> entries = [
                SELECT Id, IsActive, UnitPrice
                FROM PricebookEntry
                WHERE Pricebook2Id = :standardPriceBook.Id AND Product2Id = :prods[0].Id
            ];

            if (entries.isEmpty()) {
                PricebookEntry pbEntry = new PricebookEntry();

                pbEntry.IsActive = true;
                pbEntry.Pricebook2Id = standardPriceBook.Id;
                pbEntry.Product2Id = prods[0].Id;
                pbEntry.UnitPrice = (Decimal) data.get('UnitPrice');

                insert pbEntry;

                if (program != null && (program == 'DirecTV' || program == SPECTRUM_PROGRAM)) {
                    oppProduct = new OpportunityLineItem(
                        OpportunityId = oppId,
                        PricebookEntryId = pbEntry.Id,
                        UnitPrice = pbEntry.UnitPrice,
                        Quantity = 1
                    );
                    insert oppProduct;
                }
            } else {
                PricebookEntry existingEntry = entries[0];
                Decimal inputUnitPrice = (Decimal) data.get('UnitPrice');
                if (!existingEntry.IsActive || (inputUnitPrice != null && existingEntry.UnitPrice != inputUnitPrice)) {
                    existingEntry.IsActive = true;
                    existingEntry.UnitPrice = (Decimal) data.get('UnitPrice');

                    update existingEntry;
                }
            }
            response.put('ProductName', prods[0].Name);
        }

        return response;
    }

    @AuraEnabled
    public static ResponseWrapper getEarthLinkExcludedProducts() {
        try {
            ResponseWrapper response = new ResponseWrapper();

            List<Chuzo_Settings__c> excludedProducts = [
                SELECT Id, Excluded_Products_Earthlink__c
                FROM Chuzo_Settings__c
            ];

            response.result = new Map<String, Object>{ 'Excluded Products' => excludedProducts };
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper getWindstreamDisclaimers() {
        try {
            ResponseWrapper response = new ResponseWrapper();

            List<POE_Windstream_Disclaimer__c> disclaimers = [
                SELECT Id, Name, Disclaimer__c
                FROM POE_Windstream_Disclaimer__c
            ];

            response.result = new Map<String, Object>{ 'Disclaimers' => disclaimers };
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Chuzo_Settings__c getDTVProjectsFlag() {
        try {
            Chuzo_Settings__c settings = Chuzo_Settings__c.getOrgDefaults();
            return settings;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Boolean getVideoFlag() {
        try {
            User agent = [SELECT Id, AccountId FROM User WHERE Id = :System.UserInfo.getUserId() LIMIT 1];
            Account dealer = [SELECT Id, Frontier_Video__c FROM Account WHERE Id = :agent.AccountId];
            return dealer.Frontier_Video__c;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper getSBSFile(Map<String, Object> myData) {
        try {
            String contextId = (String) myData.get('ContextId');
            ResponseWrapper response = new ResponseWrapper();
            Map<String, Object> result = new Map<String, Object>();

            List<ContentDocumentLink> docLink = [
                SELECT ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :contextId
            ];
            if (!docLink.isEmpty()) {
                List<ContentVersion> docs = [
                    SELECT Id
                    FROM ContentVersion
                    WHERE ContentDocumentId = :docLink[0].ContentDocumentId
                ];

                if (!docs.isEmpty()) {
                    result.put('Id', docs[0].Id);
                }
            }

            response.result = result;

            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper saveSBSFile(Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();

            String recId = (String) myData.get('ContextId');
            if (myData.containsKey('isEncryptedId')) {
                Boolean isEncryptedId = (Boolean) myData.get('isEncryptedId');
                if (isEncryptedId) {
                    recId = POE_PublicRecordAccessUtility.decryptRecordId(recId);
                }
            }
            String strSignElement = (String) myData.get('strSignElement');
            Boolean isUpdate = (Boolean) myData.get('Update');
            String type = (String) myData.get('Type');
            String cversionId = (String) myData.get('cvId');
            ContentVersion cVersion = new ContentVersion();
            if (type == 'signature') {
                cVersion.ContentLocation = 'S';
                cVersion.PathOnClient = 'Signature-' + System.now() + '.png';
                cVersion.Origin = 'H';
                cVersion.Title = 'poe_signature_' + System.now() + '.png';
                cVersion.VersionData = EncodingUtil.base64Decode(strSignElement);
            } else {
                cVersion.ContentLocation = 'S';
                cVersion.PathOnClient = 'Signature-' + System.now() + '.png';
                cVersion.Origin = 'H';
                cVersion.Title = 'poe_img_sidebyside_' + System.now() + '.png';
                cVersion.VersionData = EncodingUtil.base64Decode(strSignElement);
            }
            if (cversionId != null && cversionId != '') {
                Id prevConDocument = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cversionId]
                .ContentDocumentId;
                List<ContentDocument> prevDocList = [SELECT Id FROM ContentDocument WHERE Id = :prevConDocument];
                delete prevDocList;
            }

            insert cVersion;

            Map<String, Object> result = new Map<String, Object>{ 'cVersion' => cVersion };

            Id conDocument = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cVersion.Id].ContentDocumentId;

            ContentDocumentLink cDocLink = new ContentDocumentLink();
            cDocLink.ContentDocumentId = conDocument;
            cDocLink.LinkedEntityId = recId;
            cDocLink.ShareType = 'I';
            cDocLink.Visibility = 'AllUsers';
            insert cDocLink;

            response.result = result;

            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper GetInternationalPackage() {
        try {
            ResponseWrapper response = new ResponseWrapper();

            List<User> currentUser = [
                SELECT Id, AccountId, Account.POE_Espanol_Package__c
                FROM User
                WHERE Id = :System.UserInfo.getUserId()
            ];

            Map<String, Object> acc = new Map<String, Object>{
                'POE_Espanol_Package__c' => currentUser[0].Account.POE_Espanol_Package__c
            };

            response.result = new Map<String, Object>{ 'Account' => acc };

            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper getViasatBNLData() {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String orgId = UserInfo.getOrganizationId();
            Viasat_BNL_Form_Settings__c settings = Viasat_BNL_Form_Settings__c.getOrgDefaults();
            if (Test.isRunningTest()) {
                response.result = new Map<String, Object>{
                    'orgId' => orgId,
                    'leadSource__c' => 'TestLeadSource',
                    'viasatOrgUrl__c' => 'https://www.example.com'
                };
            } else {
                response.result = new Map<String, Object>{
                    'orgId' => orgId,
                    'leadSource__c' => settings.leadSource__c,
                    'viasatOrgUrl__c' => settings.viasatOrgUrl__c
                };
            }
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper saveOrderItems(List<Map<String, Object>> items, Id orderId, Boolean dsl) {
        ResponseWrapper response = new ResponseWrapper();
        try {
            // 1. Upsert Products by ProductCode
            Map<String, Map<String, Object>> codeToItem = new Map<String, Map<String, Object>>();
            Boolean dslFlagUpdate = false;
            Set<String> codes = new Set<String>();
            for (Map<String, Object> item : items) {
                String code = (String) item.get('code');
                if (String.isBlank(code)) {
                    throw new AuraHandledException('Product code is required for all items');
                }
                codes.add(code);
                codeToItem.put(code, item);
            }
            List<Product2> existingProductsList = [
                SELECT Id, Name, ProductCode, Family, Description
                FROM Product2
                WHERE ProductCode IN :codes
            ];
            Map<String, Product2> codeToProduct = new Map<String, Product2>();
            for (Product2 prod : existingProductsList) {
                codeToProduct.put(prod.ProductCode, prod);
            }
            List<Product2> toInsertProducts = new List<Product2>();
            List<Product2> toUpdateProducts = new List<Product2>();
            for (String code : codes) {
                Map<String, Object> item = codeToItem.get(code);
                Product2 prod = codeToProduct.get(code);
                if (prod == null) {
                    prod = new Product2();
                    prod.ProductCode = code;
                    prod.Name = (String) item.get('name');
                    prod.Family = (String) item.get('family');
                    prod.Description = (String) item.get('description');
                    prod.IsActive = true;
                    toInsertProducts.add(prod);
                } else {
                    prod.Name = (String) item.get('name');
                    prod.Family = (String) item.get('family');
                    prod.Description = (String) item.get('description');
                    prod.IsActive = true;
                    toUpdateProducts.add(prod);
                }
            }
            if (!toInsertProducts.isEmpty())
                insert toInsertProducts;
            if (!toUpdateProducts.isEmpty())
                update toUpdateProducts;
            // Refresh map with upserted Ids
            List<Product2> allProducts = [SELECT Id, Name, ProductCode FROM Product2 WHERE ProductCode IN :codes];
            codeToProduct.clear();
            for (Product2 prod : allProducts) {
                codeToProduct.put(prod.ProductCode, prod);
            }
            // 2. Upsert PricebookEntry in Standard Price Book
            Pricebook2 stdPb = [SELECT Id FROM Pricebook2 WHERE IsStandard = TRUE LIMIT 1];
            List<PricebookEntry> existingPBEs = [
                SELECT Id, Product2Id, UnitPrice, IsActive, Product2.ProductCode
                FROM PricebookEntry
                WHERE Pricebook2Id = :stdPb.Id AND Product2.ProductCode IN :codes
            ];
            Map<String, PricebookEntry> codeToPBE = new Map<String, PricebookEntry>();
            for (PricebookEntry pbe : existingPBEs) {
                codeToPBE.put(pbe.Product2.ProductCode, pbe);
            }
            List<PricebookEntry> toInsertPBEs = new List<PricebookEntry>();
            List<PricebookEntry> toUpdatePBEs = new List<PricebookEntry>();
            for (String code : codes) {
                Product2 prod = codeToProduct.get(code);
                Map<String, Object> item = codeToItem.get(code);
                Decimal price = (Decimal) item.get('price');
                PricebookEntry pbe = codeToPBE.get(code);
                if (pbe == null) {
                    pbe = new PricebookEntry();
                    pbe.Product2Id = prod.Id;
                    pbe.Pricebook2Id = stdPb.Id;
                    pbe.UnitPrice = price;
                    pbe.IsActive = true;
                    toInsertPBEs.add(pbe);
                } else {
                    pbe.UnitPrice = price;
                    pbe.IsActive = true;
                    toUpdatePBEs.add(pbe);
                }
            }
            if (!toInsertPBEs.isEmpty())
                insert toInsertPBEs;
            if (!toUpdatePBEs.isEmpty())
                update toUpdatePBEs;
            // Refresh map with upserted PBEs
            existingPBEs = [
                SELECT Id, Product2Id, UnitPrice, IsActive, Product2.ProductCode
                FROM PricebookEntry
                WHERE Pricebook2Id = :stdPb.Id AND Product2.ProductCode IN :codes
            ];
            codeToPBE.clear();
            for (PricebookEntry pbe : existingPBEs) {
                codeToPBE.put(pbe.Product2.ProductCode, pbe);
            }
            // 3. Upsert OrderItems for the order
            List<OrderItem> existingOrderItems = [
                SELECT Id, Product2Id, PricebookEntryId, Product2.ProductCode
                FROM OrderItem
                WHERE OrderId = :orderId
            ];
            Map<String, OrderItem> codeToOrderItem = new Map<String, OrderItem>();
            for (OrderItem oi : existingOrderItems) {
                if (oi.Product2 != null && oi.Product2.ProductCode != null) {
                    codeToOrderItem.put(oi.Product2.ProductCode, oi);
                }
            }
            List<OrderItem> toInsertOrderItems = new List<OrderItem>();
            List<OrderItem> toUpdateOrderItems = new List<OrderItem>();
            Set<String> keepCodes = new Set<String>();
            for (String code : codes) {
                Product2 prod = codeToProduct.get(code);
                PricebookEntry pbe = codeToPBE.get(code);
                Map<String, Object> item = codeToItem.get(code);
                Decimal price = (Decimal) item.get('price');
                OrderItem oi = codeToOrderItem.get(code);
                if (oi == null) {
                    oi = new OrderItem();
                    oi.OrderId = orderId;
                    oi.Product2Id = prod.Id;
                    oi.PricebookEntryId = pbe.Id;
                    oi.Quantity = 1;
                    oi.UnitPrice = price;
                    oi.POE_Status__c = 'Draft';
                    toInsertOrderItems.add(oi);
                } else {
                    oi.UnitPrice = price;
                    oi.POE_Status__c = 'Draft';
                    toUpdateOrderItems.add(oi);
                }
                keepCodes.add(code);
            }
            if (!toInsertOrderItems.isEmpty())
                insert toInsertOrderItems;
            if (!toUpdateOrderItems.isEmpty())
                update toUpdateOrderItems;
            // Remove OrderItems not in the list
            List<OrderItem> toDelete = new List<OrderItem>();
            for (OrderItem oi : existingOrderItems) {
                if (!keepCodes.contains(oi.Product2.ProductCode)) {
                    toDelete.add(oi);
                }
            }
            if (!toDelete.isEmpty()) {
                delete toDelete;
            }

            Order ord = [SELECT Id, DSL_Migration__c FROM Order WHERE Id = :orderId LIMIT 1];
            if (ord.DSL_Migration__c != dsl) {
                ord.DSL_Migration__c = dsl;
                dslFlagUpdate = true;
                update ord;
            }

            response.result = new Map<String, Object>{
                'success' => true,
                'upsertedOrderItemCount' => (toInsertOrderItems.size() + toUpdateOrderItems.size()),
                'deletedOrderItemCount' => toDelete.size(),
                'dslFlagUpdate' => dslFlagUpdate
            };
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class ResponseWrapper {
        @AuraEnabled
        public Map<String, Object> result;
    }
}
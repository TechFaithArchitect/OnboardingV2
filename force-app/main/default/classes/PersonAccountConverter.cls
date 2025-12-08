global class PersonAccountConverter {
    global static void convertMethod(List<Account> accToConvert) {
        Id personAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('PersonAccount')
            .getRecordTypeId();
        Id orderRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName()
            .get('StandardOrder')
            .getRecordTypeId();

        Map<String, List<Order>> orderListByAccId = new Map<String, List<Order>>();
        List<OrderItem> orderItemToInsert = new List<OrderItem>();

        List<Account> accToInsert = new List<Account>();
        List<Order> ordToInsert = new List<Order>();
        List<Order> orderToUpdate = new List<Order>();
        List<Contact> contactsList = new List<Contact>();
        List<String> ordIdList = new List<String>();
        Map<String, List<Account>> newAccountByOldAccId = new Map<String, List<Account>>();
        Map<String, List<OrderItem>> orderItemsListByOrderId = new Map<String, List<OrderItem>>();
        Map<String, List<Order>> newOrdeByOldOrder = new Map<String, List<Order>>();
        Map<String, Account> accountsWithContactByAccId = new Map<String, Account>();
        for (Account acc : accToConvert) {
            if (!acc.Contacts.isEmpty()) {
                accountsWithContactByAccId.put(acc.id, acc);
                contactsList.addAll(acc.Contacts);
            } else {
                Account newAcc = new Account(
                    RecordTypeId = personAccRecordTypeId,
                    Old_AccountId__c = acc.id,
                    LastName = acc.Name,
                    BillingStreet = acc.BillingStreet,
                    BillingCity = acc.BillingCity,
                    BillingState = acc.BillingState,
                    BillingCountry = acc.BillingCountry,
                    BillingPostalCode = acc.BillingPostalCode,
                    ShippingStreet = acc.ShippingStreet,
                    ShippingCity = acc.ShippingCity,
                    ShippingState = acc.ShippingState,
                    ShippingPostalCode = acc.ShippingPostalCode,
                    ShippingCountry = acc.ShippingCountry,
                    Phone = acc.Phone,
                    POE_Require_TPV__c = acc.POE_Require_TPV__c,
                    vlocity_cmt__PremisesId__c = acc.vlocity_cmt__PremisesId__c,
                    POE_Dealer_Code__c = acc.POE_Dealer_Code__c,
                    POE_ICL_Owner__c = acc.POE_ICL_Owner__c,
                    POE_Office_Start_Date__c = acc.POE_Office_Start_Date__c,
                    POE_Active_In_SF__c = acc.POE_Active_In_SF__c,
                    POE_Bonus_Start_Date__c = acc.POE_Bonus_Start_Date__c,
                    POE_Office_Close_Date__c = acc.POE_Office_Close_Date__c,
                    POE_Status_Reason__c = acc.POE_Status_Reason__c,
                    POE_Dealer_Office_Email__c = acc.POE_Dealer_Office_Email__c,
                    POE_Secondary_Phone__c = acc.POE_Secondary_Phone__c,
                    Division__c = acc.Division__c,
                    Region__c = acc.Region__c,
                    Territory__c = acc.Territory__c,
                    Company_ID__c = acc.Company_ID__c,
                    vlocity_cmt__BillFrequency__c = acc.vlocity_cmt__BillFrequency__c,
                    vlocity_cmt__AccountPaymentType__c = acc.vlocity_cmt__AccountPaymentType__c,
                    vlocity_cmt__EnableAutopay__c = acc.vlocity_cmt__EnableAutopay__c,
                    vlocity_cmt__BillDeliveryMethod__c = acc.vlocity_cmt__BillDeliveryMethod__c,
                    vlocity_cmt__BillingEmailAddress__c = acc.vlocity_cmt__BillingEmailAddress__c,
                    vlocity_cmt__AutoPaymentMethodId__c = acc.vlocity_cmt__AutoPaymentMethodId__c,
                    vlocity_cmt__AutoPaymentAmount__c = acc.vlocity_cmt__AutoPaymentAmount__c,
                    vlocity_cmt__CLTV__c = acc.vlocity_cmt__CLTV__c,
                    vlocity_cmt__Churn__c = acc.vlocity_cmt__Churn__c,
                    POE_Programs_available__c = acc.POE_Programs_available__c,
                    POE_Programs_Available__pc = acc.POE_Programs_Available__pc,
                    vlocity_cmt__DirectoryListed__c = acc.vlocity_cmt__DirectoryListed__c,
                    vlocity_cmt__ContactPreferences__c = acc.vlocity_cmt__ContactPreferences__c,
                    ParentId = acc.ParentId,
                    vlocity_cmt__SLA__c = acc.vlocity_cmt__SLA__c,
                    vlocity_cmt__vSLA__c = acc.vlocity_cmt__vSLA__c,
                    vlocity_cmt__Status__c = acc.vlocity_cmt__Status__c,
                    vlocity_cmt__Status__pc = acc.vlocity_cmt__Status__pc,
                    OwnerId = acc.OwnerId
                );

                accToInsert.add(newAcc);
                if (!acc.Orders.isEmpty()) {
                    orderListByAccId.put(acc.id, acc.Orders);
                }
            }
        }

        for (Contact con : contactsList) {
            Account acc = accountsWithContactByAccId.get(con.AccountId);

            Account newAcc = new Account(
                RecordTypeId = personAccRecordTypeId,
                Salutation = con.Salutation,
                Old_AccountId__c = acc.id,
                FirstName = con.FirstName,
                MiddleName = con.MiddleName,
                LastName = con.LastName != null ? con.LastName : acc.LastName,
                Suffix = con.Suffix,
                Phone = con.Phone,
                BillingStreet = acc.BillingStreet,
                BillingCity = acc.BillingCity,
                BillingState = acc.BillingState,
                BillingCountry = acc.BillingCountry,
                BillingPostalCode = acc.BillingPostalCode,
                vlocity_cmt__CustomerPriority__c = acc.vlocity_cmt__CustomerPriority__c,
                vlocity_cmt__vCustomerPriority__c = acc.vlocity_cmt__vCustomerPriority__c,
                ShippingStreet = acc.ShippingStreet,
                ShippingCity = acc.ShippingCity,
                ShippingState = acc.ShippingState,
                ShippingPostalCode = acc.ShippingPostalCode,
                ShippingCountry = acc.ShippingCountry,
                POE_Require_TPV__c = acc.POE_Require_TPV__c,
                vlocity_cmt__PremisesId__c = acc.vlocity_cmt__PremisesId__c,
                POE_Dealer_Code__c = acc.POE_Dealer_Code__c,
                POE_ICL_Owner__c = acc.POE_ICL_Owner__c,
                POE_Office_Start_Date__c = acc.POE_Office_Start_Date__c,
                POE_Active_In_SF__c = acc.POE_Active_In_SF__c,
                POE_Bonus_Start_Date__c = acc.POE_Bonus_Start_Date__c,
                POE_Office_Close_Date__c = acc.POE_Office_Close_Date__c,
                POE_Status_Reason__c = acc.POE_Status_Reason__c,
                POE_Dealer_Office_Email__c = acc.POE_Dealer_Office_Email__c,
                POE_Secondary_Phone__c = acc.POE_Secondary_Phone__c,
                Division__c = acc.Division__c,
                Region__c = acc.Region__c,
                Territory__c = acc.Territory__c,
                Company_ID__c = acc.Company_ID__c,
                vlocity_cmt__BillFrequency__c = acc.vlocity_cmt__BillFrequency__c,
                vlocity_cmt__AccountPaymentType__c = acc.vlocity_cmt__AccountPaymentType__c,
                vlocity_cmt__EnableAutopay__c = acc.vlocity_cmt__EnableAutopay__c,
                vlocity_cmt__BillDeliveryMethod__c = acc.vlocity_cmt__BillDeliveryMethod__c,
                vlocity_cmt__BillingEmailAddress__c = acc.vlocity_cmt__BillingEmailAddress__c,
                vlocity_cmt__AutoPaymentMethodId__c = acc.vlocity_cmt__AutoPaymentMethodId__c,
                vlocity_cmt__AutoPaymentAmount__c = acc.vlocity_cmt__AutoPaymentAmount__c,
                vlocity_cmt__CLTV__c = acc.vlocity_cmt__CLTV__c,
                vlocity_cmt__Churn__c = acc.vlocity_cmt__Churn__c,
                POE_Programs_available__c = acc.POE_Programs_available__c,
                POE_Programs_Available__pc = acc.POE_Programs_Available__pc,
                vlocity_cmt__DirectoryListed__c = acc.vlocity_cmt__DirectoryListed__c,
                vlocity_cmt__ContactPreferences__c = acc.vlocity_cmt__ContactPreferences__c,
                ParentId = acc.ParentId,
                vlocity_cmt__SLA__c = acc.vlocity_cmt__SLA__c,
                vlocity_cmt__vSLA__c = acc.vlocity_cmt__vSLA__c,
                vlocity_cmt__Status__c = acc.vlocity_cmt__Status__c,
                vlocity_cmt__Status__pc = acc.vlocity_cmt__Status__pc,
                OwnerId = acc.OwnerId
            );

            accToInsert.add(newAcc);
            if (!acc.Orders.isEmpty()) {
                orderListByAccId.put(acc.id, acc.Orders);
            }
        }

        insert accToInsert;

        for (Account newAcc : accToInsert) {
            List<Order> orderList = orderListByAccId.get(newAcc.Old_AccountId__c);
            if (orderList != null) {
                for (Order ord : orderList) {
                    Order ordClone = new Order();

                    ordClone.AccountId = newAcc.id;
                    ordClone.Old_OrderId__c = ord.id;
                    ordClone.RecordTypeId = ord.RecordTypeId != null ? ord.RecordTypeId : orderRecordTypeId;
                    ordClone.Type = ord.Type;
                    ordClone.POE_Dealer__c = ord.POE_Dealer__c;
                    ordClone.EffectiveDate = ord.EffectiveDate;
                    ordClone.Pricebook2Id = ord.Pricebook2Id;
                    ordClone.ShippingStreet = ord.ShippingStreet;
                    ordClone.ShippingPostalCode = ord.ShippingPostalCode;
                    ordClone.ShippingCountry = ord.ShippingCountry;
                    ordClone.ShippingCity = ord.ShippingCity;
                    ordClone.ShippingState = ord.ShippingState;
                    if (ord.Status == 'Activated') {
                        ordClone.Status = 'Draft';
                        ordClone.isActive__c = true;
                    } else {
                        ordClone.Status = ord.Status;
                    }

                    ordToInsert.add(ordClone);
                    ordIdList.add(ord.id);
                }
            }
        }

        for (Order ord : [
            SELECT
                Id,
                (SELECT Id, Quantity, OrderId, PricebookEntryId, ListPrice, UnitPrice, Product2Id FROM OrderItems)
            FROM Order
            WHERE Id IN :ordIdList
        ]) {
            orderItemsListByOrderId.put(ord.id, ord.OrderItems);
        }

        insert ordToinsert;

        for (Order ord : ordToinsert) {
            List<OrderItem> OrderItemList = orderItemsListByOrderId.get(ord.Old_OrderId__c);
            if (OrderItemList != null) {
                for (OrderItem ordI : OrderItemList) {
                    OrderItem ordItemClone = new OrderItem(
                        OrderId = ord.Id,
                        Quantity = ordI.Quantity,
                        UnitPrice = ordI.UnitPrice,
                        Product2Id = ordI.Product2Id,
                        PricebookEntryId = ordI.PricebookEntryId
                    );
                    orderItemToInsert.add(ordItemClone);
                }
            }
        }
        insert orderItemToInsert;

        for (Order ord : [SELECT Id, Status FROM Order WHERE isActive__c = TRUE]) {
            ord.Status = 'Activated';
            orderToUpdate.add(ord);
        }
        update orderToUpdate;
    }
}
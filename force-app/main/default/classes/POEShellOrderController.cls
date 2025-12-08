public without sharing class POEShellOrderController {
    @AuraEnabled(cacheable=false)
    public static InitialData getInitialData(String recordId) {
        List<String> programs = new List<String>();
        List<String> reasons = new List<String>();
        List<Order> orders = new List<Order>();
        List<Contact> orderContact = new List<Contact>();
        List<OrderItem> orderItem = new List<OrderItem>();
        Contact cont = new Contact();
        OrderItem prod = new OrderItem();
        Order ord = new Order();

        Schema.DescribeFieldResult fieldResult = Account.POE_Programs_available__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry pickListVal : ple) {
            programs.add(pickListVal.getLabel());
        }
        Schema.DescribeFieldResult fieldResult2 = Order.POE_ShellReason__c.getDescribe();
        List<Schema.PicklistEntry> ple2 = fieldResult2.getPicklistValues();
        for (Schema.PicklistEntry pickListVal : ple2) {
            reasons.add(pickListVal.getLabel());
        }

        orders = [
            SELECT
                Id,
                OrderNumber,
                AccountId,
                Account.Phone,
                Account.POE_Secondary_Phone__c,
                POE_BAN__c,
                POE_InstallationDate__c
            FROM Order
            WHERE OpportunityId = :recordId
        ];
        if (!orders.isEmpty()) {
            ord = orders[0];
            orderContact = [SELECT FirstName, LastName FROM Contact WHERE AccountId = :ord.AccountId];
            if (!orderContact.isEmpty()) {
                cont = orderContact[0];
            }
            orderItem = [SELECT Product2.Name, Product2.Family FROM OrderItem WHERE OrderId = :ord.Id];
            if (!orderItem.isEmpty()) {
                prod = orderItem[0];
            }
        }

        initialData data = new initialData();
        data.programValues = programs;
        data.reasonValues = reasons;
        data.order = ord;
        data.contact = cont;
        data.product = prod;
        return data;
    }

    @AuraEnabled(cacheable=false)
    public static Order saveData(
        String firstName,
        String lastName,
        String oppId,
        String middleName,
        String phone,
        String secondaryPhone,
        String ban,
        String installationDate,
        String reason,
        String recType
    ) {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE Id = :oppId LIMIT 1];
        Pricebook2 pb2 = [SELECT Id, Name, IsActive FROM PriceBook2 WHERE IsStandard = TRUE LIMIT 1];
        Id consRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Consumer').getRecordTypeId();
        String fullName = firstName + ' ' + lastName;
        List<Account> existingAccounts = [SELECT Id, Phone FROM Account WHERE Name = :fullName];
        Account acc = new Account();
        if (!existingAccounts.isEmpty()) {
            acc = existingAccounts[0];
            acc.Phone = phone;
            acc.POE_Secondary_Phone__c = secondaryPhone;
            acc.RecordTypeId = consRecordTypeId;
            update acc;
            opp.AccountId = acc.Id;
            update opp;
        } else {
            acc.Name = fullName;
            acc.Phone = phone;
            acc.POE_Secondary_Phone__c = secondaryPhone;
            acc.RecordTypeId = consRecordTypeId;
            insert acc;
            opp.AccountId = acc.Id;
            update opp;
        }
        List<Contact> existingContacts = [
            SELECT Id, Phone
            FROM Contact
            WHERE FirstName = :firstName AND LastName = :lastName
        ];
        Contact cont = new Contact();
        if (!existingContacts.isEmpty()) {
            cont = existingContacts[0];
            cont.AccountId = acc.Id;
            update cont;
        } else {
            cont.AccountId = acc.Id;
            cont.FirstName = firstName;
            cont.LastName = lastName;
            insert cont;
        }

        Order order = new Order();
        order.OpportunityId = oppId;
        order.AccountId = acc.Id;
        order.POE_InstallationDate__c = Date.valueOf(installationDate);
        order.POE_ShellReason__c = reason;
        order.POE_BAN__c = ban;
        order.Type = 'Call Center';
        order.Status = 'Pending Installation';
        order.RecordTypeId = recType;
        order.Pricebook2Id = pb2.Id;
        order.EffectiveDate = System.today();
        insert order;

        order = [SELECT OrderNumber FROM Order WHERE Id = :order.Id LIMIT 1];

        return order;
    }

    public class InitialData {
        @AuraEnabled
        public List<String> programValues;
        @AuraEnabled
        public List<String> reasonValues;
        @AuraEnabled
        public Order order;
        @AuraEnabled
        public Contact contact;
        @AuraEnabled
        public OrderItem product;
    }
}
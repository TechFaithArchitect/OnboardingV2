global with sharing class PersonAccountConverterBatch implements Database.Batchable<sObject>, Database.Stateful {
    global Account[] start(Database.BatchableContext bc) {
        return [
            SELECT
                Id,
                Name,
                FirstName,
                LastName,
                BillingStreet,
                BillingCity,
                BillingState,
                BillingCountry,
                BillingPostalCode,
                vlocity_cmt__CustomerPriority__c,
                vlocity_cmt__vCustomerPriority__c,
                ShippingStreet,
                ShippingCity,
                ShippingState,
                ShippingPostalCode,
                ShippingCountry,
                Phone,
                POE_Require_TPV__c,
                vlocity_cmt__PremisesId__c,
                POE_Dealer_Code__c,
                POE_ICL_Owner__c,
                POE_Office_Start_Date__c,
                POE_Active_In_SF__c,
                POE_Bonus_Start_Date__c,
                POE_Office_Close_Date__c,
                POE_Status_Reason__c,
                POE_Dealer_Office_Email__c,
                POE_Secondary_Phone__c,
                Division__c,
                Region__c,
                Territory__c,
                Company_ID__c,
                vlocity_cmt__BillFrequency__c,
                vlocity_cmt__AccountPaymentType__c,
                vlocity_cmt__EnableAutopay__c,
                vlocity_cmt__BillDeliveryMethod__c,
                vlocity_cmt__BillingEmailAddress__c,
                vlocity_cmt__AutoPaymentMethodId__c,
                vlocity_cmt__AutoPaymentAmount__c,
                vlocity_cmt__CLTV__c,
                vlocity_cmt__Churn__c,
                POE_Programs_available__c,
                POE_Programs_Available__pc,
                vlocity_cmt__DirectoryListed__c,
                vlocity_cmt__ContactPreferences__c,
                ParentId,
                vlocity_cmt__SLA__c,
                vlocity_cmt__vSLA__c,
                vlocity_cmt__Status__c,
                vlocity_cmt__Status__pc,
                OwnerId,
                (
                    SELECT
                        Id,
                        Pricebook2Id,
                        AccountId,
                        POE_Dealer__c,
                        RecordTypeId,
                        Type,
                        EffectiveDate,
                        Status,
                        ShippingStreet,
                        ShippingPostalCode,
                        ShippingCountry,
                        ShippingCity,
                        ShippingState
                    FROM Orders
                ),
                (
                    SELECT
                        Id,
                        Name,
                        Salutation,
                        FirstName,
                        MiddleName,
                        vlocity_cmt__MiddleName__c,
                        LastName,
                        Suffix,
                        Email,
                        Phone,
                        AccountId,
                        Title
                    FROM Contacts
                )
            FROM Account
            WHERE RecordType.Name = 'Consumer'
        ];
    }

    global void execute(Database.BatchableContext bc, Account[] scope) {
        PersonAccountConverter.convertMethod(scope);
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('PersonAccountConverterBatch finish');
    }
}
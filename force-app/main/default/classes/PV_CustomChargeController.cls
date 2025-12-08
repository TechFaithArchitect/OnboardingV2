public with sharing class PV_CustomChargeController {
    
    @AuraEnabled(cacheable=true)
    public static FSL_AppUtils.ResponseWrapper getAllProducts() {
        
        try {
            
            Map<String, List<CustomCharge_Products__c>> productMap = new Map<String, List<CustomCharge_Products__c>>();

            for (CustomCharge_Products__c product : [SELECT Name, Id, Price__c, Vendor__c FROM CustomCharge_Products__c]) {
                if (!productMap.containsKey(product.Vendor__c)) {
                    productMap.put(product.Vendor__c, new List<CustomCharge_Products__c>());
                }
                productMap.get(product.Vendor__c).add(product);
            }
    
            return new FSL_AppUtils.ResponseWrapper('SUCCESS', productMap, null);
            
        }catch(Exception e) {
            return new FSL_AppUtils.ResponseWrapper('ERROR', null, e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static FSL_AppUtils.ResponseWrapper getProductPrice() {

        try {
            return new FSL_AppUtils.ResponseWrapper('SUCCESS', [SELECT Id, Name, Price__c FROM CustomCharge_Products__c], null);
        }catch(Exception e) {
            return new FSL_AppUtils.ResponseWrapper('ERROR', null, e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<Custom_Charge__c> getCustomCharge(String saId) {
        return [
            SELECT  Id, Quantity__c, Price__c, Total_Amount__c, Vendor__c, Allow_Override_Price__c
            FROM    Custom_Charge__c
            WHERE   Service_Appointment__c = :saId
        ];
    }
    
    @AuraEnabled
    public static List<ServiceAppointment> getSAAmount(String saId) {
        return [SELECT Id, Total_Amount__c FROM ServiceAppointment WHERE Id = :saId];
    }

    @AuraEnabled
    public static FSL_AppUtils.ResponseWrapper getVendors(Id serviceAppointmentId) {

        try {

            List<VendorValue> result = new List<VendorValue>();
        
            ServiceAppointment serviceAppointment = [
                SELECT  Dealer__r.Available_FSL_Vendors__c 
                FROM    ServiceAppointment 
                WHERE   Id = :serviceAppointmentId
                LIMIT 1
            ];
            
            if (serviceAppointment.Dealer__r != null && String.isNotBlank(serviceAppointment.Dealer__r.Available_FSL_Vendors__c)) {
                List<String> values = serviceAppointment.Dealer__r.Available_FSL_Vendors__c.split(';');
                
                for (String value : values) {
                    VendorValue newVendor = new VendorValue();
                    newVendor.label = newVendor.value = value;
                    result.add(newVendor);
                }
            } else {
                throw new AuraHandledException('The service appointment is not assigned to an FSL Dealer.');
            }

            return new FSL_AppUtils.ResponseWrapper('SUCCESS', result, null);

        }catch(Exception e) {
            return new FSL_AppUtils.ResponseWrapper('ERROR', null, e.getMessage());
        }
    }

    public class VendorValue {
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String value {get; set;}
    }
    
}
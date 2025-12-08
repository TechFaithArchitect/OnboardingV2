/**
 * Utility class for retrieving picklist values
 * Eliminates code duplication and provides consistent picklist handling
 */
public with sharing class PicklistHelper {
    
    /**
     * Gets picklist values for a field using schema describe
     * @param objectApiName The API name of the object (e.g., 'Vendor_Program_Group__c')
     * @param fieldApiName The API name of the field (e.g., 'Logic_Type__c')
     * @return List of maps with 'label' and 'value' keys
     */
    public static List<Map<String, String>> getPicklistValues(String objectApiName, String fieldApiName) {
        List<Map<String, String>> options = new List<Map<String, String>>();
        
        try {
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectApiName);
            if (sObjectType == null) {
                return options;
            }
            
            Schema.DescribeSObjectResult objectDescribe = sObjectType.getDescribe();
            Schema.SObjectField field = objectDescribe.fields.getMap().get(fieldApiName);
            
            if (field == null) {
                return options;
            }
            
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            List<Schema.PicklistEntry> picklistValues = fieldDescribe.getPicklistValues();
            
            for (Schema.PicklistEntry entry : picklistValues) {
                if (entry.isActive()) {
                    options.add(new Map<String, String>{
                        'label' => entry.getLabel(),
                        'value' => entry.getValue()
                    });
                }
            }
        } catch (Exception e) {
            System.debug('Error getting picklist values for ' + objectApiName + '.' + fieldApiName + ': ' + e.getMessage());
        }
        
        return options;
    }
    
    /**
     * Gets picklist values for a field with fallback values
     * @param objectApiName The API name of the object
     * @param fieldApiName The API name of the field
     * @param fallbackValues List of fallback values to use if schema describe fails
     * @return List of maps with 'label' and 'value' keys
     */
    public static List<Map<String, String>> getPicklistValuesWithFallback(
        String objectApiName, 
        String fieldApiName, 
        List<String> fallbackValues
    ) {
        List<Map<String, String>> options = getPicklistValues(objectApiName, fieldApiName);
        
        // If no values found, use fallback
        if (options.isEmpty() && fallbackValues != null) {
            for (String value : fallbackValues) {
                options.add(new Map<String, String>{
                    'label' => value,
                    'value' => value
                });
            }
        }
        
        return options;
    }
    
    /**
     * Gets picklist values for a field using direct field reference (faster for known types)
     * @param fieldToken The field token (e.g., Vendor_Program_Group__c.Logic_Type__c)
     * @param fallbackValues Optional fallback values if schema describe fails
     * @return List of maps with 'label' and 'value' keys
     */
    public static List<Map<String, String>> getPicklistValuesByField(
        Schema.SObjectField fieldToken, 
        List<String> fallbackValues
    ) {
        List<Map<String, String>> options = new List<Map<String, String>>();
        
        try {
            Schema.DescribeFieldResult fieldDescribe = fieldToken.getDescribe();
            List<Schema.PicklistEntry> picklistValues = fieldDescribe.getPicklistValues();
            
            for (Schema.PicklistEntry entry : picklistValues) {
                if (entry.isActive()) {
                    options.add(new Map<String, String>{
                        'label' => entry.getLabel(),
                        'value' => entry.getValue()
                    });
                }
            }
        } catch (Exception e) {
            System.debug('Error getting picklist values: ' + e.getMessage());
        }
        
        // If no values found and fallback provided, use fallback
        if (options.isEmpty() && fallbackValues != null) {
            for (String value : fallbackValues) {
                options.add(new Map<String, String>{
                    'label' => value,
                    'value' => value
                });
            }
        }
        
        return options;
    }
}
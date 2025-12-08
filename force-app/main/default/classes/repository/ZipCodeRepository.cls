public with sharing class ZipCodeRepository {
    /**
     * Fetches Zip_Code__c records by Name (5-digit ZIP).
     * @param zipNames set of ZIP strings
     * @return list of Zip_Code__c with Id and Name
     */
    public static List<Zip_Code__c> getByPostalCodes(Set<String> postalCodes) {
        if (postalCodes == null || postalCodes.isEmpty()) {
            return new List<Zip_Code__c>();
        }

        Schema.DescribeSObjectResult describe = Zip_Code__c.SObjectType.getDescribe();
        Map<String, Schema.SObjectField> fields = describe.fields.getMap();
        Boolean hasPostalField = fields.containsKey('Postal_Code__c');
        Boolean hasDelField = fields.containsKey('Zip_Code_del__c'); // source of truth for 5-digit ZIP

        List<String> selects = new List<String>{ 'Id', 'Name' };
        if (hasPostalField) {
            selects.add('Postal_Code__c');
        }
        if (hasDelField) {
            selects.add('Zip_Code_del__c');
        }

        List<String> conditions = new List<String>();
        if (hasDelField) {
            conditions.add('Zip_Code_del__c IN :postalCodes');
        }
        if (hasPostalField) {
            conditions.add('Postal_Code__c IN :postalCodes');
        }
        conditions.add('Name IN :postalCodes');

        String soql = 'SELECT ' + String.join(selects, ', ')
            + ' FROM Zip_Code__c WHERE ' + String.join(conditions, ' OR ');

        return Database.query(soql);
    }
}

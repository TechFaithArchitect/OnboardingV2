/**
 * Test data factory for Zip Code and Zip Code Territory junction objects
 * Supports creating test data for the new junction-based territory model
 */
@IsTest
public class TestZipCodeFactory {
    
    /**
     * Creates a Zip Code record
     * @param doInsert Whether to insert the record immediately
     * @param postalCode Optional postal code (defaults to '12345')
     * @return Zip_Code__c record
     * 
     * NOTE: Account, Contact, Lead have lookup fields TO Zip Code (not the other way around).
     * So Account.Zip_Code__c links to Zip_Code__c. Zip_Code__c does NOT have Account__c field.
     */
    public static Zip_Code__c createZipCode(Boolean doInsert, String postalCode) {
        Zip_Code__c zipCode = new Zip_Code__c();
        
        // If postal code field exists, set it
        if (String.isNotBlank(postalCode)) {
            Schema.DescribeSObjectResult describe = Zip_Code__c.SObjectType.getDescribe();
            Map<String, Schema.SObjectField> fields = describe.fields.getMap();
            if (fields.containsKey('Postal_Code__c')) {
                zipCode.put('Postal_Code__c', postalCode);
            }
            if (fields.containsKey('Zip_Code_del__c')) {
                zipCode.put('Zip_Code_del__c', postalCode);
            }
        }
        
        TestDataFactoryUtil.maybeInsert(zipCode, doInsert);
        return zipCode;
    }
    
    /**
     * Creates a Zip Code record with default values
     * @param doInsert Whether to insert the record immediately
     * @return Zip_Code__c record
     */
    public static Zip_Code__c createZipCode(Boolean doInsert) {
        return createZipCode(doInsert, '12345');
    }
    
    /**
     * Creates a Zip Code record (backwards compatibility method - DEPRECATED)
     * 
     * NOTE: This method is kept for backwards compatibility only.
     * Account should link to Zip Code via Account.Zip_Code__c, not Zip_Code__c.Account__c.
     * Use createZipCode(Boolean doInsert, String postalCode) instead.
     * 
     * @param doInsert Whether to insert the record immediately
     * @param accountId DEPRECATED: This parameter is ignored. Account should have Zip_Code__c lookup.
     * @param postalCode Optional postal code (defaults to '12345')
     * @return Zip_Code__c record
     */
    public static Zip_Code__c createZipCode(Boolean doInsert, Id accountId, String postalCode) {
        // Ignore accountId - Account should link to Zip Code, not the other way around
        // This method is kept for backwards compatibility only
        return createZipCode(doInsert, postalCode);
    }
    
    /**
     * Creates a Zip Code Territory junction record linking a Territory Assignment to a Zip Code
     * @param doInsert Whether to insert the record immediately
     * @param territoryAssignmentId Territory Assignment ID
     * @param zipCodeId Zip Code ID
     * @return Zip_Code_Territory__c junction record
     */
    public static Zip_Code_Territory__c createZipCodeTerritory(
        Boolean doInsert, 
        Id territoryAssignmentId, 
        Id zipCodeId
    ) {
        if (territoryAssignmentId == null || zipCodeId == null) {
            throw new IllegalArgumentException('Territory Assignment ID and Zip Code ID are required');
        }
        
        Zip_Code_Territory__c junction = new Zip_Code_Territory__c(
            Territory_Assignments__c = territoryAssignmentId,
            Zip_Code__c = zipCodeId
        );
        
        TestDataFactoryUtil.maybeInsert(junction, doInsert);
        return junction;
    }
    
    /**
     * Creates a complete test setup: Territory Assignment → Junction → Zip Code → Account
     * @param doInsert Whether to insert all records
     * @param territoryAssignment Territory Assignment record
     * @param account Account record to link to Zip Code
     * @return Wrapper containing all created records
     */
    public static ZipCodeTerritorySetupWrapper createCompleteSetup(
        Boolean doInsert,
        Territory_Assignments__c territoryAssignment,
        Account account
    ) {
        if (territoryAssignment == null || account == null) {
            throw new IllegalArgumentException('Territory Assignment and Account are required');
        }
        
        // Ensure territory assignment is inserted if needed
        if (territoryAssignment.Id == null && doInsert) {
            insert territoryAssignment;
        }
        
        // Ensure account is inserted if needed
        if (account.Id == null && doInsert) {
            insert account;
        }
        
        // Create Zip Code (Account will link to it via Account.Zip_Code__c)
        Zip_Code__c zipCode = createZipCode(doInsert, '12345');
        
        // Link Account to Zip Code (Account has lookup TO Zip Code)
        account.Zip_Code__c = zipCode.Id;
        if (doInsert) {
            // If account wasn't inserted yet, insert it now with Zip_Code__c set
            if (account.Id == null) {
                insert account;
            } else {
                update account;
            }
        }
        
        // Create Junction linking Territory Assignment to Zip Code
        Zip_Code_Territory__c junction = createZipCodeTerritory(
            doInsert, 
            territoryAssignment.Id, 
            zipCode.Id
        );
        
        return new ZipCodeTerritorySetupWrapper(territoryAssignment, zipCode, junction, account);
    }
    
    /**
     * Wrapper class for complete Zip Code Territory setup
     */
    public class ZipCodeTerritorySetupWrapper {
        public Territory_Assignments__c territoryAssignment;
        public Zip_Code__c zipCode;
        public Zip_Code_Territory__c junction;
        public Account account;
        
        public ZipCodeTerritorySetupWrapper(
            Territory_Assignments__c ta,
            Zip_Code__c zc,
            Zip_Code_Territory__c j,
            Account acc
        ) {
            this.territoryAssignment = ta;
            this.zipCode = zc;
            this.junction = j;
            this.account = acc;
        }
    }
}

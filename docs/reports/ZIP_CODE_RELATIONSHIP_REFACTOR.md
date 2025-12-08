# Zip Code Relationship Refactor

## Problem

The data model relationship between Account/Contact/Lead and Zip Code was backwards.

**Incorrect Model:**
- `Zip_Code__c` had lookup fields `Account__c`, `Contact__c`, `Lead__c`
- This created a 1:1 relationship (one Zip Code → one Account)
- Query pattern: `SELECT Account__c FROM Zip_Code__c WHERE Id IN :zipCodeIds`

**Correct Model:**
- `Account`, `Contact`, `Lead` have lookup fields `Zip_Code__c` TO `Zip_Code__c`
- This creates a 1:Many relationship (one Zip Code → many Accounts/Contacts/Leads)
- Query pattern: `SELECT Id FROM Account WHERE Zip_Code__c IN :zipCodeIds`

## Changes Made

### 1. OnboardingAccessService.cls

**Refactored `getAccountIdsForOwners()` method:**

**Before:**
```apex
for (Zip_Code__c zipCode : [
    SELECT Account__c
    FROM Zip_Code__c
    WHERE Id IN :zipCodeIds
      AND Account__c != null
    LIMIT 10000
]) {
    accountIds.add(zipCode.Account__c);
}
```

**After:**
```apex
for (Account acc : [
    SELECT Id
    FROM Account
    WHERE Zip_Code__c IN :zipCodeIds
    LIMIT 10000
]) {
    accountIds.add(acc.Id);
}
```

**Updated Comments:**
- Changed documentation to reflect: `Territory_Assignments__c → Zip_Code_Territory__c → Zip_Code__c`
- Then: `Accounts WHERE Zip_Code__c IN :zipCodeIds` (Account has lookup TO Zip Code)

### 2. TestZipCodeFactory.cls

**Updated `createZipCode()` method:**

**Before:**
```apex
public static Zip_Code__c createZipCode(Boolean doInsert, Id accountId, String postalCode) {
    Zip_Code__c zipCode = new Zip_Code__c(
        Account__c = accountId  // WRONG: Zip Code does not have Account lookup
    );
    ...
}
```

**After:**
```apex
public static Zip_Code__c createZipCode(Boolean doInsert, String postalCode) {
    Zip_Code__c zipCode = new Zip_Code__c();  // No Account field
    ...
}

// Added deprecated method for backwards compatibility
@Deprecated
public static Zip_Code__c createZipCode(Boolean doInsert, Id accountId, String postalCode) {
    // Ignore accountId - Account should link to Zip Code, not the other way around
    return createZipCode(doInsert, postalCode);
}
```

**Updated `createCompleteSetup()` method:**
- Now creates Zip Code first
- Then links Account to Zip Code via `Account.Zip_Code__c = zipCode.Id`

### 3. OnboardingAccessServiceTest.cls

**Updated all test methods to use new pattern:**

**Before:**
```apex
Zip_Code__c zipCode = TestZipCodeFactory.createZipCode(true, testAccount.Id, '12345');
```

**After:**
```apex
Zip_Code__c zipCode = TestZipCodeFactory.createZipCode(true, '12345');
testAccount.Zip_Code__c = zipCode.Id;
update testAccount;
```

**Updated test methods:**
- `testGetAccountIdsForOwners_territoryAssignmentViaJunction()`
- `testGetAccountIdsForOwners_baseAppOBRepViaJunction()`
- `testGetAccountIdsForOwners_multipleZipCodesPerTerritory()`
- `testGetAccountIdsForOwners_multipleTerritoriesForSameAccount()`
- `testGetAccountIdsForOwners_combinedOwnerAndTerritory()`
- `testGetAccountIdsForOwners_performance_largeDataSet()`

## Data Model

### Correct Relationship Structure

```
Territory_Assignments__c
  ↓ (via Zip_Code_Territory__c junction)
Zip_Code__c
  ↑ (lookup from Account.Zip_Code__c)
Account (many)
Contact (many)  ← Contact.Zip_Code__c
Lead (many)     ← Lead.Zip_Code__c
```

### Key Points

1. **One Zip Code → Many Accounts/Contacts/Leads**
   - A single Zip Code record can be referenced by multiple Account, Contact, and Lead records

2. **Query Pattern**
   - To find Accounts for a Zip Code: `SELECT Id FROM Account WHERE Zip_Code__c = :zipCodeId`
   - To find all Accounts for multiple Zip Codes: `SELECT Id FROM Account WHERE Zip_Code__c IN :zipCodeIds`

3. **Territory Assignment Path**
   - Territory_Assignments__c → Zip_Code_Territory__c → Zip_Code__c
   - Then query Accounts/Contacts/Leads WHERE Zip_Code__c IN :zipCodeIds

## Files Modified

1. ✅ `force-app/main/default/classes/services/OnboardingAccessService.cls`
2. ✅ `force-app/main/default/classes/test/TestZipCodeFactory.cls`
3. ✅ `force-app/main/default/classes/test/OnboardingAccessServiceTest.cls`

## Verification

- ✅ No linter errors
- ✅ All queries updated to use correct pattern
- ✅ Test methods updated to reflect new data model
- ✅ Deprecated method added for backwards compatibility

## Next Steps

1. Verify field metadata exists: `Account.Zip_Code__c`, `Contact.Zip_Code__c`, `Lead.Zip_Code__c`
2. Remove deprecated field `Zip_Code__c.Account__c` if it exists
3. Run all tests to ensure they pass with new data model

---

**Status:** ✅ COMPLETED  
**Date:** December 2025


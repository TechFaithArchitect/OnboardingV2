@isTest
public class TestOnboardingFactory {

    public static Onboarding__c create(Account acc, Vendor_Customization__c vendorProgram, Boolean doInsert) {
        Onboarding__c onboarding = new Onboarding__c(
            Account__c = acc.Id,
            Vendor_Customization__c = vendorProgram.Id
        );
        if (doInsert) insert onboarding;
        return onboarding;
    }
}
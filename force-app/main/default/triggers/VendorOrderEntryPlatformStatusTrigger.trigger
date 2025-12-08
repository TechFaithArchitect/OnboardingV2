trigger VendorOrderEntryPlatformStatusTrigger on Vendor_Order_Entry_Platform__c (after update) {
    if (! OnboardingExpirationEvaluator.bypassTracking) {
    OnboardingStatusTrackerHandler.handleStatusTracking(Trigger.oldMap, Trigger.newMap,'Vendor_Order_Entry_Platform__c');
    }
}
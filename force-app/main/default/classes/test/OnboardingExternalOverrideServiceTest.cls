@isTest
private class OnboardingExternalOverrideServiceTest {
    @isTest
    static void applyOverrideCreatesAudit() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Onboarding__c ob = new Onboarding__c(
            Account__c = acc.Id,
            Onboarding_Status__c = 'Setup Complete'
        );
        insert ob;

        OnboardingExternalOverrideService.OverrideRequest req = new OnboardingExternalOverrideService.OverrideRequest();
        req.onboardingId = ob.Id;
        req.reason = 'Re-onboard';
        req.allowedPrograms = new List<String>{ 'ProgramA', 'ProgramB' };
        req.sourceSystem = 'Axapta';
        req.requestId = 'REQ-123';

        Test.startTest();
        OnboardingExternalOverrideService.OverrideResponse resp = OnboardingExternalOverrideService.applyOverride(req);
        Test.stopTest();

        System.assertEquals(true, resp.success, 'Override should succeed');

        Onboarding__c updated = [
            SELECT External_Override_Enabled__c, External_Override_Programs__c,
                   External_Override_Request_ID__c, Previous_Status_Before_Override__c
            FROM Onboarding__c
            WHERE Id = :ob.Id
        ];
        System.assertEquals(true, updated.External_Override_Enabled__c, 'Override flag should be set');
        System.assert(updated.External_Override_Programs__c.contains('ProgramA'), 'Programs should be stored');
        System.assertEquals('REQ-123', updated.External_Override_Request_ID__c, 'Request ID should be stored');
        System.assertEquals('Setup Complete', updated.Previous_Status_Before_Override__c, 'Previous status stored');

        List<Onboarding_External_Override_Log__c> logs = [
            SELECT Override_Action__c, Allowed_Programs__c, Source_System__c
            FROM Onboarding_External_Override_Log__c
            WHERE Onboarding__c = :ob.Id
        ];
        System.assertEquals(1, logs.size(), 'One audit log expected');
        System.assertEquals('Applied', logs[0].Override_Action__c);
        System.assert(logs[0].Allowed_Programs__c.contains('ProgramA'));
    }

    @isTest
    static void removeOverrideResetsFlagAndLogs() {
        Account acc = new Account(Name = 'Test Account 2');
        insert acc;
        Onboarding__c ob = new Onboarding__c(
            Account__c = acc.Id,
            Onboarding_Status__c = 'Setup Complete',
            External_Override_Enabled__c = true,
            Previous_Status_Before_Override__c = 'Setup Complete'
        );
        insert ob;

        Test.startTest();
        OnboardingExternalOverrideService.OverrideResponse resp = OnboardingExternalOverrideService.removeOverride(ob.Id, 'Done');
        Test.stopTest();

        System.assertEquals(true, resp.success);
        Onboarding__c updated = [
            SELECT External_Override_Enabled__c, External_Override_Source__c, External_Override_Programs__c
            FROM Onboarding__c WHERE Id = :ob.Id
        ];
        System.assertEquals(false, updated.External_Override_Enabled__c, 'Override flag should be cleared');
        System.assertEquals(null, updated.External_Override_Source__c);
        System.assertEquals(null, updated.External_Override_Programs__c);

        List<Onboarding_External_Override_Log__c> logs = [
            SELECT Override_Action__c, Reason__c
            FROM Onboarding_External_Override_Log__c
            WHERE Onboarding__c = :ob.Id
            AND Override_Action__c = 'Removed'
        ];
        System.assertEquals(1, logs.size(), 'One removal audit log expected');
        System.assertEquals('Done', logs[0].Reason__c);
    }
}

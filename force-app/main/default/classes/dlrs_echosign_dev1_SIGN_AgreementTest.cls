/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_echosign_dev1_SIGN_AgreementTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_echosign_dev1_SIGN_AgreementTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new echosign_dev1__SIGN_Agreement__c());
    }
}
@istest
class PV_SRCertStatusChangeBatchSchedulerTest {
	public static testMethod void testschedule() {
		Test.StartTest();
		PV_SRCertStatusChangeBatchScheduler testsche = new PV_SRCertStatusChangeBatchScheduler();
		String sch = '0 0 23 * * ?';
		system.schedule('Test status Check', sch, testsche );
		Test.stopTest();
	}
}
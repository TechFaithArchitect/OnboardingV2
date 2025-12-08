@istest
class PV_SAStatusChangeToPastOpenSchedulerTest{
	public static testMethod void testschedule() {
		Test.StartTest();
        PV_SAStatusChangeToPastOpenScheduler testsche = new PV_SAStatusChangeToPastOpenScheduler();
		String sch = '0 0 23 * * ?';
        system.schedule('Test status Check', sch, testsche );
		Test.stopTest();
	}
}
@istest
class PV_SAStatusChangeToDispatchSchedulerTest{
	public static testMethod void testschedule() {
		Test.StartTest();
		PV_SAStatusChangeToDispatchScheduler testsche = new PV_SAStatusChangeToDispatchScheduler();
		String sch = '0 0 23 * * ?';
		system.schedule('Test status Check', sch, testsche );
		Test.stopTest();
	}
}
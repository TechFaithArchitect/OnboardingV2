@istest
class PV_WorkTypeSRBatchSchedulerTest{
	public static testMethod void testschedule() {
		Test.StartTest();
		PV_WorkTypeSRBatchScheduler testsche = new PV_WorkTypeSRBatchScheduler();
		String sch = '0 0 23 * * ?';
		system.schedule('Test status Check', sch, testsche );
		Test.stopTest();
	}
}
@istest
public class PV_AssignChildTerritoryBatchSchTest {
    public static testMethod void testschedule() {
		Test.StartTest();
		PV_AssignChildTerritoryBatchScheduler testsche = new PV_AssignChildTerritoryBatchScheduler();
		String sch = '0 0 23 * * ?';
		system.schedule('Test status Check', sch, testsche );
		Test.stopTest();
	}

}
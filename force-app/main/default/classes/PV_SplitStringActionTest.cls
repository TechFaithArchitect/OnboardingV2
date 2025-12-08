@IsTest
public class PV_SplitStringActionTest {

    @IsTest
    static void testSplitText_basicCase() {
        PV_SplitStringAction.Request req = new PV_SplitStringAction.Request();
        req.inputText = 'test;test2;test3';

        List<PV_SplitStringAction.Request> requests = new List<PV_SplitStringAction.Request>{ req };

        Test.startTest();
        List<PV_SplitStringAction.Response> responses = PV_SplitStringAction.splitText(requests);
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'Should return one response');
        System.assertEquals(3, responses[0].values.size(), 'Should split into 3 values');
        System.assertEquals('test', responses[0].values[0]);
        System.assertEquals('test2', responses[0].values[1]);
        System.assertEquals('test3', responses[0].values[2]);
    }
}
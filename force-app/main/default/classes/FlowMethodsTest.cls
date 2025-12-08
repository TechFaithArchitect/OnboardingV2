@isTest
public class FlowMethodsTest {
    @isTest
    static void testGetStates(){
        test.startTest();
        List<List<FlowResponse>> response = FlowMethods.getStates();
        test.stopTest();

        System.assert(!response[0].isEmpty(), 'Response should not be empty');
    }
}
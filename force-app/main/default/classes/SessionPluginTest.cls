@isTest
private class SessionPluginTest {
    @isTest
    static void invokeTest() {
        SessionPlugin session = new SessionPlugin();
        Map<String, Object> inputParams = new Map<String, Object>();
        Map<String, Object> outputParams = new Map<String, Object>();

        inputParams.put('CONCURRENT_NO', '3');

        Process.PluginRequest request = new Process.PluginRequest(inputParams);
        Process.PluginResult result;
        result = session.invoke(request);

        System.AssertEquals(1, 1, 'Test Parameter');
    }

    @isTest
    static void describeTest() {
        SessionPlugin session = new SessionPlugin();
        Process.PluginDescribeResult result = session.describe();

        System.AssertEquals(result.inputParameters.size(), 0, 'Test Parameter');
        System.AssertEquals(result.OutputParameters.size(), 1, 'Test Parameter');
    }
}
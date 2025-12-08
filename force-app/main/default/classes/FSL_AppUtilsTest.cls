@isTest
private class FSL_AppUtilsTest {
    @isTest
    static void testResponseWrapper() {
        
        String testState = 'SUCCESS';
        String testResponse = 'Test Response';
        String testError = null;
        
        FSL_AppUtils.ResponseWrapper wrapper = new FSL_AppUtils.ResponseWrapper(testState, testResponse, testError);
        
        System.assertEquals(testState, wrapper.state, 'State should match the input');
        System.assertEquals(testResponse, wrapper.response, 'Response should match the input');
        System.assertEquals(testError, wrapper.error, 'Error should match the input');
    }
}
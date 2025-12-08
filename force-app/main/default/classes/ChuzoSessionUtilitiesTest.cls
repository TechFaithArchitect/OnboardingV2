@isTest
private class ChuzoSessionUtilitiesTest {
    @IsTest
    static void testCheckUserStatus() {
        // Call the method to be tested
        ChuzoSessionUtilities.Response response = ChuzoSessionUtilities.checkUserStatus();

        // Assert the expected result
        System.assertEquals(false, response.isGuest, 'User status should be guest');
    }
}
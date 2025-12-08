@isTest
private class POE_CommunityPasswordResetControllerTest {
    @isTest
    static void testSetUserPasswordSuccess() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            String testPassword = 'TestPass123!';
            String encodedPassword = EncodingUtil.base64Encode(Blob.valueOf(testPassword));

            String response = POE_CommunityPasswordResetController.setUserPassword(encodedPassword);

            POE_CommunityPasswordResetController.ResponseWrapper wrapper = (POE_CommunityPasswordResetController.ResponseWrapper) JSON.deserialize(
                response,
                POE_CommunityPasswordResetController.ResponseWrapper.class
            );

            System.assertEquals(
                POE_CommunityPasswordResetController.SUCCESS,
                wrapper.status,
                'Expected successful status for valid password'
            );
            System.assert(String.isBlank(wrapper.errorMessage), 'Error message should be blank on success');
        }
    }

    @isTest
    static void testSetUserPasswordError() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            String encodedPassword = EncodingUtil.base64Encode(Blob.valueOf(''));

            String response = POE_CommunityPasswordResetController.setUserPassword(encodedPassword);

            POE_CommunityPasswordResetController.ResponseWrapper wrapper = (POE_CommunityPasswordResetController.ResponseWrapper) JSON.deserialize(
                response,
                POE_CommunityPasswordResetController.ResponseWrapper.class
            );

            System.assertEquals(
                POE_CommunityPasswordResetController.ERROR,
                wrapper.status,
                'Expected error status for invalid password'
            );
            System.assertNotEquals(null, wrapper.errorMessage, 'Error message should not be null on failure');
            System.assertNotEquals('', wrapper.errorMessage, 'Error message should not be empty on failure');
        }
    }

    private static User createTestUser() {
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User testUser = new User(
            Alias = 'tuser',
            Email = 'testuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'TestUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser' + DateTime.now().getTime() + '@test.com'
        );

        insert testUser;
        return testUser;
    }
}
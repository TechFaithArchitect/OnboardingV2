@IsTest
private class EmailCommDedupeUtilTest {

    @IsTest
    static void testIsDuplicateReturnsFalseWhenNoMatch() {
        EmailCommSendRequestDTO emailCommSendRequestDTO = TestDataFactory.createEmailCommSendRequestDTO();

        Test.startTest();
        Boolean isDuplicate = EmailCommDedupeUtil.isDuplicate(emailCommSendRequestDTO);
        Test.stopTest();

        System.assertEquals(false, isDuplicate, 'Should not detect duplicate when no log exists');
    }

    @IsTest
    static void testIsDuplicateReturnsTrueWhenMatchExists() {
        EmailCommSendRequestDTO emailCommSendRequestDTO = TestDataFactory.createEmailCommSendRequestDTO();

        TestDataFactory.createEmailCommLog(emailCommSendRequestDTO, true, 0);

        Test.startTest();
        Boolean isDuplicate = EmailCommDedupeUtil.isDuplicate(emailCommSendRequestDTO);
        Test.stopTest();

        System.assertEquals(true, isDuplicate, 'Should detect duplicate when matching log exists');
    }

    @IsTest
    static void testIsDuplicateIgnoresOldLogs() {
        EmailCommSendRequestDTO emailCommSendRequestDTO = TestDataFactory.createEmailCommSendRequestDTO();

        TestDataFactory.createEmailCommLog(emailCommSendRequestDTO, true, 5);

        Test.startTest();
        Boolean isDuplicate = EmailCommDedupeUtil.isDuplicate(emailCommSendRequestDTO);
        Test.stopTest();

        System.assertEquals(false, isDuplicate, 'Old logs should not count as duplicates');
    }
}

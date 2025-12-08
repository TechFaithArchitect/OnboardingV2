@isTest
public class PV_DateParserTest {
    @isTest
    static void testParseRFC2822_ValidDate() {
        String input = 'Tue, 13 Feb 2024 15:30:45 +0000';

        Test.startTest();
        DateTime result = PV_DateParser.parseRFC2822(input);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected a valid DateTime object');
        System.assertEquals(DateTime.newInstanceGMT(2024, 2, 13, 15, 30, 45), result, 'Parsed DateTime does not match expected value');
    }

    @isTest
    static void testParseRFC2822_InvalidDate() {
        String input = 'Invalid Date Format';

        Test.startTest();
        DateTime result = PV_DateParser.parseRFC2822(input);
        Test.stopTest();

        System.assertEquals(null, result, 'Expected null for an invalid date format');
    }

    @isTest
    static void testParseRFC2822_NullOrBlankInput() {
        Test.startTest();
        System.assertEquals(null, PV_DateParser.parseRFC2822(null), 'Expected null for null input');
        System.assertEquals(null, PV_DateParser.parseRFC2822(''), 'Expected null for blank input');
        System.assertEquals(null, PV_DateParser.parseRFC2822('   '), 'Expected null for whitespace input');
        Test.stopTest();
    }
}
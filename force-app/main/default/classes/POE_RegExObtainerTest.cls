@isTest
public with sharing class POE_RegExObtainerTest {
    @isTest
    public static void getOnlyLettersRegExPositiveTest(){
        String errorMessage = 'Test error message';
        String regex = 'd{10}$';
        Test.startTest();
        POE_RegExObtainer.ResponseWrapper wrapper = POE_RegExObtainer.getOnlyLettersRegEx();
        Test.stopTest();
        Assert.isNotNull(wrapper.result.get('expression'), 'Expression should not have been null.');
        Assert.isNotNull(wrapper.result.get('errorMessage'), 'Error message should not have been null.');
    }
}
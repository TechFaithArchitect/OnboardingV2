@isTest
public with sharing class FlowRedirectControllertest {
    @isTest
    static void test_getMyDomain(){
        String myDomain = FlowRedirectController.getMyDomain();

        System.assert(myDomain != null, 'myDomain cant be null');
    }
}
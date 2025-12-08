@isTest
public class FooterChuzoControllerTest {
    @isTest
    static void Test_getManualPDFLinkCustomSetting(){
        
        test.startTest();
        Chuzo_Settings__c response = FooterChuzoController.getManualPDFLinkCustomSetting();
        test.stopTest();

        System.assertEquals(null, response.Chuzo_Manual_File_URL__c, 'Field should be null');
    }

}
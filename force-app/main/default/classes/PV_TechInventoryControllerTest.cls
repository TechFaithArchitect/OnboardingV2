@isTest
private class PV_TechInventoryControllerTest {

    @isTest
    static void testGetTechProductUrl() {
        Test.startTest();
        String url = PV_TechInventoryController.getTechProductUrl();
        Test.stopTest();

        Assert.isNotNull(url, 'URL should be populated');
    }
}
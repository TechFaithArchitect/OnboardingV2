@isTest
public with sharing class POE_OwnerOrderDashboardControllerTest {
    private static final String TEST_NAME = 'Test';
    private static final String PRIMARY_PROGRAM_FILTER = 'All';
    private static final String PRIMARY_TYPE_FILTER = 'All';
    private static final String PRIMARY_DATE_FILTER = 'All';
    private static final String SECONDARY_PROGRAM_FILTER = 'DirecTV';
    private static final String SECONDARY_TYPE_FILTER = 'Door To Door';
    private static final String SECONDARY_DATE_FILTER = 'Custom';
    private static final String ORDER_STATUS = 'Draft';
    private static final String ORDER_STATUS_2 = 'Pending Installation';
    private static final String TERTIARY_DATE = 'Today';

    static void makeData() {
        Account testAccount = new Account(
            Name = TEST_NAME
        );
        insert testAccount;

        testAccount = [SELECT Id FROM Account LIMIT 1];
        Order testOrder = new Order(
            AccountId = testAccount.Id,
            Status = ORDER_STATUS,
            EffectiveDate = System.today()
        );
        insert testOrder;

        testOrder = new Order(
            AccountId = testAccount.Id,
            Status = ORDER_STATUS_2,
            EffectiveDate = System.today()
        );
        insert testOrder;
    }

    @isTest
    public static void testGetReports() {
        Test.startTest();
        Map<String, String> result = poe_ownerOrderDashboardController.getReports();
        Test.stopTest();
        
        Assert.areNotEqual(null, result, 'testGetReports');
    }

    @isTest
    public static void testGetOrdersInfo() {
        makeData();
        Test.startTest();
        
        // Test with filters = All
        poe_ownerOrderDashboardController.ResponseWrapper result = poe_ownerOrderDashboardController.getOrdersInfo(
            PRIMARY_PROGRAM_FILTER, PRIMARY_TYPE_FILTER, PRIMARY_DATE_FILTER, null, null
        );
        Assert.areNotEqual(null, result, 'testGetOrdersInfo');

        // Test with custom filters
        String today = Datetime.now().format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
        result = poe_ownerOrderDashboardController.getOrdersInfo(
            SECONDARY_PROGRAM_FILTER, SECONDARY_TYPE_FILTER, SECONDARY_DATE_FILTER, today, today
        );
        Assert.areNotEqual(null, result, 'testGetOrdersInfo2');

        // Test with dynamic date
        result = poe_ownerOrderDashboardController.getOrdersInfo(
            PRIMARY_PROGRAM_FILTER, PRIMARY_TYPE_FILTER, TERTIARY_DATE, null, null
        );
        Assert.areNotEqual(null, result, 'testGetOrdersInfo3');

        Test.stopTest();
    }

    @isTest
    public static void testGetFilterValues() {
        Test.startTest();
        Map<String, List<String>> result = poe_ownerOrderDashboardController.getFilterValues();
        Test.stopTest();

        Assert.areNotEqual(null, result, 'testGetFilterValues');
    }
}
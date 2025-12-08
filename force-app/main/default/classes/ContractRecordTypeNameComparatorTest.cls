@isTest
private class ContractRecordTypeNameComparatorTest {

    @isTest
    static void testComparatorOrder() {
        Contract nda = new Contract(RecordType = new RecordType(Name = 'NDA'));
        Contract baseApp = new Contract(RecordType = new RecordType(Name = 'New Dealer Application (DOM)'));
        ContractRecordTypeNameComparator comparator = new ContractRecordTypeNameComparator();

        System.assertEquals(-1, comparator.compare(nda, baseApp), 'NDA should sort before non-NDA');
        System.assertEquals(1, comparator.compare(baseApp, nda), 'Non-NDA should sort after NDA');
        System.assertEquals(0, comparator.compare(nda, nda), 'Same types should return 0');
    }
}
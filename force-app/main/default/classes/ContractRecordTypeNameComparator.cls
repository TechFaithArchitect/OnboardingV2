public with sharing class ContractRecordTypeNameComparator implements Comparator<Contract> {
    public Integer compare(Contract a, Contract b) {
        if (a.RecordType.Name == 'NDA' && b.RecordType.Name != 'NDA') return -1;
        if (a.RecordType.Name != 'NDA' && b.RecordType.Name == 'NDA') return 1;
        return 0;
    }
}
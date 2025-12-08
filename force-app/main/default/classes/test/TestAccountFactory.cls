@isTest
public class TestAccountFactory {

    public static Account create(String name, Boolean doInsert) {
        Account account = new Account(
            Name = name + ' ' + DateTime.now().getTime(),
            POE_Dealer_Code__c = 'D01',
            Available_FSL_Vendors__c = Label.DIRECTV
        );
        TestDataFactoryUtil.maybeInsert(account, doInsert);
        return account;
    }
}

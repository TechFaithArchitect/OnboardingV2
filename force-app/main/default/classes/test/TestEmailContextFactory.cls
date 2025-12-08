@isTest
public class TestEmailContextFactory {

    public static TestDataFactoryWrapper.EmailTestContextWrapper create(Boolean doInsert) {
        // Create Account + Contact directly
        Account account = TestAccountFactory.create('EmailAcc', doInsert);
        Contact contact = TestContactFactory.create('Email', 'User', account, doInsert);

        // Create Template directly
        Communication_Template__c template = new Communication_Template__c(
            Name = 'Test Template ' + DateTime.now().getTime(),
            Active__c = true
        );
        TestDataFactoryUtil.maybeInsert(template, doInsert);

        // Create Onboarding directly
        Onboarding__c onboarding = new Onboarding__c(Account__c = account.Id);
        TestDataFactoryUtil.maybeInsert(onboarding, doInsert);

        return new TestDataFactoryWrapper.EmailTestContextWrapper(
            account, contact, template, onboarding
        );
    }
}
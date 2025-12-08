public class ContactSelectorController {
    @AuraEnabled
    public static Contact saveContact(Map<String, Object> myData){
        try {
            String firstName = (String) myData.get('firstName');
            String lastName = (String) myData.get('lastName');
            String email = (String) myData.get('email');
            String phone = (String) myData.get('phone');
            String accountId = (String) myData.get('accountId');

            Contact newContact = new Contact(
                FirstName = firstName,
                LastName = lastName,
                Email = email,
                Phone = phone,
                AccountId = accountId
            );

            insert newContact;

            return newContact;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
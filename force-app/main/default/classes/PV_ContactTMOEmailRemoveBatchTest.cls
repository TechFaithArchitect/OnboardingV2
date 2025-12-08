@isTest
public class PV_ContactTMOEmailRemoveBatchTest {
    static testMethod void testContactTMOEmailRemoveBatch(){        
        List<Contact> ContactList= new List<Contact>();        
        for(Integer i=0 ;i <200;i++){           
            Contact con = new Contact();            
            con.LastName ='Name'+i;  
            con.TMO_Email__c = 'tmoemail'+i+'@gmail.com';
            ContactList.add(con);            
        }        
        insert ContactList;        
        Test.startTest();        
        PV_ContactTMOEmailRemoveBatch obj = new PV_ContactTMOEmailRemoveBatch();        
        DataBase.executeBatch(obj);       
        Test.stopTest();      
        integer  count = [select count() from Contact where LastName LIKE '%Name%'];
        System.assertEquals(200, count );
    }
    static testMethod void testUpdateContactEmail(){
        Test.setMock(HttpCalloutMock.class, new PV_RestForContactTMOEmailRemoveBatchMock());
        
        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestUri = '/services/apexrest/ContactTMOEmailRemove/';
        
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;
        
        PV_RestForContactTMOEmailRemoveBatch.updateContactEmail();  
    }
}
public with sharing class AccountResponseWrapper {
    
    public class AccountWrapper{
        public String Id {get;set;}
        public String Name {get;set;}
        public String Division {get;set;}
        public String Region {get;set;}
        public String Territory {get;set;}
        public String CompanyID {get;set;}
        public String P10_Invoice_Account {get;set;}
        public String Alert_Message {get;set;}
        public String Customer_Classification {get;set;}
    }

    public List<AccountWrapper> records { get;set; }
}
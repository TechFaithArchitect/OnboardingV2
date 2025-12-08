public class FSL_AppUtils {
    
    public class ResponseWrapper {
        @AuraEnabled
        public String state; 
        @AuraEnabled
        public Object response; 
        @AuraEnabled
        public String error;

        public ResponseWrapper(String state, Object response, String error) {
            this.state = state;
            this.response = response;
            this.error = error;
        }
    }
}
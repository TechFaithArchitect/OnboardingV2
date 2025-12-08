public class PV_SplitStringAction {
    
    public class Request {
        @InvocableVariable(required=true)
        public String inputText;
    }
    
    public class Response {
        @InvocableVariable
        public List<String> values;
    }
    
    @InvocableMethod(label='Split String' description='Split a string by semicolon and return a list')
    public static List<Response> splitText(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        for (Request request : requests) {
            Response res = new Response();
            
            List<String> rawValues = request.inputText.split(';');
            List<String> cleanValues = new List<String>();
            for (String val : rawValues) {
                if (String.isNotBlank(val)) {
                    cleanValues.add(val);
                }
            }
            res.values = cleanValues;
            responses.add(res);
        }
        return responses;
    }
}
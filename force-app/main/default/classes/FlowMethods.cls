public class FlowMethods {

    @InvocableMethod(
        label='Get US States' 
        description='Get Only US states'
    )
    public static List<List<FlowResponse>> getStates(){
        List<FlowResponse> response = new List<FlowResponse>();

        Map<String, List<Schema.PicklistEntry>> statesByCountry = getFieldDependencies('Address', 'CountryCode', 'StateCode');

        for(Schema.PicklistEntry state : statesByCountry.get('United States')) {
            FlowResponse newEntry = new FlowResponse();
            newEntry.label = state.getLabel();
            newEntry.code = state.getValue();
            response.add(newEntry);
        }

        return new List<List<FlowResponse>> {response};
    }
 
    public static Map<String, List<Schema.PicklistEntry>> getFieldDependencies(String objectName, String controllingField, String dependentField) {
        Map<String, List<Schema.PicklistEntry>> controllingInfo = new Map<String, List<Schema.PicklistEntry>>();
    
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
    
        Schema.DescribeSObjectResult describeResult = objType.getDescribe();
        Schema.DescribeFieldResult controllingFieldInfo = describeResult.fields.getMap().get(controllingField).getDescribe();
        Schema.DescribeFieldResult dependentFieldInfo = describeResult.fields.getMap().get(dependentField).getDescribe();
    
        List<Schema.PicklistEntry> controllingValues = controllingFieldInfo.getPicklistValues();
        List<Schema.PicklistEntry> dependentValues = dependentFieldInfo.getPicklistValues();
    
        for(Schema.PicklistEntry currControllingValue : controllingValues)
        {
            controllingInfo.put(currControllingValue.getLabel(), new List<Schema.PicklistEntry>());
        }
    
        for(Schema.PicklistEntry currDependentValue : dependentValues)
        {
            String jsonString = JSON.serialize(currDependentValue);
    
            MyPickListInfo info = (MyPickListInfo) JSON.deserialize(jsonString, MyPickListInfo.class);
    
            String hexString = EncodingUtil.convertToHex(EncodingUtil.base64Decode(info.validFor)).toUpperCase();
    
            Integer baseCount = 0;
    
            for(Integer curr : hexString.getChars())
            {
                Integer val = 0;
    
                if(curr >= 65)
                {
                    val = curr - 65 + 10;
                }
                else
                {
                    val = curr - 48;
                }
    
                if((val & 8) == 8)
                {
                    controllingInfo.get(controllingValues[baseCount + 0].getLabel()).add(currDependentValue);
                }
                if((val & 4) == 4)
                {
                    controllingInfo.get(controllingValues[baseCount + 1].getLabel()).add(currDependentValue);                    
                }
                if((val & 2) == 2)
                {
                    controllingInfo.get(controllingValues[baseCount + 2].getLabel()).add(currDependentValue);                    
                }
                if((val & 1) == 1)
                {
                    controllingInfo.get(controllingValues[baseCount + 3].getLabel()).add(currDependentValue);                    
                }
    
                baseCount += 4;
            }            
        } 
        
        return controllingInfo;
    }

    public class MyPickListInfo {
        public String validFor;
    }
}
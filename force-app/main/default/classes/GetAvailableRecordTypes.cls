global with sharing class GetAvailableRecordTypes {
  
  @InvocableMethod(label='Get Available Record Types')
  global static List<List<RecordType>> invoke(
      List<GetAvailableRecordTypesRequest> requests
  ) {
    // 1) Cache global describe
    Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
    List<List<RecordType>> allResults = new List<List<RecordType>>();
    
    // 2) Loop each request
    for (GetAvailableRecordTypesRequest req : requests) {
      List<RecordType> rts = new List<RecordType>();
      Schema.SObjectType sType = gd.get(req.sObjectApiName);
      if (sType != null) {
        Schema.DescribeSObjectResult dsr = sType.getDescribe();
        for (Schema.RecordTypeInfo rtInfo : dsr.getRecordTypeInfos()) {
          if (rtInfo.isAvailable()) {
            // 3) Build a lightweight RecordType sObject
            rts.add(new RecordType(
              Id   = rtInfo.getRecordTypeId(),
              Name = rtInfo.getName()
            ));
          }
        }
      }
      allResults.add(rts);
    }
    
    return allResults;
  }
}
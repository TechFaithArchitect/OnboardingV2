public class PV_WorkTypeSRBatchHandler {
    
    public static Map<Id,Map<String,boolean>> skillcheck(Set<Id>srIdsSet) {
        Set<Id>tMobileSkillSet = new Set<Id>();
        Map<Id,Map<String,boolean>> srWTMap = new Map<Id,Map<String,boolean>>();
        Map<Id,Set<Id>>worktypeSkillMap = new Map<Id,Set<Id>>();
        Map<Id,Set<Id>>srSkillMap = new Map<Id,Set<Id>>();
        
        List<WorkType> WtList = [
            SELECT  Id,Name,Work_Type_Code__c , (SELECT SkillId,SkillNumber FROM SkillRequirements)
            FROM    WorkType 
            WHERE   Vendor__c IN ('T-Mobile', 'WOW', 'AT&T')
        ];
        
        for(WorkType wotype:WtList){
            Set<Id> skillIds = new Set<Id>();
            for (SkillRequirement sr : wotype.SkillRequirementS) {
                skillIds.add(sr.SkillId);
                tMobileSkillSet.add(sr.SkillId);
            }
            worktypeSkillMap.put(wotype.Id, skillIds);
        }
        
        system.debug('worktypeSkillMap'+worktypeSkillMap);
        
        List<ServiceResourceSkill>srList=[SELECT ServiceResourceId,SkillId,SkillNumber FROM ServiceResourceSkill
                                          WHERE ServiceResourceId IN:srIdsSet AND EffectiveStartDate <= TODAY];
        
        
        for(ServiceResourceSkill srs:srList){
            if(srSkillMap.containsKey(srs.ServiceResourceId)){
                srSkillMap.get(srs.ServiceResourceId).add(srs.SkillId);
            }else{
                srSkillMap.put(srs.ServiceResourceId,new Set<Id>{srs.SkillId});
            }
        }
        
        system.debug('srSkillMap'+srSkillMap);
        
       for (WorkType workType : WtList) {
            for (Id srId : srSkillMap.keySet()) {
                String workTypeCode = workType.Work_Type_Code__c;

                if (srSkillMap.get(srId).containsAll(worktypeSkillMap.get(workType.Id)) &&
                        !worktypeSkillMap.get(workType.Id).isEmpty()) {
                    if (!srWTMap.containsKey(srId)) {
                        srWTMap.put(srId, new Map<String, Boolean>());
                    }
                    Map<String, Boolean> wtCheckMap = new Map<String, Boolean>();
                    wtCheckMap.put(workTypeCode, true);
                    srWTMap.get(srId).putAll(wtCheckMap);
                } else {
                    if (!srWTMap.containsKey(srId)) {
                        srWTMap.put(srId, new Map<String, Boolean>());
                    }
                    Map<String, Boolean> wtCheckMap = new Map<String, Boolean>();
                    wtCheckMap.put(workTypeCode, false);
                    srWTMap.get(srId).putAll(wtCheckMap);
                }
            }
        }

        return srWTMap;
    
    }
}
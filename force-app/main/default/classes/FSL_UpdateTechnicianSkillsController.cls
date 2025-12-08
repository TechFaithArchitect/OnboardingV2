public with sharing class FSL_UpdateTechnicianSkillsController {
    @AuraEnabled
    public static List<String> getAccountVendors(Id accountId) {
        List<String> vendorValues = new List<String>();
        Account account = [SELECT Id, Available_FSL_Vendors__c FROM Account WHERE Id = :accountId LIMIT 1];
        
        if (account.Available_FSL_Vendors__c != null) {
            vendorValues = account.Available_FSL_Vendors__c.split(';');
        } else {
            vendorValues = new List<String>();
        }

        return vendorValues;
    }

    @AuraEnabled
    public static String getTechnicianVendors(Id resourceId) {
        ServiceResource serviceResource = [
            SELECT  Id, Vendor_Type__c
            FROM    ServiceResource
            WHERE   Id = :resourceId
        ];

        return serviceResource.Vendor_Type__c;
    }

    @AuraEnabled
    public static List<Id> getActiveTechnicianSkillIds(Id resourceId) {
        List<Id> skillIds = new List<Id>();
        
        for (ServiceResourceSkill resourceSkill : [
            SELECT  SkillId
            FROM    ServiceResourceSkill
            WHERE   ServiceResourceId = :resourceId
            AND     EffectiveEndDate = null
        ]) {
            skillIds.add(resourceSkill.SkillId);
        }
        
        return skillIds;
    }

    public static List<ServiceResourceSkill> getTechnicianSkills(Id resourceId) {
        return [
            SELECT  SkillId, Skill.DeveloperName, EffectiveEndDate
            FROM    ServiceResourceSkill
            WHERE   ServiceResourceId = :resourceId
        ];
    }

    public static void updateSkills(Id resourceId, List<String> skillsDeveloperName, String actionType) {
        List<ServiceResourceSkill> skillsToUpdate = [
            SELECT  Id, EffectiveStartDate, EffectiveEndDate
            FROM    ServiceResourceSkill 
            WHERE   Skill.DeveloperName IN :skillsDeveloperName
            AND     ServiceResourceId = :resourceId
        ];

        for (ServiceResourceSkill serviceResourceSkill : skillsToUpdate) {
            if (actionType == 'Update') {
                serviceResourceSkill.EffectiveEndDate = null;
            } else if (actionType == 'Remove' && serviceResourceSkill.EffectiveStartDate <= System.now()) {
                serviceResourceSkill.EffectiveEndDate = System.now();
            }
            else if (actionType == 'Remove' && serviceResourceSkill.EffectiveStartDate > System.now()) {
                serviceResourceSkill.EffectiveStartDate = System.now();
                serviceResourceSkill.EffectiveEndDate = System.now();
            }
        }

        try {
            update skillsToUpdate;
        } catch (Exception e) {
            ExceptionUtil.publishFSLException('Internal Error', 'FSL', FSL_UpdateTechnicianSkillsController.class.getName(), e.getMessage());
            throw new AuraHandledException('Failed to update skills. ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void updateTechnicianSkills(Id resourceId, Date startDate, String skillsJson) {
        List<SkillWrapper> allSkills = (List<SkillWrapper>) JSON.deserialize(skillsJson, List<SkillWrapper>.class);
        List<ServiceResourceSkill> currentTechnicianSkills = getTechnicianSkills(resourceId);
        Map<Id, ServiceResourceSkill> currentSkillsMap = new Map<Id, ServiceResourceSkill>();
        
        for (ServiceResourceSkill serviceResourceSkill : currentTechnicianSkills) {
            currentSkillsMap.put(serviceResourceSkill.SkillId, serviceResourceSkill);
        }
        
        List<String> toCreate = new List<String>();
        List<String> toUpdate = new List<String>();
        List<String> toRemove = new List<String>();
        
        for (SkillWrapper skill : allSkills) {
            ServiceResourceSkill existing = currentSkillsMap.get(skill.Id);
            
            if (skill.isSelected && existing == null) {
                toCreate.add(skill.DeveloperName);
            } else if (skill.isSelected && existing.EffectiveEndDate != null) {
                toUpdate.add(skill.DeveloperName);
            } else if (!skill.isSelected && existing != null && existing.EffectiveEndDate == null) {
                toRemove.add(skill.DeveloperName);
            }            
        }
        
        Set<Id> allSkillIds = new Set<Id>();
        for (SkillWrapper skill : allSkills) {
            allSkillIds.add(skill.Id);
        }

        for (ServiceResourceSkill current : currentTechnicianSkills) {
            if (!allSkillIds.contains(current.SkillId) && current.EffectiveEndDate == null) {
                toRemove.add(current.Skill.DeveloperName);
            }
        }
        
        if (!toCreate.isEmpty()) {
            PV_CreateSRandSTMQueueable.assignSkillForSR(resourceId, toCreate, startDate);
        }
        if (!toUpdate.isEmpty()) {
            updateSkills(resourceId, toUpdate, 'Update');
        }
        if (!toRemove.isEmpty()) {
            updateSkills(resourceId, toRemove, 'Remove');
        }
    }

    @AuraEnabled
    public static void updateTechnicianVendors(Id resourceId, String vendors) {
        ServiceResource serviceResource = [SELECT Id, AccountId FROM ServiceResource WHERE Id = :resourceId LIMIT 1];
        serviceResource.Vendor_Type__c = vendors;
        update serviceResource;
    }

    public class SkillWrapper {
        public String Id;
        public String DeveloperName;
        public String MasterLabel;
        public Boolean isSelected;
    }
}
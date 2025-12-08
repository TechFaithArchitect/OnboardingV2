/**
 * @description       :
 * @author            : msatrano
 * @group             :
 * @last modified on  : 07-12-2022
 * @last modified by  : msatrano
 **/
global without sharing class POEUserDeactivationController {
    global Boolean invokeMethod(
        String methodName,
        Map<String, Object> inputMap,
        Map<String, Object> outMap,
        Map<String, Object> options
    ) {
        Boolean result = true;
        try {
            String userId = (String) inputMap.get('userId');
            String deactivationReason = (String) inputMap.get('deactivationReason');
            List<User> user = [SELECT IsActive, ContactId FROM USER WHERE ID = :userId];

            List<Contact> contacts = [SELECT Id, POE_Deactivation_Reason__c FROM Contact WHERE Id = :user[0].ContactId];
            contacts[0].POE_Deactivation_Reason__c = deactivationReason;
            contacts[0].Chuzo_Member__c = false;
            update contacts;

            outMap.put('result', 'Update successful');
        } catch (Exception e) {
            result = false;
        }
        return result;
    }

    @AuraEnabled
    public static void deactivateRepresentative(Map<String, Object> myData) {
        try {
            String userId = (String) myData.get('userId');
            String deactivationReason = (String) myData.get('deactivationReason');

            List<User> user = [SELECT IsActive, ContactId FROM USER WHERE ID = :userId];
            List<Contact> contact = [SELECT Id, FSL_Member__c FROM Contact WHERE Id = :user[0].ContactId];

            if (contact[0].FSL_Member__c == true) {
                Map<Id, PermissionSetGroup> permSetsGroup = new Map<Id, PermissionSetGroup>(
                    [SELECT Id, MasterLabel FROM PermissionSetGroup WHERE MasterLabel LIKE '%Chuzo%']
                );
                Map<Id, PermissionSet> permSets = new Map<Id, PermissionSet>(
                    [SELECT Id, Label FROM PermissionSet WHERE Label LIKE '%Chuzo%']
                );
                List<PermissionSetAssignment> permAssigments = [
                    SELECT Id
                    FROM PermissionSetAssignment
                    WHERE
                        AssigneeId = :user[0].Id
                        AND (PermissionSetGroupId IN :permSetsGroup.keySet()
                        OR PermissionSetId IN :permSets.keySet())
                ];

                delete permAssigments;
            } else {
                user[0].isActive = false;
                update user;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void reactivateRepresentative(Map<String, Object> myData) {
        try {
            String userId = (String) myData.get('userId');
            List<User> user = [SELECT IsActive, ContactId FROM USER WHERE ID = :userId];
            List<Contact> contact = [SELECT Id, FSL_Member__c, AccountId FROM Contact WHERE Id = :user[0].ContactId];

            //create new case
            RecordType repOnboardingRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'Rep_Onboarding'];
            Group queue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Customer_Service_Team'];
            Case onboardingCase = new Case(
                AccountId = contact[0].AccountId,
                ContactId = contact[0].Id,
                POE_ICLRep__c = contact[0].Id,
                Type = 'Onboarding',
                Subject = 'Re-Activate Rep',
                Origin = 'Chuzo',
                RecordTypeId = repOnboardingRT.Id,
                OwnerId = queue.Id
            );
            insert onboardingCase;

            Group accountGroup = [
                SELECT Id
                FROM Group
                WHERE Type = 'Regular' AND Name = :('Dealer-' + contact[0].AccountId)
                LIMIT 1
            ];
            CaseSharingService.ShareInput shareInput = new CaseSharingService.ShareInput();
            shareInput.recordId = onboardingCase.Id;
            shareInput.groupId = accountGroup.Id;
            shareInput.accessLevel = 'Edit';
            CaseSharingService.shareCaseWithGroup(new List<CaseSharingService.ShareInput>{ shareInput });
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean hasOpenCase(Map<String, Object> myData) {
        String userId = (String) myData.get('userId');
        User user = [SELECT IsActive, ContactId FROM USER WHERE ID = :userId LIMIT 1];
        Contact contact = [SELECT Id, FSL_Member__c, AccountId FROM Contact WHERE Id = :user.ContactId LIMIT 1];
        RecordType repOnboardingRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'Rep_Onboarding'];
        List<Case> openChuzoCases = [
            SELECT Id
            FROM Case
            WHERE Status != 'Closed' AND ContactId = :contact.Id AND RecordTypeId = :repOnboardingRT.id
        ];

        if (openChuzoCases.size() > 0) {
            return true;
        } else {
            return false;
        }
    }

    @AuraEnabled
    public static void deactivateRepresentativeContact(Map<String, Object> myData) {
        String userId = (String) myData.get('userId');
        String deactivationReason = (String) myData.get('deactivationReason');
        List<User> user = [SELECT IsActive, ContactId FROM USER WHERE ID = :userId];
        List<Contact> contact = [
            SELECT Id, FSL_Member__c, POE_Deactivation_Reason__c
            FROM Contact
            WHERE Id = :user[0].ContactId
        ];

        contact[0].POE_Deactivation_Reason__c = deactivationReason;
        contact[0].Chuzo_Member__c = false;
        update contact;
    }
}
/**
 * Service for detecting blocked and at-risk onboarding records
 * Uses Status Evaluation Engine and Stage Dependency Service
 */
public with sharing class OnboardingBlockingDetectionService {

    /**
     * Gets IDs of blocked onboarding records
     * @param onboardingIds List of onboarding IDs to check
     * @return Set of blocked onboarding IDs
     */
    public static Set<Id> getBlockedOnboardingIds(List<Id> onboardingIds) {
        if (onboardingIds == null || onboardingIds.isEmpty()) {
            return new Set<Id>();
        }
        
        Set<Id> blockedIds = new Set<Id>();
        
        // Query onboarding records with requirements
        List<Onboarding__c> onboardings = [
            SELECT Id, Onboarding_Status__c, Vendor_Customization__c
            FROM Onboarding__c
            WHERE Id IN :onboardingIds
        ];
        
        if (onboardings.isEmpty()) {
            return blockedIds;
        }
        
        // Check for Denied status
        for (Onboarding__c ob : onboardings) {
            if (ob.Onboarding_Status__c == 'Denied') {
                blockedIds.add(ob.Id);
            }
        }
        
        // Query requirements with problematic statuses
        List<Onboarding_Requirement__c> blockedReqs = [
            SELECT Onboarding__c
            FROM Onboarding_Requirement__c
            WHERE Onboarding__c IN :onboardingIds
                  AND Status__c IN ('Denied', 'Incomplete')
        ];
        
        // Group by onboarding
        Map<Id, List<Onboarding_Requirement__c>> reqsByOnboarding = new Map<Id, List<Onboarding_Requirement__c>>();
        for (Onboarding_Requirement__c req : blockedReqs) {
            if (!reqsByOnboarding.containsKey(req.Onboarding__c)) {
                reqsByOnboarding.put(req.Onboarding__c, new List<Onboarding_Requirement__c>());
            }
            reqsByOnboarding.get(req.Onboarding__c).add(req);
        }
        
        // Check each onboarding for blocking requirements
        for (Onboarding__c ob : onboardings) {
            if (blockedIds.contains(ob.Id)) {
                continue; // Already marked as blocked
            }
            
            List<Onboarding_Requirement__c> reqs = reqsByOnboarding.get(ob.Id);
            if (reqs != null && !reqs.isEmpty()) {
                // Check if any requirement is Denied (blocked)
                for (Onboarding_Requirement__c req : reqs) {
                    if (req.Status__c == 'Denied') {
                        blockedIds.add(ob.Id);
                        break;
                    }
                }
            }
        }
        
        return blockedIds;
    }

    /**
     * Gets blocking reasons for an onboarding record
     * @param onboardingId Onboarding ID to check
     * @return List of blocking reason strings
     */
    public static List<String> getBlockingReasons(Id onboardingId) {
        List<String> reasons = new List<String>();
        
        if (onboardingId == null) {
            return reasons;
        }
        
        // Query onboarding record
        List<Onboarding__c> onboardings = [
            SELECT Id, Onboarding_Status__c, Vendor_Customization__c
            FROM Onboarding__c
            WHERE Id = :onboardingId
            LIMIT 1
        ];
        
        if (onboardings.isEmpty()) {
            return reasons;
        }
        
        Onboarding__c ob = onboardings[0];
        
        // Check status
        if (ob.Onboarding_Status__c == 'Denied') {
            reasons.add('Onboarding status is Denied');
        }
        
        // Query requirements
        List<Onboarding_Requirement__c> requirements = [
            SELECT Id, Status__c, Vendor_Program_Requirement__r.Name
            FROM Onboarding_Requirement__c
            WHERE Onboarding__c = :onboardingId
                  AND Status__c IN ('Denied', 'Incomplete')
        ];
        
        for (Onboarding_Requirement__c req : requirements) {
            if (req.Status__c == 'Denied') {
                String reqName = req.Vendor_Program_Requirement__r != null && 
                                String.isNotBlank(req.Vendor_Program_Requirement__r.Name) 
                                ? req.Vendor_Program_Requirement__r.Name 
                                : 'Requirement ' + req.Id;
                reasons.add('Requirement denied: ' + reqName);
            }
        }
        
        // TODO: Add stage dependency blocking reasons
        // This would require checking OnboardingStageDependencyService
        // but that service is for vendor program onboarding, not dealer onboarding
        // For dealer onboarding, we primarily check requirement status
        
        return reasons;
    }

    /**
     * Checks if an onboarding is at risk
     * An onboarding is at risk if it has incomplete requirements for more than N days
     * @param onboardingId Onboarding ID to check
     * @param daysThreshold Number of days threshold (default 7)
     * @return True if at risk, false otherwise
     */
    public static Boolean isAtRisk(Id onboardingId, Integer daysThreshold) {
        if (onboardingId == null) {
            return false;
        }
        
        if (daysThreshold == null || daysThreshold <= 0) {
            daysThreshold = 7; // Default to 7 days
        }
        
        // Query onboarding record
        List<Onboarding__c> onboardings = [
            SELECT Id, CreatedDate, Onboarding_Status__c
            FROM Onboarding__c
            WHERE Id = :onboardingId
            LIMIT 1
        ];
        
        if (onboardings.isEmpty()) {
            return false;
        }
        
        Onboarding__c ob = onboardings[0];
        
        // Check if status is already terminal
        if (ob.Onboarding_Status__c == 'Complete' || 
            ob.Onboarding_Status__c == 'Denied' || 
            ob.Onboarding_Status__c == 'Expired') {
            return false;
        }
        
        // Check age
        if (ob.CreatedDate == null) {
            return false;
        }
        
        Date createdDate = Date.valueOf(ob.CreatedDate);
        Integer ageInDays = createdDate.daysBetween(Date.today());
        
        if (ageInDays <= daysThreshold) {
            return false; // Not old enough to be at risk
        }
        
        // Check for incomplete requirements
        List<Onboarding_Requirement__c> incompleteReqs = [
            SELECT Id
            FROM Onboarding_Requirement__c
            WHERE Onboarding__c = :onboardingId
                  AND Status__c = 'Incomplete'
            LIMIT 1
        ];
        
        return !incompleteReqs.isEmpty();
    }

    /**
     * Gets blocking information for multiple onboarding records
     * @param onboardingIds List of onboarding IDs to check
     * @return Map of onboarding ID to blocking info (blocked flag, at-risk flag, reasons)
     */
    public static Map<Id, BlockingInfo> getBlockingInfoBulk(List<Id> onboardingIds) {
        Map<Id, BlockingInfo> result = new Map<Id, BlockingInfo>();
        
        if (onboardingIds == null || onboardingIds.isEmpty()) {
            return result;
        }
        
        // Initialize all records
        for (Id obId : onboardingIds) {
            result.put(obId, new BlockingInfo());
        }
        
        // Query onboarding records
        List<Onboarding__c> onboardings = [
            SELECT Id, Onboarding_Status__c, CreatedDate, Vendor_Customization__c
            FROM Onboarding__c
            WHERE Id IN :onboardingIds
        ];
        
        // Query requirements
        List<Onboarding_Requirement__c> requirements = [
            SELECT Id, Onboarding__c, Status__c, Vendor_Program_Requirement__r.Name
            FROM Onboarding_Requirement__c
            WHERE Onboarding__c IN :onboardingIds
                  AND Status__c IN ('Denied', 'Incomplete')
        ];
        
        // Group requirements by onboarding
        Map<Id, List<Onboarding_Requirement__c>> reqsByOnboarding = new Map<Id, List<Onboarding_Requirement__c>>();
        for (Onboarding_Requirement__c req : requirements) {
            if (!reqsByOnboarding.containsKey(req.Onboarding__c)) {
                reqsByOnboarding.put(req.Onboarding__c, new List<Onboarding_Requirement__c>());
            }
            reqsByOnboarding.get(req.Onboarding__c).add(req);
        }
        
        // Process each onboarding
        for (Onboarding__c ob : onboardings) {
            BlockingInfo info = result.get(ob.Id);
            if (info == null) {
                continue;
            }
            
            // Check status
            if (ob.Onboarding_Status__c == 'Denied') {
                info.isBlocked = true;
                info.reasons.add('Onboarding status is Denied');
            }
            
            // Check requirements
            List<Onboarding_Requirement__c> reqs = reqsByOnboarding.get(ob.Id);
            if (reqs != null) {
                for (Onboarding_Requirement__c req : reqs) {
                    if (req.Status__c == 'Denied') {
                        info.isBlocked = true;
                        String reqName = req.Vendor_Program_Requirement__r != null && 
                                       String.isNotBlank(req.Vendor_Program_Requirement__r.Name) 
                                       ? req.Vendor_Program_Requirement__r.Name 
                                       : 'Requirement ' + req.Id;
                        info.reasons.add('Requirement denied: ' + reqName);
                    } else if (req.Status__c == 'Incomplete') {
                        // Check if at risk
                        if (ob.CreatedDate != null) {
                            Date createdDate = Date.valueOf(ob.CreatedDate);
                            Integer ageInDays = createdDate.daysBetween(Date.today());
                            if (ageInDays > 7) {
                                info.isAtRisk = true;
                                info.reasons.add('Requirement incomplete for ' + ageInDays + ' days');
                            }
                        }
                    }
                }
            }
        }
        
        return result;
    }

    /**
     * Inner class for blocking information
     */
    public class BlockingInfo {
        public Boolean isBlocked = false;
        public Boolean isAtRisk = false;
        public List<String> reasons = new List<String>();
    }
}
/**
 * Utility class for mapping technical onboarding statuses to user-friendly stages
 * for display in the front end. This class does NOT modify data - it only provides
 * display-friendly labels for end users.
 * 
 * Admins will continue to see technical statuses in the backend.
 * End users see simplified stages: In Progress, Review Pending, Completed
 */
public class OnboardingApplicationStatusMapper {
    
    /**
     * Maps a technical status to a user-friendly stage for display
     * @param technicalStatus The technical status from Salesforce (e.g., "Draft", "In Process", "Pending Review")
     * @param isAdmin Whether the current user is an admin (admins see technical statuses)
     * @return User-friendly stage label for display (In Progress, Review Pending, Completed)
     */
    public static String getUserFacingStage(String technicalStatus, Boolean isAdmin) {
        // Admins see technical statuses as-is
        if (isAdmin) {
            return technicalStatus != null ? technicalStatus : 'In Progress';
        }
        
        // End users see simplified stages
        if (technicalStatus == null || String.isBlank(technicalStatus)) {
            return 'In Progress';
        }
        
        String normalizedStatus = technicalStatus.toLowerCase().trim();
        
        // Map technical statuses to user-friendly stages
        if (normalizedStatus == 'draft' || 
            normalizedStatus == 'in process' ||
            normalizedStatus == 'inprogress') {
            return 'In Progress';
        } else if (normalizedStatus == 'pending review' ||
                   normalizedStatus == 'pendingreview' ||
                   normalizedStatus == 'pending approval' ||
                   normalizedStatus == 'pendingapproval' ||
                   normalizedStatus == 'awaiting review' ||
                   normalizedStatus == 'awaitingreview' ||
                   normalizedStatus == 'under review' ||
                   normalizedStatus == 'underreview') {
            return 'Review Pending';
        } else if (normalizedStatus == 'complete' ||
                   normalizedStatus == 'completed' ||
                   normalizedStatus == 'approved') {
            return 'Completed';
        }
        
        // Default fallback
        return 'In Progress';
    }
    
    /**
     * Gets the CSS class variant for the status badge/pill
     * @param userFacingStage The user-friendly stage
     * @return CSS variant name (brand, warning, success)
     */
    public static String getStatusVariant(String userFacingStage) {
        if (userFacingStage == null) {
            return 'brand';
        }
        
        String normalized = userFacingStage.toLowerCase().trim();
        
        if (normalized == 'in progress') {
            return 'brand'; // Blue/primary color
        } else if (normalized == 'review pending') {
            return 'warning'; // Orange/amber color
        } else if (normalized == 'completed') {
            return 'success'; // Green color
        }
        
        return 'brand'; // Default
    }
    
    /**
     * Gets the icon name for the status
     * @param userFacingStage The user-friendly stage
     * @return Lightning icon name
     */
    public static String getStatusIcon(String userFacingStage) {
        if (userFacingStage == null) {
            return 'utility:clock';
        }
        
        String normalized = userFacingStage.toLowerCase().trim();
        
        if (normalized == 'in progress') {
            return 'utility:clock';
        } else if (normalized == 'review pending') {
            return 'utility:approval';
        } else if (normalized == 'completed') {
            return 'utility:check';
        }
        
        return 'utility:clock'; // Default
    }
    
    /**
     * Checks if the current user is an admin based on profile or permission set
     * This is a simple check - can be enhanced with custom metadata
     * @return True if user is an admin
     */
    public static Boolean isCurrentUserAdmin() {
        // Check if user has System Administrator profile
        String profileName = UserInfo.getProfileId() != null 
            ? [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1].Name
            : '';
        
        if (profileName == 'System Administrator') {
            return true;
        }
        
        // TODO: Add permission set check if needed
        // Example: Check if user has 'Onboarding_Admin' permission set
        
        return false;
    }
    
    /**
     * Gets user-facing stage for the current user (checks admin status automatically)
     * @param technicalStatus The technical status
     * @return User-friendly stage label
     */
    public static String getUserFacingStageForCurrentUser(String technicalStatus) {
        return getUserFacingStage(technicalStatus, isCurrentUserAdmin());
    }
}
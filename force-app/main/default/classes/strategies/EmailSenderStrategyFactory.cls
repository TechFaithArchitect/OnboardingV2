/**
 * Factory for creating email sender strategies
 * Centralizes strategy selection logic
 */
public with sharing class EmailSenderStrategyFactory {
    
    private static final Set<String> VALID_SENDER_TYPES = new Set<String>{ 'CurrentUser', 'OrgWide' };
    private static final Map<String, EmailSenderStrategy> STRATEGY_CACHE = new Map<String, EmailSenderStrategy>();
    
    /**
     * Gets the appropriate email sender strategy for a sender type
     * @param senderType The sender type (e.g., 'CurrentUser', 'OrgWide')
     * @return The email sender strategy
     * @throws IllegalArgumentException if sender type is invalid
     */
    public static EmailSenderStrategy getStrategy(String senderType) {
        if (String.isBlank(senderType)) {
            senderType = 'CurrentUser'; // Default
        }
        
        // Validate sender type
        if (!VALID_SENDER_TYPES.contains(senderType)) {
            throw new IllegalArgumentException(
                'Invalid senderType "' + senderType + '". Valid values are: ' + 
                String.join(new List<String>(VALID_SENDER_TYPES), ', ')
            );
        }
        
        // Check cache first
        if (STRATEGY_CACHE.containsKey(senderType)) {
            return STRATEGY_CACHE.get(senderType);
        }
        
        // Create strategy based on sender type
        EmailSenderStrategy strategy;
        switch on senderType {
            when 'CurrentUser' {
                strategy = new CurrentUserSenderStrategy();
            }
            when 'OrgWide' {
                strategy = new OrgWideSenderStrategy();
            }
        }
        
        // Cache the strategy
        STRATEGY_CACHE.put(senderType, strategy);
        return strategy;
    }
    
    /**
     * Gets the set of valid sender types
     * @return Set of valid sender type strings
     */
    public static Set<String> getValidSenderTypes() {
        return VALID_SENDER_TYPES.clone();
    }
    
    /**
     * Clears the strategy cache (useful for testing)
     */
    @TestVisible
    private static void clearCache() {
        STRATEGY_CACHE.clear();
    }
}
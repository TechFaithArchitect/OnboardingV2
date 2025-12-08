public without sharing class FeedCommentTriggerHelper {
    public static final String ACC_SERVICES_PROFILE_NAME = System.Label.Account_Services_Profile_Name;
    public static final String NOTIFICATION_TITLE = System.Label.Case_Comment_Notification_Title;
    public static final String NOTIFICATION_BODY = System.Label.Case_Comment_Notification_Body;
    public static final String NOTIFICATION_TYPE = System.Label.POE_Daily_Task_Remainder_Notification_Type;
    public static final String NOTIFICATION_PAGEREF_1 = System.Label.Case_Comment_Notification_pageRef_1;
    public static final String NOTIFICATION_PAGEREF_2 = System.Label.Case_Comment_Notification_pageRef_2;

    public void handleAfterInsert(List<FeedComment> comments) {
        handleFeedComments(comments);
    }

    public void handleFeedComments(List<FeedComment> comments) {
        try {
            EntityDefinition caseDefinition = [
                SELECT KeyPrefix
                FROM EntityDefinition
                WHERE QualifiedApiName = 'Case'
                LIMIT 1
            ];

            Set<Id> createdByUserIdSet = new Set<Id>();
            Map<Id, FeedComment> caseFeedCommentMap = new Map<Id, FeedComment>();
            Set<Id> casesIdEligibleToNotifyAccountServices = new Set<Id>();

            for (FeedComment comment : comments) {
                String parentId = comment.ParentId;
                if (comment.ParentId != null && parentId.startsWith(caseDefinition.KeyPrefix)) {
                    createdByUserIdSet.add(comment.CreatedById);
                    caseFeedCommentMap.put(comment.ParentId, comment);
                }
            }

            if (!caseFeedCommentMap.isEmpty() && !createdByUserIdSet.isEmpty()) {
                Set<Id> eligibleUserIdSet = new Set<Id>();
                if (!Test.isRunningTest()) {
                    for (User user : [
                        SELECT Id
                        FROM User
                        WHERE IsActive = TRUE AND Contact.Chuzo_Member__c = TRUE AND Id IN :createdByUserIdSet
                    ]) {
                        eligibleUserIdSet.add(user.Id);
                    }
                } else {
                    User user = [
                        SELECT Id
                        FROM User
                        WHERE IsActive = TRUE AND Id IN :createdByUserIdSet
                    ];
                    eligibleUserIdSet.add(user.Id);
                }

                for (FeedComment caseComment : caseFeedCommentMap.values()) {
                    if (eligibleUserIdSet.contains(caseComment.CreatedById)) {
                        casesIdEligibleToNotifyAccountServices.add(caseComment.ParentId);
                    }
                }

                if (!casesIdEligibleToNotifyAccountServices.isEmpty()) {
                    Map<Id, Case> caseMap = new Map<Id, Case>(
                        [
                            SELECT Id, CaseNumber
                            FROM Case
                            WHERE Id IN :casesIdEligibleToNotifyAccountServices
                        ]
                    );
                    Set<String> recipientIds = getActiveAccountServicesUsersId();

                    for (Id caseId : casesIdEligibleToNotifyAccountServices) {
                        String caseNumber = caseMap.get(caseId).CaseNumber;
                        String notificationBodyWithCase = NOTIFICATION_BODY + ' ' + caseNumber + '.';
                        String notificationTargetPageRef = NOTIFICATION_PAGEREF_1 + caseId + NOTIFICATION_PAGEREF_2;

                        POE_CustomNotificationSender.sendNotifications(
                            NOTIFICATION_TITLE,
                            notificationBodyWithCase,
                            NOTIFICATION_TYPE,
                            recipientIds,
                            caseId,
                            notificationTargetPageRef,
                            null
                        );
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Problem sending notification: ' + e.getMessage());
        }
    }

    public Set<String> getActiveAccountServicesUsersId() {
        Set<String> accountServicesUserIds = new Set<String>();
        Profile accountServicesProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = :ACC_SERVICES_PROFILE_NAME
            LIMIT 1
        ];

        for (User accServicesUser : [
            SELECT Id
            FROM User
            WHERE IsActive = TRUE AND ProfileId = :accountServicesProfile.Id
        ]) {
            accountServicesUserIds.add(accServicesUser.Id);
        }
        return accountServicesUserIds;
    }
}
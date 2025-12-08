global with sharing class ContentDistributionCreator {

    global class ContentDistributionRequest {
        @InvocableVariable(label='ContentVersion ID' description='The ID of the ContentVersion to create a public link for.' required=true)
        public Id contentVersionId;
    }

    global class ContentDistributionResult {
        @InvocableVariable(label='Distribution Public URL' description='The publicly accessible URL for the content.')
        public String distributionPublicUrl;

        @InvocableVariable(label='File Force Public URL' description='Constructed https://<myDomain>.file.force.com public URL for direct delivery.')
        public String fileForcePublicUrl;

        @InvocableVariable(label='Documentforce Public URL' description='Constructed https://<myDomain>.documentforce.com public URL for direct delivery.')
        public String documentForcePublicUrl;

        @InvocableVariable(label='Is Video' description='True if the uploaded file is a video type.')
        public Boolean isVideo;

        @InvocableVariable(label='Error Message' description='Error message if the operation failed.')
        public String errorMessage;

        @InvocableVariable(label='Is Success' description='True if the operation was successful.')
        public Boolean isSuccess;
    }

    @InvocableMethod(label='Create Public File Link' description='Creates a public ContentDistribution link for a file.' category='Content')
    public static List<ContentDistributionResult> createPublicLink(List<ContentDistributionRequest> requests) {
        List<ContentDistributionResult> results = new List<ContentDistributionResult>();
        List<Id> contentVersionIds = new List<Id>();

        for(ContentDistributionRequest req : requests) {
            if(req.contentVersionId != null){
                contentVersionIds.add(req.contentVersionId);
            }
        }
        
        if (contentVersionIds.isEmpty()) {
            return results;
        }

        Map<Id, ContentVersion> contentVersionMap = new Map<Id, ContentVersion>([
            SELECT Id, Title, FileType, FileExtension FROM ContentVersion WHERE Id IN :contentVersionIds
        ]);

        List<ContentDistribution> distributionsToInsert = new List<ContentDistribution>();

        for (ContentDistributionRequest req : requests) {
            ContentDistribution cd = new ContentDistribution();
            if (contentVersionMap.containsKey(req.contentVersionId)) {
                cd.Name = contentVersionMap.get(req.contentVersionId).Title;
            } else {
                cd.Name = 'Shared File';
            }
            cd.ContentVersionId = req.contentVersionId;
            cd.PreferencesAllowViewInBrowser = true;
            cd.PreferencesLinkLatestVersion = true;
            cd.PreferencesNotifyOnVisit = false;
            cd.PreferencesPasswordRequired = false;
            cd.PreferencesAllowOriginalDownload = true;
            distributionsToInsert.add(cd);
        }

        try {
            if (!distributionsToInsert.isEmpty()) {
                insert distributionsToInsert;
            }

            Map<Id, ContentDistribution> insertedCdsMap = new Map<Id, ContentDistribution>([
                SELECT Id, ContentVersionId, DistributionPublicUrl 
                FROM ContentDistribution 
                WHERE Id IN :distributionsToInsert
            ]);

            for(ContentDistributionRequest req : requests) {
                ContentDistributionResult res = new ContentDistributionResult();
                Boolean foundMatch = false;
                
                for(ContentDistribution cd : insertedCdsMap.values()){
                    if(cd.ContentVersionId == req.contentVersionId){
                        res.distributionPublicUrl = cd.DistributionPublicUrl;
                        ContentVersion cv = contentVersionMap.get(req.contentVersionId);
                        String ext = cv != null ? String.valueOf(cv.FileExtension).toLowerCase() : null;
                        String fileType = cv != null ? String.valueOf(cv.FileType).toLowerCase() : null;
                        Set<String> videoExtensions = new Set<String>{'mp4','m4v','mov','avi','wmv','mkv','webm','ogg','ogv'};
                        Boolean looksLikeVideo = (ext != null && videoExtensions.contains(ext)) || (fileType != null && fileType.contains('video'));
                        res.isVideo = looksLikeVideo;
                        try {
                            String orgHost = URL.getOrgDomainUrl().getHost();
                            List<String> hostParts = orgHost != null ? orgHost.split('\\.') : new List<String>();
                            String myDomainPrefix = (hostParts.size() > 0) ? hostParts[0] : '';
                            String fileForceHost;
                            String documentForceHost;
                            if (String.isNotBlank(orgHost) && orgHost.endsWith('.my.salesforce.com')) {
                                fileForceHost = orgHost.replace('.my.salesforce.com', '.file.force.com');
                                documentForceHost = orgHost.replace('.my.salesforce.com', '.documentforce.com');
                            } else {
                                fileForceHost = (String.isBlank(myDomainPrefix)) ? 'file.force.com' : myDomainPrefix + '.file.force.com';
                                documentForceHost = (String.isBlank(myDomainPrefix)) ? 'documentforce.com' : myDomainPrefix + '.documentforce.com';
                            }

                            String organizationId = UserInfo.getOrganizationId();
                            String cdId = cd.Id;
                            String cdIdSubstring = (cdId != null && cdId.length() > 6) ? cdId.substring(3, cdId.length() - 3) : '';

                            String distUrl = cd.DistributionPublicUrl;
                            Integer lastSlashIdx = (distUrl != null) ? distUrl.lastIndexOf('/') : -1;
                            String distHash = (lastSlashIdx != -1 && lastSlashIdx + 1 < distUrl.length()) ? distUrl.substring(lastSlashIdx + 1) : '';

                            String tailPath = '/sfc/dist/version/download/?oid=' + organizationId + '&ids=' + String.valueOf(req.contentVersionId) + '&d=/a/' + cdIdSubstring + '/' + distHash + '&operationContext=DELIVERY&dpt=';
                            res.fileForcePublicUrl = 'https://' + fileForceHost + tailPath;
                            res.documentForcePublicUrl = 'https://' + documentForceHost + tailPath;
                        } catch (Exception ignored) {
                        }
                        res.isSuccess = true;
                        res.errorMessage = null;
                        foundMatch = true;
                        break; 
                    }
                }

                if(!foundMatch){
                    res.isSuccess = false;
                    res.errorMessage = 'Could not find the created ContentDistribution record for ContentVersionId: ' + req.contentVersionId;
                }
                results.add(res);
            }
        } catch (Exception e) {
            for (ContentDistributionRequest req : requests) {
                ContentDistributionResult res = new ContentDistributionResult();
                res.isSuccess = false;
                res.errorMessage = e.getMessage();
                results.add(res);
            }
        }

        return results;
    }
}
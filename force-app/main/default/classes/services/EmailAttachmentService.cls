public with sharing class EmailAttachmentService {
    public static List<Messaging.EmailFileAttachment> getAttachments(List<Id> attachmentIds) {
        List<Messaging.EmailFileAttachment> results = new List<Messaging.EmailFileAttachment>();
        if (attachmentIds == null || attachmentIds.isEmpty()) return results;

        // Load Legacy Attachments
        List<Attachment> legacyAttachments = EmailAttachmentRepository.getLegacyAttachments(attachmentIds);
        for (Attachment a : legacyAttachments) {
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setFileName(a.Name);
            efa.setBody(a.Body);
            efa.setContentType(a.ContentType);
            results.add(efa);
        }

        // Load ContentVersion files
        List<ContentVersion> contentVersions = EmailAttachmentRepository.getContentVersions(attachmentIds);
        for (ContentVersion cv : contentVersions) {
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setFileName(cv.Title + '.' + cv.FileExtension);
            efa.setBody(cv.VersionData);
            results.add(efa);
        }

        return results;
    }
}
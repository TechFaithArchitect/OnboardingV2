public class EmailTemplateDTO {
    public Id id;
    public String developerName;
    public String name;
    public String folder;
    public String subject;
    public Boolean isActive;
    public String commType;

    public EmailTemplateDTO() {}

    public EmailTemplateDTO(EmailTemplate t) {
        this.id = t.Id;
        this.developerName = t.DeveloperName;
        this.name = t.Name;
        this.folder = t.FolderName;
        this.subject = String.isNotBlank(t.Subject) ? t.Subject : 'Unfiled';
        this.isActive = t.IsActive;
        this.commType = deriveCommType(t.Name);
    }

    private String deriveCommType(String templateName) {
        if (templateName.containsIgnoreCase('Welcome')) return 'Welcome';
        if (templateName.containsIgnoreCase('Reminder')) return 'Reminder';
        if (templateName.containsIgnoreCase('Completion')) return 'Completion';
        return 'Custom';
    }

    public Communication_Template__c toSObject() {
        return new Communication_Template__c(
            Name = name,
            DeveloperName__c = developerName,
            Folder_Name__c = folder,
            Email_Subject__c = subject,
            Communication_Type__c = commType,
            Active__c = isActive,
            Email_Template_Id__c = id
        );
    }

    public Communication_Template__c toSObject(Communication_Template__c existing) {
        existing.Folder_Name__c = folder;
        existing.Email_Subject__c = subject;
        existing.Communication_Type__c = commType;
        existing.Active__c = isActive;
        existing.Email_Template_Id__c = id;
        return existing;
    }

    public Boolean hasChanges(Communication_Template__c existing) {
        return (
            existing.Folder_Name__c != folder ||
            existing.Email_Subject__c != subject ||
            existing.Communication_Type__c != commType ||
            existing.Active__c != isActive ||
            existing.Email_Template_Id__c != id
        );
    }
}

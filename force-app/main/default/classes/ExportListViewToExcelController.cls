public with sharing class ExportListViewToExcelController {
    public String fileName {get; set;}
    public Utilities.ListViewWrapper wrapper {get; set;}
    public ExportListViewToExcelController(ApexPages.StandardSetController stdSetController){
        system.debug(stdSetController);
        
    }
    public void fetchListviewRecords() {
        String listurl = apexpages.currentpage().getparameters().get('vfRetURLInSFX');
        String listId = listurl.substringAfter('filterName=');
       // String objName = 'ServiceResource';
        String result = listurl.substringAfter('o/');
        String objName = result.substringBefore('/'); 
        String listNames = [SELECT Name FROM ListView WHERE Id =:listId limit 1].Name;
        fileName= objName +'_'+listNames.replace(' ','_');
        // Populate wrapper
        wrapper = new Utilities.ListViewWrapper(objName, listId);
        system.debug('wrapper:'+wrapper);
        wrapper.fetchListViewDetail();
    }
}
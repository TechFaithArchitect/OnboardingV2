/**
* @description       : Handler Class PV_ProductConsumedTrigger
* @author            : Impaqtive DevTeam
* @group             :
* @last modified on  : 24-07-2023
* @last modified by  : Impaqtive DevTeam
* Modifications Log
* Ver   Date         Author            Modification
* 1.0                      Initial Version
**/
public class PV_ProductConsumedTriggerHandler {
    static String DIRECTV = Label.DIRECTV;
    static String ViaSat = Label.ViaSat;
    public static void createAsset(Map<Id, ProductConsumed> productConsumedMap){
        Map<Id,Id> woProdIds = New Map<Id,Id>();
        Map<Id,Id> woAccMap = new Map<Id,Id>();
        try{
            List<ProductConsumed> pcList = [SELECT Id, WorkOrderId, Product2Id FROM ProductConsumed WHERE Id IN: productConsumedMap.keySet()];
            for(ProductConsumed pc : pcList){
                woProdIds.put(pc.WorkOrderId,pc.Product2Id);
            }
            for(WorkOrder wo:[SELECT Id,Vendor__c, AccountId FROM WorkOrder WHERE Id IN: woProdIds.keySet()]){
                if(wo.Vendor__c == DIRECTV || wo.Vendor__c == ViaSat){
                    woAccMap.put(wo.Id, wo.AccountId);
                }                
            }
            List<Asset> assetList = New List<Asset>();
            for(ID aID : woProdIds.keySet()){
                for(ID bID : woAccMap.keySet()){
                    if(aID == bID){
                        Asset ast = new Asset();
                        ast.Name = woAccMap.get(bID)+' - '+ woProdIds.get(aID);
                        ast.AccountId = woAccMap.get(bID);
                        ast.Product2Id = woProdIds.get(aID);
                        assetList.add(ast);
                    }
                }
            }
            insert assetList;
        }catch(Exception ex) {
            ExceptionUtil.publishException('PV_ProductConsumedTriggerHandler.handleAfterInsert', ex.getLineNumber(), ex.getMessage(), ex.getStackTraceString());
        }
    }
}
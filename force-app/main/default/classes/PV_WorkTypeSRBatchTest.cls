@isTest
public class PV_WorkTypeSRBatchTest {
    static testmethod void test() {
        
        System.runAs(new User(Id = Userinfo.getUserId())){
            Account acct= PV_TestDataFactory.createAccount('TestAcc', true);
            contact con = PV_TestDataFactory.createContact('firstName', 'lastName',true,acct);            
            OperatingHours opHrs= PV_TestDataFactory.createOperatingHours('East - Mon-Fri 8am - 5pm', true);
            ServiceTerritory pst = PV_TestDataFactory.createParentServiceTerritory(true, 'ST-01',opHrs);
            pst.Account__c = acct.Id;
            ServiceTerritory childServiceTerritory = PV_TestDataFactory.createServiceTerritoryForAccount(true, acct, pst);
            
            User usr = PV_TestDataFactory.createTechnicianUser(true,con);
            PV_TestDataFactory.assignPermissionSetGroupToUser(true, usr, 'FSL_Technician');
            
            Skill TMoFB_Meraki_MG51_MG51e = [SELECT Id, DeveloperName FROM Skill WHERE DeveloperName = 'TMoFB_Meraki_MG51_MG51e'];
            Skill TMoFB_Cradlepoint_E300 = [SELECT Id, DeveloperName FROM Skill WHERE DeveloperName = 'TMoFB_Cradlepoint_E300'];
            Skill TMoFB_Cradlepoint_E3000 = [SELECT Id, DeveloperName FROM Skill WHERE DeveloperName = 'TMoFB_Cradlepoint_E3000'];
            Skill TMoFB_InseegoMiFiXPRO5G = [SELECT Id, DeveloperName FROM Skill WHERE DeveloperName = 'TMoFB_InseegoMiFiXPRO5G'];
            Skill TMoFB_Cradlepoint_E320 = [SELECT Id, DeveloperName FROM Skill WHERE DeveloperName = 'TMoFB_Cradlepoint_E320'];
            Skill TMoFB_Cradlepoint_W1850 = [SELECT Id, DeveloperName FROM Skill WHERE DeveloperName = 'TMoFB_Cradlepoint_W1850'];
            Skill TMoFB_Cradlepoint_W1855 = [SELECT Id, DeveloperName FROM Skill WHERE DeveloperName = 'TMoFB_Cradlepoint_W1855'];
            Skill TMoFB_Cradlepoint_W2005 = [SELECT Id, DeveloperName FROM Skill WHERE DeveloperName = 'TMoFB_Cradlepoint_W2005'];
            Skill TMoFB_Cradlepoint_W4005 = [SELECT Id, DeveloperName FROM Skill WHERE DeveloperName = 'TMoFB_Cradlepoint_W4005'];
            Skill TMoFB_Inseego_FW2000 = [SELECT Id, DeveloperName FROM Skill WHERE DeveloperName = 'TMoFB_Inseego_FW2000'];
            Skill TMoFB_Inseego_FX2000 = [SELECT Id, DeveloperName FROM Skill WHERE DeveloperName = 'TMoFB_Inseego_FX2000'];
            Skill TMoFB_Inseego_FX3100 = [SELECT Id, DeveloperName FROM Skill WHERE DeveloperName = 'TMoFB_Inseego_FX3100'];
            Skill TMoFB_5G_Gateway_S1_N2 = [SELECT Id, DeveloperName FROM Skill WHERE DeveloperName = 'TMoFB_5G_Gateway_S1_N2'];
            Skill TMoFB_SIM_Swap = [SELECT Id, DeveloperName FROM Skill WHERE DeveloperName = 'TMoFB_SIM_Swap'];
            
            // Inserting Work Types
            List<WorkType> workTypeList = new List<WorkType>();
            
            WorkType wtHome1Int = new WorkType(Name = 'T-Mobile Home Office Install - Cellular Gateway Only', Work_Type_Code__c = 'HOME1INT', EstimatedDuration = 90, Vendor__c = 'T-Mobile');
            workTypeList.add(wtHome1Int);
            
            WorkType wtHome1Ext = new WorkType(Name = 'T-Mobile Home Office Install - w/ External Antenna', Work_Type_Code__c = 'HOME1EXT', EstimatedDuration = 90, Vendor__c = 'T-Mobile');
            workTypeList.add(wtHome1Ext);
            
            WorkType wtHome1ExtCs = new WorkType(Name = 'T-Mobile Home Office Install - w/ External Antenna(Contractor Supplied)', Work_Type_Code__c = 'HOME1EXTCS', EstimatedDuration = 90, Vendor__c = 'T-Mobile');
            workTypeList.add(wtHome1ExtCs);
            
            WorkType comm1IntLsow = new WorkType(Name = 'T-Mobile Commercial Install - Cellular Gateway Only - LSOW(No Site Survey)', Work_Type_Code__c = 'COMM1INTLSOW', EstimatedDuration = 90, Vendor__c = 'T-Mobile');
            workTypeList.add(comm1IntLsow);
            
            WorkType comm2Int = new WorkType(Name = 'T-Mobile Commercial Install - Cellular Gateway Only', Work_Type_Code__c = 'COMM2INT', EstimatedDuration = 90, Vendor__c = 'T-Mobile');
            workTypeList.add(comm2Int);
            
            WorkType comm2Ext = new WorkType(Name = 'T-Mobile Commercial Install - w/ External Antenna', Work_Type_Code__c = 'COMM2EXT', EstimatedDuration = 90, Vendor__c = 'T-Mobile');
            workTypeList.add(comm2Ext);
            
            WorkType comm2ExtCs = new WorkType(Name = 'T-Mobile Commercial Install - w/ External Antenna(Contractor Supplied)', Work_Type_Code__c = 'COMM2EXTCS', EstimatedDuration = 90, Vendor__c = 'T-Mobile');
            workTypeList.add(comm2ExtCs);
            
            WorkType comm1Int = new WorkType(Name = 'T-Mobile Commercial Install - Cellular Gateway Only', Work_Type_Code__c = 'COMM1INT', EstimatedDuration = 90, Vendor__c = 'T-Mobile');
            workTypeList.add(comm1Int);
            
            WorkType comm1Ext = new WorkType(Name = 'T-Mobile Commercial Install - w/ External Antenna', Work_Type_Code__c = 'COMM1EXT', EstimatedDuration = 90, Vendor__c = 'T-Mobile');
            workTypeList.add(comm1Ext);
            
            WorkType comm1ExtCs = new WorkType(Name = 'T-Mobile Commercial Install - w/External Antenna(Contractor Supplied)', Work_Type_Code__c = 'COMM1EXTCS', EstimatedDuration = 90, Vendor__c = 'T-Mobile');
            workTypeList.add(comm1ExtCs);
            
            WorkType siteSurvey = new WorkType(Name = 'T-Mobile Site Survey', Work_Type_Code__c = 'SITE SURVEY', EstimatedDuration = 90, Vendor__c = 'T-Mobile');
            workTypeList.add(siteSurvey);
            
            WorkType hoServiceCall = new WorkType(Name = 'T-Mobile Home Office Service Call', Work_Type_Code__c = 'HO SERVICE CALL', EstimatedDuration = 90, Vendor__c = 'T-Mobile');
            workTypeList.add(hoServiceCall);
            
            WorkType comServiceCall = new WorkType(Name = 'T-Mobile Commercial Service Call', Work_Type_Code__c = 'COM SERVICE CALL', EstimatedDuration = 90, Vendor__c = 'T-Mobile');
            workTypeList.add(comServiceCall);
            
            WorkType comServiceCall4Hour = new WorkType(Name = 'T-Mobile Commercial Service Call - 4 Hour', Work_Type_Code__c = 'COM SERVICE CALL-4', EstimatedDuration = 90, Vendor__c = 'T-Mobile');
            workTypeList.add(comServiceCall4Hour);
            
            WorkType comServiceCall8Hour = new WorkType(Name = 'T-Mobile Commercial Service Call - 8 Hour', Work_Type_Code__c = 'COM SERVICE CALL-8', EstimatedDuration = 90, Vendor__c = 'T-Mobile');
            workTypeList.add(comServiceCall8Hour);
            
            WorkType comServiceCall12Hour = new WorkType(Name = 'T-Mobile Commercial Service Call - 12 Hour', Work_Type_Code__c = 'COM SERVICE CALL-12', EstimatedDuration = 90, Vendor__c = 'T-Mobile');
            workTypeList.add(comServiceCall12Hour);
            
            WorkType comServiceCall24Hour = new WorkType(Name = 'T-Mobile Commercial Service Call - 24 hour', Work_Type_Code__c = 'COM SERVICE CALL-24', EstimatedDuration = 90, Vendor__c = 'T-Mobile');
            workTypeList.add(comServiceCall24Hour);
            
            WorkType simswap = new WorkType(Name = 'SIM Swap', Work_Type_Code__c = 'SIMSWAP', EstimatedDuration = 60, Vendor__c = 'T-Mobile');
            workTypeList.add(simswap);
            
            insert workTypeList;
            
            
            
            List<WorkType> allWorkTypes = [SELECT Id, Name FROM WorkType];
            system.debug('---------------------------------'+allWorkTypes.size());
            
            // Create a list to store SkillRequirement records
            List<SkillRequirement> skillReqList = new List<SkillRequirement>();
            
            // Loop through each work type and add skill requirements
            for (WorkType wt : allWorkTypes) {
                SkillRequirement wtypeSkillReq1 = new SkillRequirement();
                wtypeSkillReq1.RelatedRecordId = wt.Id;
                wtypeSkillReq1.SkillId = TMoFB_Meraki_MG51_MG51e.Id;
                skillReqList.add(wtypeSkillReq1);
                SkillRequirement wtypeSkillReq2 = new SkillRequirement();
                wtypeSkillReq2.RelatedRecordId = wt.Id;
                wtypeSkillReq2.SkillId = TMoFB_Cradlepoint_E300.Id;
                skillReqList.add(wtypeSkillReq2);
                SkillRequirement wtypeSkillReq3 = new SkillRequirement();
                wtypeSkillReq3.RelatedRecordId = wt.Id;
                wtypeSkillReq3.SkillId = TMoFB_Cradlepoint_E3000.Id;
                skillReqList.add(wtypeSkillReq3);
                SkillRequirement wtypeSkillReq13 = new SkillRequirement();
                wtypeSkillReq13.RelatedRecordId = wt.Id;
                wtypeSkillReq13.SkillId = TMoFB_InseegoMiFiXPRO5G.Id;
                skillReqList.add(wtypeSkillReq13);
                SkillRequirement wtypeSkillReq4 = new SkillRequirement();
                wtypeSkillReq4.RelatedRecordId = wt.Id;
                wtypeSkillReq4.SkillId = TMoFB_Cradlepoint_E320.Id;
                skillReqList.add(wtypeSkillReq4);
                SkillRequirement wtypeSkillReq5 = new SkillRequirement();
                wtypeSkillReq5.RelatedRecordId = wt.Id;
                wtypeSkillReq5.SkillId = TMoFB_Cradlepoint_W1850.Id;
                skillReqList.add(wtypeSkillReq5);
                SkillRequirement wtypeSkillReq6 = new SkillRequirement();
                wtypeSkillReq6.RelatedRecordId = wt.Id;
                wtypeSkillReq6.SkillId = TMoFB_Cradlepoint_W1855.Id;
                skillReqList.add(wtypeSkillReq6);
                SkillRequirement wtypeSkillReq7 = new SkillRequirement();
                wtypeSkillReq7.RelatedRecordId = wt.Id;
                wtypeSkillReq7.SkillId = TMoFB_Cradlepoint_W2005.Id;
                skillReqList.add(wtypeSkillReq7);
                SkillRequirement wtypeSkillReq8 = new SkillRequirement();
                wtypeSkillReq8.RelatedRecordId = wt.Id;
                wtypeSkillReq8.SkillId = TMoFB_Cradlepoint_W4005.Id;
                skillReqList.add(wtypeSkillReq8);
                SkillRequirement wtypeSkillReq9 = new SkillRequirement();
                wtypeSkillReq9.RelatedRecordId = wt.Id;
                wtypeSkillReq9.SkillId = TMoFB_Inseego_FW2000.Id;
                skillReqList.add(wtypeSkillReq9);
                SkillRequirement wtypeSkillReq10 = new SkillRequirement();
                wtypeSkillReq10.RelatedRecordId = wt.Id;
                wtypeSkillReq10.SkillId = TMoFB_Inseego_FX2000.Id;
                skillReqList.add(wtypeSkillReq10);
                SkillRequirement wtypeSkillReq11 = new SkillRequirement();
                wtypeSkillReq11.RelatedRecordId = wt.Id;
                wtypeSkillReq11.SkillId = TMoFB_Inseego_FX3100.Id;
                skillReqList.add(wtypeSkillReq11);

                SkillRequirement wtypeSkillReq12 = new SkillRequirement();
                wtypeSkillReq12.RelatedRecordId = wt.Id;
                wtypeSkillReq12.SkillId = TMoFB_5G_Gateway_S1_N2.Id;
                skillReqList.add(wtypeSkillReq12);
                
                SkillRequirement wtypeSkillReq14 = new SkillRequirement();
                wtypeSkillReq14.RelatedRecordId = wt.Id;
                wtypeSkillReq14.SkillId = TMoFB_SIM_Swap.Id;
                skillReqList.add(wtypeSkillReq14); 
                
            }
            insert skillReqList;
            
            
            ServiceResource ServiceRes = PV_TestDataFactory.createServiceResource(true,acct,con,usr);
            ServiceRes.Vendor_Type__c = 'T-Mobile';
            update ServiceRes;
            
            List<ServiceResourceSkill>srSkills = new List<ServiceResourceSkill>();
            ServiceResourceSkill srSkill01 = new ServiceResourceSkill();
            srSkill01.ServiceResourceId = ServiceRes.Id;
            srSkill01.SkillLevel= 80.00;
            srSkill01.EffectiveStartDate = System.Today();
            srSkill01.SkillId = TMoFB_Meraki_MG51_MG51e.Id;
            srSkills.add(srSkill01);
            
            ServiceResourceSkill srSkill02 = new ServiceResourceSkill();
            srSkill02.ServiceResourceId = ServiceRes.Id;
            srSkill02.SkillLevel= 80.00;
            srSkill02.EffectiveStartDate = System.Today();
            srSkill02.SkillId = TMoFB_Cradlepoint_E300.Id;
            srSkills.add(srSkill02);
            
            ServiceResourceSkill srSkill03 = new ServiceResourceSkill();
            srSkill03.ServiceResourceId = ServiceRes.Id;
            srSkill03.SkillLevel= 80.00;
            srSkill03.EffectiveStartDate = System.Today();
            srSkill03.SkillId = TMoFB_Cradlepoint_E3000.Id;
            srSkills.add(srSkill03);
            
            ServiceResourceSkill srSkill04 = new ServiceResourceSkill();
            srSkill04.ServiceResourceId = ServiceRes.Id;
            srSkill04.SkillLevel= 80.00;
            srSkill04.EffectiveStartDate = System.Today();
            srSkill04.SkillId = TMoFB_5G_Gateway_S1_N2.Id;
            srSkills.add(srSkill04);
            
            ServiceResourceSkill srSkill5 = new ServiceResourceSkill();
            srSkill5.ServiceResourceId = ServiceRes.Id;
            srSkill5.SkillLevel= 80.00;
            srSkill5.EffectiveStartDate = System.Today();
            srSkill5.SkillId = TMoFB_Inseego_FX3100.Id;
            srSkills.add(srSkill5);
            
            ServiceResourceSkill srSkill6 = new ServiceResourceSkill();
            srSkill6.ServiceResourceId = ServiceRes.Id;
            srSkill6.SkillLevel= 80.00;
            srSkill6.EffectiveStartDate = System.Today();
            srSkill6.SkillId = TMoFB_Inseego_FX2000.Id;
            srSkills.add(srSkill6);
            
            ServiceResourceSkill srSkill7 = new ServiceResourceSkill();
            srSkill7.ServiceResourceId = ServiceRes.Id;
            srSkill7.SkillLevel= 80.00;
            srSkill7.EffectiveStartDate = System.Today();
            srSkill7.SkillId = TMoFB_Inseego_FW2000.Id;
            srSkills.add(srSkill7);
            
            ServiceResourceSkill srSkill8 = new ServiceResourceSkill();
            srSkill8.ServiceResourceId = ServiceRes.Id;
            srSkill8.SkillLevel= 80.00;
            srSkill8.EffectiveStartDate = System.Today();
            srSkill8.SkillId = TMoFB_Cradlepoint_W4005.Id;
            srSkills.add(srSkill8);
            
            ServiceResourceSkill srSkill9 = new ServiceResourceSkill();
            srSkill9.ServiceResourceId = ServiceRes.Id;
            srSkill9.SkillLevel= 80.00;
            srSkill9.EffectiveStartDate = System.Today();
            srSkill9.SkillId = TMoFB_Cradlepoint_W2005.Id;
            srSkills.add(srSkill9);
            
            ServiceResourceSkill srSkill10 = new ServiceResourceSkill();
            srSkill10.ServiceResourceId = ServiceRes.Id;
            srSkill10.SkillLevel= 80.00;
            srSkill10.EffectiveStartDate = System.Today();
            srSkill10.SkillId = TMoFB_Cradlepoint_W1855.Id;
            srSkills.add(srSkill10);
            
            ServiceResourceSkill srSkill11 = new ServiceResourceSkill();
            srSkill11.ServiceResourceId = ServiceRes.Id;
            srSkill11.SkillLevel= 80.00;
            srSkill11.EffectiveStartDate = System.Today();
            srSkill11.SkillId = TMoFB_Cradlepoint_W1850.Id;
            srSkills.add(srSkill11);
            
            ServiceResourceSkill srSkill12 = new ServiceResourceSkill();
            srSkill12.ServiceResourceId = ServiceRes.Id;
            srSkill12.SkillLevel= 80.00;
            srSkill12.EffectiveStartDate = System.Today();
            srSkill12.SkillId = TMoFB_Cradlepoint_E320.Id;
            srSkills.add(srSkill12);
            
            ServiceResourceSkill srSkill13 = new ServiceResourceSkill();
            srSkill13.ServiceResourceId = ServiceRes.Id;
            srSkill13.SkillLevel= 80.00;
            srSkill13.EffectiveStartDate = System.Today();
            srSkill13.SkillId = TMoFB_InseegoMiFiXPRO5G.Id;
            srSkills.add(srSkill13);
            
            ServiceResourceSkill srSkill14 = new ServiceResourceSkill();
            srSkill14.ServiceResourceId = ServiceRes.Id;
            srSkill14.SkillLevel= 80.00;
            srSkill14.EffectiveStartDate = System.Today();
            srSkill14.SkillId = TMoFB_SIM_Swap.Id;
            srSkills.add(srSkill14);
            insert srSkills;
            
            ServiceTerritoryMember stm = PV_TestDataFactory.createServiceTerritoryMember(true,ServiceRes,childServiceTerritory,'S');
            WorkType wt = PV_TestDataFactory.createWorkType('T_Mobile_Commercial_Install_Cellular_G__c',true);
            WorkOrder wo = PV_TestDataFactory.createWorkOrder(usr,wt,true);
            
            List<Work_Type_SR_Count__c> wtsrList = new List<Work_Type_SR_Count__c>();
            for(Integer i=1;i<=20;i++){
                Work_Type_SR_Count__c wtsr = new Work_Type_SR_Count__c();
                wtsr.No_of_skilled_resources__c = i+1;
                wtsr.Service_Territory__c = childServiceTerritory.Id;
                wtsr.Work_Type__c = wt.Id;
                wtsr.Service_Resource_Percentage__c = ((i/20)*100);
                wtsrList.add(wtsr);
            }
            
            if(!wtsrList.isEmpty()){
                insert wtsrList;
            }
            
            Test.startTest();
            PV_WorkTypeSRBatch b = new PV_WorkTypeSRBatch();
            Database.executeBatch(b);
            Test.stopTest();
            
        }
    }
    static testmethod void test2() {
        
        System.runAs(new User(Id = Userinfo.getUserId())){
            Account acct= PV_TestDataFactory.createAccount('TestAcc', true);
            contact con = PV_TestDataFactory.createContact('firstName', 'lastName',true,acct);            
            OperatingHours opHrs= PV_TestDataFactory.createOperatingHours('East - Mon-Fri 8am - 5pm', true);
            ServiceTerritory pst = PV_TestDataFactory.createParentServiceTerritory(true, 'ST-01',opHrs);
            pst.Account__c = acct.Id;
            ServiceTerritory childServiceTerritory = PV_TestDataFactory.createServiceTerritoryForAccount(true, acct, pst);
            
            User usr = PV_TestDataFactory.createTechnicianUser(true,con);
            PV_TestDataFactory.assignPermissionSetGroupToUser(true, usr, 'FSL_Technician');
            
            Skill TMoFB_Meraki_MG51_MG51e = [SELECT Id, DeveloperName FROM Skill WHERE DeveloperName = 'TMoFB_Meraki_MG51_MG51e'];
            Skill TMoFB_Cradlepoint_E300 = [SELECT Id, DeveloperName FROM Skill WHERE DeveloperName = 'TMoFB_Cradlepoint_E300'];
            Skill TMoFB_Cradlepoint_E3000 = [SELECT Id, DeveloperName FROM Skill WHERE DeveloperName = 'TMoFB_Cradlepoint_E3000'];
            Skill TMoFB_InseegoMiFiXPRO5G = [SELECT Id, DeveloperName FROM Skill WHERE DeveloperName = 'TMoFB_InseegoMiFiXPRO5G'];
            Skill TMoFB_Cradlepoint_E320 = [SELECT Id, DeveloperName FROM Skill WHERE DeveloperName = 'TMoFB_Cradlepoint_E320'];
            Skill TMoFB_Cradlepoint_W1850 = [SELECT Id, DeveloperName FROM Skill WHERE DeveloperName = 'TMoFB_Cradlepoint_W1850'];
            Skill TMoFB_Cradlepoint_W1855 = [SELECT Id, DeveloperName FROM Skill WHERE DeveloperName = 'TMoFB_Cradlepoint_W1855'];
            Skill TMoFB_Cradlepoint_W2005 = [SELECT Id, DeveloperName FROM Skill WHERE DeveloperName = 'TMoFB_Cradlepoint_W2005'];
            Skill TMoFB_Cradlepoint_W4005 = [SELECT Id, DeveloperName FROM Skill WHERE DeveloperName = 'TMoFB_Cradlepoint_W4005'];
            Skill TMoFB_Inseego_FW2000 = [SELECT Id, DeveloperName FROM Skill WHERE DeveloperName = 'TMoFB_Inseego_FW2000'];
            Skill TMoFB_Inseego_FX2000 = [SELECT Id, DeveloperName FROM Skill WHERE DeveloperName = 'TMoFB_Inseego_FX2000'];
            Skill TMoFB_Inseego_FX3100 = [SELECT Id, DeveloperName FROM Skill WHERE DeveloperName = 'TMoFB_Inseego_FX3100'];
            Skill TMoFB_5G_Gateway_S1_N2 = [SELECT Id, DeveloperName FROM Skill WHERE DeveloperName = 'TMoFB_5G_Gateway_S1_N2'];
            Skill TMoFB_SIM_Swap = [SELECT Id, DeveloperName FROM Skill WHERE DeveloperName = 'TMoFB_SIM_Swap'];
            
            // Inserting Work Types
            List<WorkType> workTypeList = new List<WorkType>();
            
            WorkType wtHome1Int = new WorkType(Name = 'T-Mobile Home Office Install - Cellular Gateway Only', Work_Type_Code__c = 'HOME1INT', EstimatedDuration = 90, Vendor__c = 'T-Mobile');
            workTypeList.add(wtHome1Int);
            
            WorkType wtHome1Ext = new WorkType(Name = 'T-Mobile Home Office Install - w/ External Antenna', Work_Type_Code__c = 'HOME1EXT', EstimatedDuration = 90, Vendor__c = 'T-Mobile');
            workTypeList.add(wtHome1Ext);
            
            WorkType wtHome1ExtCs = new WorkType(Name = 'T-Mobile Home Office Install - w/ External Antenna(Contractor Supplied)', Work_Type_Code__c = 'HOME1EXTCS', EstimatedDuration = 90, Vendor__c = 'T-Mobile');
            workTypeList.add(wtHome1ExtCs);
            
            WorkType comm1IntLsow = new WorkType(Name = 'T-Mobile Commercial Install - Cellular Gateway Only - LSOW(No Site Survey)', Work_Type_Code__c = 'COMM1INTLSOW', EstimatedDuration = 90, Vendor__c = 'T-Mobile');
            workTypeList.add(comm1IntLsow);
            
            WorkType comm2Int = new WorkType(Name = 'T-Mobile Commercial Install - Cellular Gateway Only', Work_Type_Code__c = 'COMM2INT', EstimatedDuration = 90, Vendor__c = 'T-Mobile');
            workTypeList.add(comm2Int);
            
            WorkType comm2Ext = new WorkType(Name = 'T-Mobile Commercial Install - w/ External Antenna', Work_Type_Code__c = 'COMM2EXT', EstimatedDuration = 90, Vendor__c = 'T-Mobile');
            workTypeList.add(comm2Ext);
            
            WorkType comm2ExtCs = new WorkType(Name = 'T-Mobile Commercial Install - w/ External Antenna(Contractor Supplied)', Work_Type_Code__c = 'COMM2EXTCS', EstimatedDuration = 90, Vendor__c = 'T-Mobile');
            workTypeList.add(comm2ExtCs);
            
            WorkType comm1Int = new WorkType(Name = 'T-Mobile Commercial Install - Cellular Gateway Only', Work_Type_Code__c = 'COMM1INT', EstimatedDuration = 90, Vendor__c = 'T-Mobile');
            workTypeList.add(comm1Int);
            
            WorkType comm1Ext = new WorkType(Name = 'T-Mobile Commercial Install - w/ External Antenna', Work_Type_Code__c = 'COMM1EXT', EstimatedDuration = 90, Vendor__c = 'T-Mobile');
            workTypeList.add(comm1Ext);
            
            WorkType comm1ExtCs = new WorkType(Name = 'T-Mobile Commercial Install - w/External Antenna(Contractor Supplied)', Work_Type_Code__c = 'COMM1EXTCS', EstimatedDuration = 90, Vendor__c = 'T-Mobile');
            workTypeList.add(comm1ExtCs);
            
            WorkType siteSurvey = new WorkType(Name = 'T-Mobile Site Survey', Work_Type_Code__c = 'SITE SURVEY', EstimatedDuration = 90, Vendor__c = 'T-Mobile');
            workTypeList.add(siteSurvey);
            
            WorkType hoServiceCall = new WorkType(Name = 'T-Mobile Home Office Service Call', Work_Type_Code__c = 'HO SERVICE CALL', EstimatedDuration = 90, Vendor__c = 'T-Mobile');
            workTypeList.add(hoServiceCall);
            
            WorkType comServiceCall = new WorkType(Name = 'T-Mobile Commercial Service Call', Work_Type_Code__c = 'COM SERVICE CALL', EstimatedDuration = 90, Vendor__c = 'T-Mobile');
            workTypeList.add(comServiceCall);
            
            WorkType comServiceCall4Hour = new WorkType(Name = 'T-Mobile Commercial Service Call - 4 Hour', Work_Type_Code__c = 'COM SERVICE CALL-4', EstimatedDuration = 90, Vendor__c = 'T-Mobile');
            workTypeList.add(comServiceCall4Hour);
            
            WorkType comServiceCall8Hour = new WorkType(Name = 'T-Mobile Commercial Service Call - 8 Hour', Work_Type_Code__c = 'COM SERVICE CALL-8', EstimatedDuration = 90, Vendor__c = 'T-Mobile');
            workTypeList.add(comServiceCall8Hour);
            
            WorkType comServiceCall12Hour = new WorkType(Name = 'T-Mobile Commercial Service Call - 12 Hour', Work_Type_Code__c = 'COM SERVICE CALL-12', EstimatedDuration = 90, Vendor__c = 'T-Mobile');
            workTypeList.add(comServiceCall12Hour);
            
            WorkType comServiceCall24Hour = new WorkType(Name = 'T-Mobile Commercial Service Call - 24 hour', Work_Type_Code__c = 'COM SERVICE CALL-24', EstimatedDuration = 90, Vendor__c = 'T-Mobile');
            workTypeList.add(comServiceCall24Hour);
            
            WorkType simswap = new WorkType(Name = 'SIM Swap', Work_Type_Code__c = 'SIMSWAP', EstimatedDuration = 60, Vendor__c = 'T-Mobile');
            workTypeList.add(simswap);
            
            insert workTypeList;
                        
            List<WorkType> allWorkTypes = [SELECT Id, Name FROM WorkType];
            system.debug('---------------------------------'+allWorkTypes.size());
            
            // Create a list to store SkillRequirement records
            List<SkillRequirement> skillReqList = new List<SkillRequirement>();
            
            // Loop through each work type and add skill requirements
            for (WorkType wt : allWorkTypes) {
                 SkillRequirement wtypeSkillReq1 = new SkillRequirement();
                wtypeSkillReq1.RelatedRecordId = wt.Id;
                wtypeSkillReq1.SkillId = TMoFB_Meraki_MG51_MG51e.Id;
                skillReqList.add(wtypeSkillReq1);
                
                SkillRequirement wtypeSkillReq2 = new SkillRequirement();
                wtypeSkillReq2.RelatedRecordId = wt.Id;
                wtypeSkillReq2.SkillId = TMoFB_Cradlepoint_E300.Id;
                skillReqList.add(wtypeSkillReq2);
                
                SkillRequirement wtypeSkillReq3 = new SkillRequirement();
                wtypeSkillReq3.RelatedRecordId = wt.Id;
                wtypeSkillReq3.SkillId = TMoFB_InseegoMiFiXPRO5G.Id;
                skillReqList.add(wtypeSkillReq3);
                
                SkillRequirement wtypeSkillReq13 = new SkillRequirement();
                wtypeSkillReq13.RelatedRecordId = wt.Id;
                wtypeSkillReq13.SkillId = TMoFB_5G_Gateway_S1_N2.Id;
                skillReqList.add(wtypeSkillReq13);
                
                SkillRequirement wtypeSkillReq4 = new SkillRequirement();
                wtypeSkillReq4.RelatedRecordId = wt.Id;
                wtypeSkillReq4.SkillId = TMoFB_Inseego_FX3100.Id;
                skillReqList.add(wtypeSkillReq4);
                
                SkillRequirement wtypeSkillReq5 = new SkillRequirement();
                wtypeSkillReq5.RelatedRecordId = wt.Id;
                wtypeSkillReq5.SkillId = TMoFB_Inseego_FX2000.Id;
                skillReqList.add(wtypeSkillReq5);
                
                SkillRequirement wtypeSkillReq6 = new SkillRequirement();
                wtypeSkillReq6.RelatedRecordId = wt.Id;
                wtypeSkillReq6.SkillId = TMoFB_Inseego_FW2000.Id;
                skillReqList.add(wtypeSkillReq6);
                
                SkillRequirement wtypeSkillReq7 = new SkillRequirement();
                wtypeSkillReq7.RelatedRecordId = wt.Id;
                wtypeSkillReq7.SkillId = TMoFB_Cradlepoint_W4005.Id;
                skillReqList.add(wtypeSkillReq7);
                
                SkillRequirement wtypeSkillReq8 = new SkillRequirement();
                wtypeSkillReq8.RelatedRecordId = wt.Id;
                wtypeSkillReq8.SkillId = TMoFB_Cradlepoint_W2005.Id;
                skillReqList.add(wtypeSkillReq8);
                
                SkillRequirement wtypeSkillReq9 = new SkillRequirement();
                wtypeSkillReq9.RelatedRecordId = wt.Id;
                wtypeSkillReq9.SkillId = TMoFB_Cradlepoint_W1855.Id;
                skillReqList.add(wtypeSkillReq9);
                
                SkillRequirement wtypeSkillReq10 = new SkillRequirement();
                wtypeSkillReq10.RelatedRecordId = wt.Id;
                wtypeSkillReq10.SkillId = TMoFB_Cradlepoint_W1850.Id;
                skillReqList.add(wtypeSkillReq10);
                
                SkillRequirement wtypeSkillReq11 = new SkillRequirement();
                wtypeSkillReq11.RelatedRecordId = wt.Id;
                wtypeSkillReq11.SkillId = TMoFB_Cradlepoint_E320.Id;
                skillReqList.add(wtypeSkillReq11);
                
                
                SkillRequirement wtypeSkillReq12 = new SkillRequirement();
                wtypeSkillReq12.RelatedRecordId = wt.Id;
                wtypeSkillReq12.SkillId = TMoFB_Cradlepoint_E3000.Id;
                skillReqList.add(wtypeSkillReq12);
                
                SkillRequirement wtypeSkillReq14 = new SkillRequirement();
                wtypeSkillReq14.RelatedRecordId = wt.Id;
                wtypeSkillReq14.SkillId = TMoFB_SIM_Swap.Id;
                skillReqList.add(wtypeSkillReq14);
                
            }
            insert skillReqList;
            
            
            ServiceResource ServiceRes = PV_TestDataFactory.createServiceResource(true,acct,con,usr);
            DescribeFieldResult describe = ServiceResource.Vendor_Type__c.getDescribe();
            List<PicklistEntry> avl = describe.getPicklistValues();
            string fgh=avl[0].value+';'+avl[1].value;
            ServiceRes.Vendor_Type__c = fgh;
            update ServiceRes;
            
            
            List<ServiceResourceSkill>srSkills = new List<ServiceResourceSkill>();
            ServiceResourceSkill srSkill01 = new ServiceResourceSkill();
            srSkill01.ServiceResourceId = ServiceRes.Id;
            srSkill01.SkillLevel= 80.00;
            srSkill01.EffectiveStartDate = System.Today()-1;
            srSkill01.SkillId = TMoFB_Meraki_MG51_MG51e.Id;
            srSkills.add(srSkill01);
            
            ServiceResourceSkill srSkill02 = new ServiceResourceSkill();
            srSkill02.ServiceResourceId = ServiceRes.Id;
            srSkill02.SkillLevel= 80.00;
            srSkill02.EffectiveStartDate = System.Today()-1;
            srSkill02.SkillId = TMoFB_Cradlepoint_E300.Id;
            srSkills.add(srSkill02);
            
            ServiceResourceSkill srSkill03 = new ServiceResourceSkill();
            srSkill03.ServiceResourceId = ServiceRes.Id;
            srSkill03.SkillLevel= 80.00;
            srSkill03.EffectiveStartDate = System.Today()-1;
            srSkill03.SkillId = TMoFB_Cradlepoint_E3000.Id;
            srSkills.add(srSkill03);
            
  ServiceResourceSkill srSkill04 = new ServiceResourceSkill();
            srSkill04.ServiceResourceId = ServiceRes.Id;
            srSkill04.SkillLevel= 80.00;
            srSkill04.EffectiveStartDate = System.Today()-1;
            srSkill04.SkillId = TMoFB_5G_Gateway_S1_N2.Id;
            srSkills.add(srSkill04);            
            
            
            ServiceResourceSkill srSkill5 = new ServiceResourceSkill();
            srSkill5.ServiceResourceId = ServiceRes.Id;
            srSkill5.SkillLevel= 80.00;
            srSkill5.EffectiveStartDate = System.Today()-1;
            srSkill5.SkillId = TMoFB_Inseego_FX3100.Id;
            srSkills.add(srSkill5);
            
            ServiceResourceSkill srSkill6 = new ServiceResourceSkill();
            srSkill6.ServiceResourceId = ServiceRes.Id;
            srSkill6.SkillLevel= 80.00;
            srSkill6.EffectiveStartDate = System.Today()-1;
            srSkill6.SkillId = TMoFB_Inseego_FX2000.Id;
            srSkills.add(srSkill6);
            
            ServiceResourceSkill srSkill7 = new ServiceResourceSkill();
            srSkill7.ServiceResourceId = ServiceRes.Id;
            srSkill7.SkillLevel= 80.00;
            srSkill7.EffectiveStartDate = System.Today()-1;
            srSkill7.SkillId = TMoFB_Inseego_FW2000.Id;
            srSkills.add(srSkill7);
            
            ServiceResourceSkill srSkill8 = new ServiceResourceSkill();
            srSkill8.ServiceResourceId = ServiceRes.Id;
            srSkill8.SkillLevel= 80.00;
            srSkill8.EffectiveStartDate = System.Today()-1;
            srSkill8.SkillId = TMoFB_Cradlepoint_W4005.Id;
            srSkills.add(srSkill8);
            
            ServiceResourceSkill srSkill9 = new ServiceResourceSkill();
            srSkill9.ServiceResourceId = ServiceRes.Id;
            srSkill9.SkillLevel= 80.00;
            srSkill9.EffectiveStartDate = System.Today()-1;
            srSkill9.SkillId = TMoFB_Cradlepoint_W2005.Id;
            srSkills.add(srSkill9);
            
            ServiceResourceSkill srSkill10 = new ServiceResourceSkill();
            srSkill10.ServiceResourceId = ServiceRes.Id;
            srSkill10.SkillLevel= 80.00;
            srSkill10.EffectiveStartDate = System.Today()-1;
            srSkill10.SkillId = TMoFB_Cradlepoint_W1855.Id;
            srSkills.add(srSkill10);
            
            ServiceResourceSkill srSkill11 = new ServiceResourceSkill();
            srSkill11.ServiceResourceId = ServiceRes.Id;
            srSkill11.SkillLevel= 80.00;
            srSkill11.EffectiveStartDate = System.Today()-1;
            srSkill11.SkillId = TMoFB_Cradlepoint_W1850.Id;
            srSkills.add(srSkill11);
            
            ServiceResourceSkill srSkill12 = new ServiceResourceSkill();
            srSkill12.ServiceResourceId = ServiceRes.Id;
            srSkill12.SkillLevel= 80.00;
            srSkill12.EffectiveStartDate = System.Today()-1;
            srSkill12.SkillId = TMoFB_Cradlepoint_E320.Id;
            srSkills.add(srSkill12);
            
            ServiceResourceSkill srSkill13 = new ServiceResourceSkill();
            srSkill13.ServiceResourceId = ServiceRes.Id;
            srSkill13.SkillLevel= 80.00;
            srSkill13.EffectiveStartDate = System.Today()-1;
            srSkill13.SkillId = TMoFB_InseegoMiFiXPRO5G.Id;
            srSkills.add(srSkill13);
            
            ServiceResourceSkill srSkill14 = new ServiceResourceSkill();
            srSkill14.ServiceResourceId = ServiceRes.Id;
            srSkill14.SkillLevel= 80.00;
            srSkill14.EffectiveStartDate = System.Today()-1;
            srSkill14.SkillId = TMoFB_SIM_Swap.Id;
            srSkills.add(srSkill14);
            insert srSkills;
            
            ServiceTerritoryMember stm = PV_TestDataFactory.createServiceTerritoryMember(true,ServiceRes,childServiceTerritory,'S');
            WorkType wt = PV_TestDataFactory.createWorkType('T_Mobile_Commercial_Install_Cellular_G__c',true);
            WorkOrder wo = PV_TestDataFactory.createWorkOrder(usr,wt,true);
            
            List<Work_Type_SR_Count__c> wtsrList = new List<Work_Type_SR_Count__c>();
            for(Integer i=1;i<=20;i++){
                Work_Type_SR_Count__c wtsr = new Work_Type_SR_Count__c();
                wtsr.No_of_skilled_resources__c = i+1;
                wtsr.Service_Territory__c = childServiceTerritory.Id;
                wtsr.Work_Type__c = wt.Id;
                wtsr.Service_Resource_Percentage__c = ((i/20)*100);
                wtsrList.add(wtsr);
            }
            
            if(!wtsrList.isEmpty()){
                insert wtsrList;
            }
            
            Test.startTest();
            PV_WorkTypeSRBatch b = new PV_WorkTypeSRBatch();
            Database.executeBatch(b);
            Test.stopTest();
            
        }
    }
}
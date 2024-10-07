/**
 * @description       : Filter applications and quick quotes based on specified criteria
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-07-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 **/
public without sharing class FilterApplications implements PortalActionAdapter {
    public List<genesis__Applications__c> appObject;
    public List<genesis__Quick_Quotes__c> quickQuoteObject;

    Set<String> excludedStatuses = new Set<String>{'Expired', 'Failed'};



    // Function to get filtered applications and quick quotes for Broker
    public List<genesis__Applications__c> getFilteredAppQQForBroker() {
        List<genesis__Quick_Quotes__c> quickQuotes = new List<genesis__Quick_Quotes__c>(); 
        List<genesis__Applications__c> appList = new List<genesis__Applications__c>();       
        List<genesis__Quick_Quotes__c> filteredQuickQuotes = new List<genesis__Quick_Quotes__c>();
        List<genesis__Applications__c> filteredApplication = new List<genesis__Applications__c>();

        appList = [SELECT Id, genesis__Status__c
                        FROM genesis__Applications__c 
                        WHERE genesis__Status__c NOT IN :excludedStatuses
                        AND genesis__Contact__r.brk_TypeofContact__c = :UnderwritingBatchJobConstants.BROKER
                        WITH SYSTEM_MODE];
 
        quickQuotes = [SELECT Id, genesis__Status__c 
                        FROM genesis__Quick_Quotes__c		 
                        WHERE genesis__Status__c NOT IN :excludedStatuses
                        AND genesis__Contact__r.brk_TypeofContact__c = :UnderwritingBatchJobConstants.BROKER
                        WITH SYSTEM_MODE];


    
        if(quickQuotes.size()>5000){         
            for(genesis__Applications__c qqValue: quickQuotes){
                if (qqValue.CreatedDate >= System.now().addMonths(-3)) {
                    filteredQuickQuotes.add(qqValue);
                }
            }
        }

        if(appList.size()> 5000){             
            for(genesis__Applications__c appValue: appList){
                if(appValue.CreatedDate >= System.now().addMonths(-3) ){
                    filteredApplication.add(appValue);
                }
            }        
        } 
    }

}

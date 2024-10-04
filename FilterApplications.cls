/**
 * @description       : Filter applications and quick quotes based on specified criteria
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-04-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 **/
public without sharing class FilterApplications {
    public List<genesis__Applications__c> appObject;
    public List<genesis__QuickQuote__c> quickQuoteObject;
    private final static String EX_NO_APPLICATION = 'Already Filtered Applications';
    private final static String EX_NO_QQ = 'Already Filtered Quick Quotes And Applications';

    // Constructor to initialize the lists
    public FilterApplications() {
        appObject = new List<genesis__Applications__c>();
        quickQuoteObject = new List<genesis__QuickQuote__c>();
    }

    // Function to get filtered applications and quick quotes for Broker
    public List<genesis__Applications__c> getFilteredAppQQForBroker() {

        List<genesis__Applications__c> appList = [SELECT Id,
                                                  genesis__Status__c
                                        FROM genesis__Applications__c 
                                        WHERE genesis__Status__c != 'Expired' 
                                        AND genesis__Status__c != 'Failed'
                                        AND genesis__Contact__c ='Broker'
                                        WITH SYSTEM_MODE];


        List<genesis__QuickQuote__c> quickQuotes = [SELECT Id, 
                                                     genesis__Status__c 
                                        FROM genesis__QuickQuote__c 
                                        WHERE genesis__Status__c != 'Expired' 
                                        AND genesis__Status__c != 'Failed'
                                        AND genesis__Contact__c ='Broker'
                                        WITH SYSTEM_MODE];


        // Check the size                                           
        if( quickQuotes.size() < 5000 ){
            throw new CustomException(EX_NO_QQ);
        }
    
        else if (appList.size()> 5000 && quickQuotes.size()>5000){
             
             

        }
       

      

       
    }
}

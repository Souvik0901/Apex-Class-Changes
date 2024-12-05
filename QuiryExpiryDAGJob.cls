/****************************************************************************************
Class Name         : QuoteExpiryDAGJob
Description        : Batch job that scans over Quick Quotes and expires them. 
Developer          : Alok Tiwari
Created Date       : 12/01/2023
Last Modified By   : 
Last Modified Date : 
*****************************************************************************************/
global with sharing class QuoteExpiryDAGJob extends clcommon.DynamicJob implements Schedulable{
        global String query =System.label.Quote_Expiry_Query ;
        public static final String JOB_NAME = QuoteExpiryDAGJob.class.getName();
        global SET<String> expirableStatus = new SET<String>{ConstantValues.qqStatus_en,ConstantValues.qqStatus_gen};
    
        global QuoteExpiryDAGJob() {}
        global QuoteExpiryDAGJob(String query){
            super(JOB_NAME,query);
            this.query = query;
        }
        global override String getRuntimeQuery(){ 
		return   query;
                            
           
        }
        global override void doStart(Database.BatchableContext bc){}

        global override void doExecute(Database.BatchableContext bc,List<SObject> scope){
            Date currentSystemDate;
            if(Test.isRunningTest()){
                currentSystemDate = System.Today();
            }else{
                currentSystemDate = FlowfiUtil.currentSystemDate;
            }
            List<genesis__Quick_Quotes__c> qqUpdateList = new List<genesis__Quick_Quotes__c>();
            if(scope.size()>0){
                for(genesis__Quick_Quotes__c qqObj: (List<genesis__Quick_Quotes__c>) scope){
                    if(System_Configuration__c.Quick_Quote_Expiry_Day_Count__c!=null && 
                        qqObj.CreatedDate.Date().daysBetween(currentSystemDate)>System_Configuration__c.getInstance().Quick_Quote_Expiry_Day_Count__c){
                            qqObj.genesis__Status__c = ConstantValues.qqStatus_expired;
                            qqObj.Expired_On__c = FlowfiUtil.currentSystemDate;
                            qqUpdateList.add(qqObj);
                    }
                }
            }
            if(qqUpdateList.size()>0){
                Savepoint sp = Database.setSavepoint();
                try{
                    update qqUpdateList;
                }catch(Exception ex){
                    ExceptionManager.manageException(ex);
                    Database.rollback(sp);
                    insert ExceptionManager.getClCommonLog(ex,'Genesis');
                }
            }
        }
        global override void doExecute(System.SchedulableContext sc){}
        global override void doInitialize(){}
        global override void doFinish(Database.BatchableContext bc){}     
}

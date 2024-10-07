/**
 * @description       : Filter applications and quick quotes based on specified criteria
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-07-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 **/
public without sharing class FilterApplications implements PortalActionAdapter {
    List<String> paramKeys;
    clcommon.Response res;

    Set<String> excludedStatuses = new Set<String>{'Expired', 'Failed'};


    /**
    * @description : Setting the value of parameters incoming
    * @author Souvik Sen
    **/
    public FilterApplications(){
        res= new clcommon.Response();
        paramKeys = new List<String>();
    }

    /**
    * @description : Setting the value of parameters incoming
    * @author Souvik Sen
    * @param param : Map<String Object>
    **/
    public void setParams(Map<String, Object> param){
        try {
            paramKeys.add();
        } catch (Exception ex) {
            generateException(ex);
        }
    }


    /**
    * @description : 
    * @author Souvik Sen
    **/
    public void execute(){
        try{
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
        
            if(quickQuotes.size()> 5000){         
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
            
            // Need to response the possible Outcome

           
        }
        catch(Exception ex){
            generateException(ex);
        }
    }


    /**
    * @description : Return response
    * @author Sujit Pal
    * @return clcommon.Response 
    **/ 
    public clcommon.Response getPortalResponse(){
        retun res;
    }


    /**
    * @description : Return response
    * @author Sujit Pal
    * @param ex
    **/
    private void generateException(Exception ex){
        error  =true;  
        errMsg = ex.getMessage();                   
        insert ExceptionManager.getClCommonLog(ex,ConversionConstant.genesis);
        if(ex.getTypeName().equals(CpConstants.CUSTOMEXCEPTIONTYPE)){
            res = FlowfiUtil.getErrorMessageResponse(ex.getMessage());
        }else{
            res = FlowfiUtil.getErrorResponse(CpConstants.SOMETHINGWENTWRONG);
        }
    }

}

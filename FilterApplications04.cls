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
    Boolean error=false;
    String errMsg;
    Map<String, Object> fields= new Map<String,Object>();
    Set<String> excludedStatuses = new Set<String>{'Expired', 'Failed'};
    private final static String BROKER_ID='brokerId';
    Map<String, Object> portalParam = new Map<String, Object>();
    private final static String QUICKQUOTE_MESSAGE = 'Quick Quote Details';
    private final static String APPLICATION_MESSAGE = 'Application Details';
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
            PortalValidationUtil.checkBlankMap(param, ResponseMessenger.reqParamBlank);
            ValidationUtil.validateObjectNotNull(param.get(BROKER_ID));
            paramKeys.add(BROKER_ID);
            PortalValidationUtil.checkParamKeysInParamMap(param, paramKeys, portalParam);
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
            if(BrokerPortalSecurityUtil.profileChecking(UserInfo.getUserId())){
                getFilteredAppQQForBroker();
            }
            else{
                throw new CustomException(ResponseMessenger.ProfileNotFound);
            }
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
        return res;
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

    public void getFilteredAppQQForBroker() {
        List<genesis__Quick_Quotes__c> quickQuotes = new List<genesis__Quick_Quotes__c>(); 
        List<genesis__Applications__c> appList = new List<genesis__Applications__c>();       
        List<genesis__Quick_Quotes__c> filteredQuickQuotes = new List<genesis__Quick_Quotes__c>();
        List<genesis__Applications__c> filteredApplication = new List<genesis__Applications__c>();
        String brokerId=String.valueOf(portalParam.get(BROKER_ID));

        appList = [SELECT Id, genesis__Status__c
                        FROM genesis__Applications__c 
                        WHERE genesis__Status__c NOT IN :excludedStatuses
                        AND Broker_ID__c =: brokerId
                        WITH SYSTEM_MODE];
 
        quickQuotes = [SELECT Id, genesis__Status__c 
                        FROM genesis__Quick_Quotes__c		 
                        WHERE genesis__Status__c NOT IN :excludedStatuses
                        AND Broker_ID__c =: brokerId
                        WITH SYSTEM_MODE];  
    
        if(quickQuotes.size()> 5000){         
            for(genesis__Applications__c qqValue: quickQuotes){
                if (qqValue.CreatedDate >= System.now().addMonths(-3)) {
                    filteredQuickQuotes.add(qqValue);
                }
            }
            fields.put(QUICKQUOTE_MESSAGE,filteredQuickQuotes);
        }

        if(appList.size()> 5000){             
            for(genesis__Applications__c appValue: appList){
                if(appValue.CreatedDate >= System.now().addMonths(-3) ){
                    filteredQuickQuotes.add(appValue);                       
                }
            }
            fields.put(APPLICATION_MESSAGE,filteredApplication);        
        } 
        
        // Need to response the possible Outcome
        res = FlowfiUtil.getSuccessResponse(CpConstants.SUCCESS, fields); 
    }

}

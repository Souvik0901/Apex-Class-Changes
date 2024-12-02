/*********************************************************************************************************
@Class          : BrokerServiceabilityCalculator
@Description    : This API is used to get the capacity of Broker's customer using the serviceability calculator in the Broker Portal
@Created Date   : 23/05/2022
@Developer      : Reet Roy
@History        : 
**********************************************************************************************************/
public without sharing class BrokerServiceabilityCalculator implements PortalActionAdapter{
    String jsonData;
    Boolean quote;
    List<String> paramKeys;
    Map<String,Object> fields ;
    clcommon.Response res;
    BrokerServiceabilityCalculator.ServiceRequestWrapper servObj;
    /* Initialising parameter keys and response */
    public class ServiceRequestWrapper{
        public String rate_type;
        public String Broker_Fee;
        public String total_monthly_loan_repayments;
        public String nonessential_spending;
        public String rent_mortgage;
        public String total_balance_owing_on_cards;
        public String Loan_Amount;
        public String Primary_Monthly_Income_Amount_After_Tax;
        public String calculator_residential_Status;
        public String Dependants;
        public String combined_credit_card_loan;
        public String Interest_Rate;
        public String essential_spending;
        public String Government_Income;
        public String Other_Income;
        public String investment_property_mortgage;
        public String Loan_Term;
        public String Marital_Status;
        public String No_of_dependents;
        public String Client_Name;
    }
    public class LoanWrapper{
        public Decimal loanAmt;
        public Decimal rate;
        public Integer term;
        public String rateType;
        public Decimal brokerFee;
    }
    public BrokerServiceabilityCalculator(){
        quote = false;
        servObj = new BrokerServiceabilityCalculator.ServiceRequestWrapper();
        res = new clcommon.Response();
        fields= new Map<String,Object>();
        paramKeys = new List<String>();
        paramKeys.add(BrokerServiceabilityCalculatorConstants.JSON_DATA_PARAM);
    }
    /* Setting the value of parameters incoming via POJO */
    /**
    * setParams   : this method fetches and set parameters from the input map
    * @params     : Map<String, Object> param
    * @returnType : void
    **/ 
    public void setParams(Map<String,Object> param){
        try{
            Map<String,Object> customParam = new Map<String,Object>();
            /* if parameter map comes blank then exception */
            if(param!=null && !param.isEmpty()){
                for(String paramKey : paramKeys){
                    /* if parameter doesn't contain a paramKey or has null as its value */
                    if(!param.containsKey(paramKey)){
                        throw new CustomException(CpConstants.PARAM_MISSING_EX+paramKey);
                    }else if( param.get(paramKey) == null){
                        throw new CustomException(CpConstants.PARAM_VAL_MISSING_EX+paramKey);
                    }else{
                        String filteredVal = String.valueOf(param.get(paramKey));
                        filteredVal=filteredVal.removeStart(CpConstants.REMOVE_FROM_START);
                        filteredVal=filteredVal.removeEnd(CpConstants.REMOVE_FROM_END);
                        customParam.put(paramKey,filteredVal);
                    }
                }
                if( paramKeys != null && paramKeys.size() > 0 ){
                    jsonData = String.valueOf(customParam.get(paramKeys[0]));
                }
                this.parseCalculateInformation(jsonData);
            }else{
                throw new CustomException(CpConstants.PARAM_MAP_BLANK_EX);
            }
        }catch(Exception e){
            /* if custom exception thrown return success response with error message */
            if(e.getTypeName() == CpConstants.CUSTOMEXCEPTIONTYPE){
                res = FlowfiUtil.getErrorMessageResponse(e.getMessage());
            }else{
                res = FlowfiUtil.getErrorResponse(CpConstants.SOMETHINGWENTWRONG);
            }
        }
    }
    public void parseCalculateInformation(String jsonData){
        servObj = (BrokerServiceabilityCalculator.ServiceRequestWrapper)JSON.deserialize(jsonData, BrokerServiceabilityCalculator.ServiceRequestWrapper.class);
    }
    /* processing of info extracted from req json */
    public void execute(){
        try{
            if( FlowfiUtil.brokerUserCheck()){
                if( servObj == null ){
                    throw new CustomException(BrokerServiceabilityCalculatorConstants.REQ_EMPTY_EX);
                }
                CalculationHandler calHandler = new CalculationHandler();
                String rateType = returnIfNotNull(servObj.rate_type, BrokerServiceabilityCalculatorConstants.RATE_EMPTY);
                String maritalStatus = returnIfNotNull(servObj.Marital_Status, BrokerServiceabilityCalculatorConstants.RELATIONSHIP_EMPTY);
                String noOfDependants = returnIfNotNull(servObj.Dependants , BrokerServiceabilityCalculatorConstants.NO_OF_DEPENDANTS_EMPTY);
                Decimal rate = calHandler.truncateNum(returnDecimalIfValid(servObj.Interest_Rate, BrokerServiceabilityCalculatorConstants.RATE_EMPTY , BrokerServiceabilityCalculatorConstants.RATE_INCORRECT_FORMAT_EX));
                Decimal loanAmt = calHandler.truncateNum(returnDecimalIfValid(servObj.Loan_Amount, BrokerServiceabilityCalculatorConstants.LOAN_AMT_EMPTY, BrokerServiceabilityCalculatorConstants.LOAN_AMT_INCORRECT_FORMAT_EX));
                Decimal brokerFee = calHandler.truncateNum(returnDecimalIfValid(servObj.Broker_Fee, BrokerServiceabilityCalculatorConstants.BROKER_FEE_EMPTY, BrokerServiceabilityCalculatorConstants.BROKER_FEE_INCORRECT_FORMAT_EX));
                Decimal otherLoanExpense = calHandler.truncateNum(servObj.total_monthly_loan_repayments == null ? 0 : returnDecimalIfValid(servObj.total_monthly_loan_repayments, null, BrokerServiceabilityCalculatorConstants.MONTHLY_REPAYMENT_INCORRECT_EX));
                Decimal nonEssentialExpense = calHandler.truncateNum(servObj.nonessential_spending == null ? 0 : returnDecimalIfValid(servObj.nonessential_spending, null, BrokerServiceabilityCalculatorConstants.NON_ESSENTIAL_INCORRECT_EX));
                Decimal essentialExpense = calHandler.truncateNum(servObj.essential_spending == null ? 0 : returnDecimalIfValid(servObj.essential_spending, null,BrokerServiceabilityCalculatorConstants.ESSENTIAL_INCORRECT_EX));
                Decimal totalccBalance = calHandler.truncateNum(servObj.total_balance_owing_on_cards == null ? 0 : returnDecimalIfValid(servObj.total_balance_owing_on_cards, null, BrokerServiceabilityCalculatorConstants.CC_BALANCE_INCORRECT_EX));
                Decimal primaryIncomeAmt = calHandler.truncateNum(returnDecimalIfValid(servObj.Primary_Monthly_Income_Amount_After_Tax, BrokerServiceabilityCalculatorConstants.PR_INCOME_EMPTY, BrokerServiceabilityCalculatorConstants.PR_INCOME_INCORRECT_EX));
                String residentialStatus = returnIfNotNull(servObj.calculator_residential_Status, BrokerServiceabilityCalculatorConstants.RESIDENTIAL_STATUS_EMPTY);
                Decimal rentMortgage;
                if(BrokerServiceabilityCalculatorConstants.NO_MORTGAGE_STATUS_LIST.contains(residentialStatus)){
                    rentMortgage = 0;
                } else {
                    rentMortgage = calHandler.truncateNum(returnDecimalIfValid(servObj.rent_mortgage, BrokerServiceabilityCalculatorConstants.RENT_MORT_EMPTY, BrokerServiceabilityCalculatorConstants.RENT_MORT_INCORRECT_EX));
                }
                Decimal totalccLimit = calHandler.truncateNum(servObj.combined_credit_card_loan == null ? 0 : returnDecimalIfValid(servObj.combined_credit_card_loan, null, BrokerServiceabilityCalculatorConstants.CC_LIMIT_INCORRECT_EX));
                Decimal govtIncomeAmt = calHandler.truncateNum(servObj.Government_Income == null ? 0 : returnDecimalIfValid(servObj.Government_Income, null, BrokerServiceabilityCalculatorConstants.GOVT_INCORRECT_EX));
                Decimal otherIncomeAmt = calHandler.truncateNum(servObj.Other_Income == null ? 0 : returnDecimalIfValid(servObj.Other_Income, null, BrokerServiceabilityCalculatorConstants.OTHER_INC_INCORRECT_EX));
                Decimal investmentAmt = calHandler.truncateNum(servObj.investment_property_mortgage == null ? 0 : returnDecimalIfValid(servObj.investment_property_mortgage, null, BrokerServiceabilityCalculatorConstants.INV_AMT_INCORRECT_EX));
                Integer term = returnIntegerIfValid(servObj.Loan_Term, BrokerServiceabilityCalculatorConstants.LOAN_TRM_EMPTY, BrokerServiceabilityCalculatorConstants.LOAN_TRM_INCORRECT_EX);
                String clientName = returnIfNotNull(servObj.Client_Name, BrokerServiceabilityCalculatorConstants.CLIENT_NAME_EMPTY);
                Decimal totalIncome = calHandler.truncateNum(primaryIncomeAmt) + calHandler.truncateNum(govtIncomeAmt) + calHandler.truncateNum(0.9 * otherIncomeAmt);
                calHandler.totalIncome = totalIncome;
                calHandler.essentialExpense = essentialExpense;
                calHandler.noOfDependants =  noOfDependants == BrokerServiceabilityCalculatorConstants.NO_OF_DEPENDANTS_MORE_THAN_10 ? BrokerServiceabilityCalculatorConstants.NO_OF_DEPENDANTS_MORE_THAN_10_INT : Decimal.valueOf(noOfDependants);
                calHandler.bankVerifiedEssentialExpense = 0;
                calHandler.nonEssentialExpense = nonEssentialExpense;
                calHandler.housingCostStated = rentMortgage + investmentAmt;
                calHandler.bankVerifiedRentMortgage = 0;
                calHandler.residentialStatus = residentialStatus;
                calHandler.maritalStatus = maritalStatus;
                calHandler.expenseShared = returnIfNotNull(servObj.No_of_dependents, BrokerServiceabilityCalculatorConstants.EXP_SHARED_EMPTY);
                calHandler.noOfApplicants = 1;
                
                calHandler.getCoupleorNot();
                
                genesis__Monthly_Income_Expense_Info__c ccExpense = new genesis__Monthly_Income_Expense_Info__c();
                ccExpense.Total_Balance__c = totalccBalance;
                ccExpense.Credit_Card_Limit__c = totalccLimit;
                ccExpense.RecordTypeId = Schema.SObjectType.genesis__Monthly_Income_Expense_Info__c.getRecordTypeInfosByDeveloperName().get(BrokerServiceabilityCalculatorConstants.CC_RECORD_TYPE).getRecordTypeId();
                calHandler.ccList.add(ccExpense);
                
                
                
                Decimal livingExpense = calHandler.truncateNum(calHandler.getLivingExpenseForApp());

                
                

                Decimal housingExpense = calHandler.truncateNum(calHandler.getHousingExpense());
                Decimal getLFSCCExpense = calHandler.truncateNum(calHandler.getLFSCCExpense());
                BrokerServiceabilityCalculator.LoanWrapper lnWrap = new BrokerServiceabilityCalculator.LoanWrapper();
                lnWrap.loanAmt = loanAmt;
                lnWrap.rate = rate;
                lnWrap.rateType = rateType;
                lnWrap.term = term;
                lnWrap.brokerFee = brokerFee;
                Decimal sensitizedEmi = calHandler.truncateNum(getSensitizedEmi(lnWrap));
                Decimal totalExpense = livingExpense + housingExpense + getLFSCCExpense + sensitizedEmi + otherLoanExpense;
                
                Decimal umi = totalIncome - totalExpense;
                fields.put(BrokerServiceabilityCalculatorConstants.TOT_INC_RESP,totalIncome);
                fields.put(BrokerServiceabilityCalculatorConstants.TOT_EXP_RESP,totalExpense);
                fields.put(BrokerServiceabilityCalculatorConstants.UMI_RESP,umi);
                Decimal borrowingLimitMethod = calculateBorrowingLimit(rate, term, umi);
                fields.put(BrokerServiceabilityCalculatorConstants.BORROWING_LIMIT, borrowingLimitMethod);
                res = FlowfiUtil.getSuccessResponse(BrokerServiceabilityCalculatorConstants.SUCCESS,fields);

            } else{
                throw new CustomException(CpConstants.ACCESS_DENIED);
            }
        } catch( Exception e ){
            ExceptionManager.manageException(e);
            if(e.getTypeName().equals(CpConstants.CUSTOMEXCEPTIONTYPE)){
                res = FlowfiUtil.getErrorMessageResponse(e.getMessage());
            }else {
                res = FlowfiUtil.getErrorResponse(ResponseMessenger.genericExceptionMsg);
            }
            insert ExceptionManager.getClCommonLog(e,ConversionConstant.genesis);
        }
    }
    public Decimal getSensitizedEmi(BrokerServiceabilityCalculator.LoanWrapper lnWrap){
        System_Configuration__c sysConfig = System_Configuration__c.getInstance();
        EMICalculation.EmiResults emi;
        Decimal bufferRate = sysConfig.Buffer_Interest_Rate__c == null ? 0 : sysConfig.Buffer_Interest_Rate__c;
        if(lnWrap.rateType == BrokerServiceabilityCalculatorConstants.VARIABLE_PRO_TYPE){
            lnWrap.rate = lnWrap.rate + bufferRate;
        }
        Date startDate = FlowfiUtil.currentSystemDate;
        Date firstPayDate = startDate.addMonths(1);
        Decimal adminFee = sysConfig.Loan_Admin_Fee__c == null ? 0 : sysConfig.Loan_Admin_Fee__c;
        String daysConvention = sysConfig.Default_Days_Convention__c;
        String interestCalcMethod = sysConfig.Default_Interest_Calculation_Method__c;
        
        emi = EMICalculation.calcEMI(startDate, firstPayDate, BrokerServiceabilityCalculatorConstants.MONTHLY_FREQ, daysConvention, interestCalcMethod, lnWrap.loanAmt + lnWrap.brokerFee , lnWrap.rate , 12 * lnWrap.term);
        return emi.paymentAmount + adminFee;
    }
    public Decimal returnDecimalIfValid(String val,String nullmsg, String formatmsg){
        String strValue = returnIfNotNull(val,nullmsg);
        try{
            return Decimal.valueOf(strValue);
        }catch( Exception e ){
            throw new CustomException(formatmsg);
        }
    }
    public String returnIfNotNull(String val,String message){
        if( val == null || String.isBlank(val)){
            throw new CustomException(message);
        }
        return val;
    }
    public Integer returnIntegerIfValid(String val,String nullmsg, String formatmsg){
        String strValue = returnIfNotNull(val,nullmsg);
        try{
            return Integer.valueOf(strValue);
        }catch( Exception e ){
            throw new CustomException(formatmsg);
        }
    }
    
    public Decimal calculateBorrowingLimit(Decimal rate,Integer term,Decimal umi)
    {
       Double r = rate/1200;
       Double t = term*12;
       Double p = umi -1;
       Double ret = 1/(1+r);

       Decimal pow = p* (1 - math.pow((ret),t))/(1-ret);
       
       Decimal calculatingInterest = pow *r;

       Decimal borrowingLimit = pow - calculatingInterest;
       borrowingLimit.setScale(2,RoundingMode.DOWN);

       return borrowingLimit;
       
    }

    /*****************Return response******************/
    public clcommon.Response getPortalResponse(){
        return res;
    }
}

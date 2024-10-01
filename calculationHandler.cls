/**
 * @Class             : RulesConsolidationHandler
 * @author            : Souvik Sen
 * @group             : 
 * @last modified on  : 09-27-2024
 * @last modified by  : Sujit Pal
**/
public with sharing class RulesConsolidationHandler {
    private Id appId;
    private Decimal verifiedIncome = 0 ;
    private List<clcommon__Party__c> applicantList;
    private genesis__Applications__c applicationObj; 
    private Map<Id,genesis__Employment_Information__c> applicantEmpMap;
    private Map<Id,List<genesis__Monthly_Income_Expense_Info__c>> applicantCreditCardMap; 
    private Map<Id,List<genesis__Monthly_Income_Expense_Info__c>> applicantOtherLoanMap;
    private Map<Id,genesis__Monthly_Income_Expense_Info__c> applicantExpenseMap;
    private Map<Id,Decimal> applicantRepaymentAmountMap;
    private Map<Id,Decimal> applicantCCLimitMap;
    private Map<Id,ints__Credit_File__c> applicantIBCreditFileMap;
    private Map<Id,Map<String,String>> applicantEfxScoreMap;
    private Map<Id,List<ints__EfxReport_Collection__c>> applicantEfxCollectionMap;
    private Map<Id,List<ints__EfxReport_Consumer_Statement__c>> applicantDefaultMap;
    private List<Account> applicantAccountList ;
    public RulesConsolidationHandler(){
        applicantList = new List<clcommon__Party__c>();
        applicantEmpMap = new Map<Id,genesis__Employment_Information__c>();
        applicantCreditCardMap = new Map<Id,List<genesis__Monthly_Income_Expense_Info__c>>();
        applicantOtherLoanMap = new Map<Id,List<genesis__Monthly_Income_Expense_Info__c>>();
        applicantExpenseMap = new Map<Id,genesis__Monthly_Income_Expense_Info__c>();
        applicantAccountList = new List<Account>();
        applicantIBCreditFileMap = new Map<Id,ints__Credit_File__c>();
        applicantRepaymentAmountMap = new Map<Id,Decimal>();
        applicantCCLimitMap = new Map<Id,Decimal>();
        applicantDefaultMap = new Map<Id,List<ints__EfxReport_Consumer_Statement__c>>();
        applicantEfxScoreMap = new Map<Id,Map<String,String>>();
        applicantEfxCollectionMap = new Map<Id,List<ints__EfxReport_Collection__c>>();
    }
    private Decimal truncateNum(Decimal num){
        return num.setScale(2,System.RoundingMode.DOWN);
    }
    public RulesConsolidationHandler(Id appId, String stage){
        this();
        this.appId = appId;
        instantiateVariableList(stage);
    }
    private void instantiateVariableList(String stage){
        applicationObj = new genesis__Applications__c();
        List<genesis__Applications__c> applist = [ SELECT Id,
                                                            LFS90DaysOverdue__c,
                                                            Country_Check__c,
                                                            Age_Check__c,
                                                            DupId_check__c,
                                                            Company__c,
                                                            Borrower_Email__c,
                                                            Fraud_Triggered_Rules__c,
                                                            genesis__CL_Product__c,
                                                            OwnerId,
                                                            genesis__CL_Product_Name__c,
                                                            Do_You_have_KiwiHome_Loan__c,
                                                            Loan_Purposes__c,
                                                            Residential_Status__c,
                                                            Unsecured_Referral_Limit__c, 
                                                            Secured_Referral_Limit__c,
                                                            Recently_declined_customer__c,
                                                            genesis__Account__c,
                                                            genesis__Loan_Amount__c,
                                                            genesis__Status__c,
                                                            Thin_bureau_file_referral__c
                                                        FROM genesis__Applications__c 
                                                        WHERE Id = :this.appId
                                                        LIMIT 1];
        if(applist==null ||applist.size()==0){
            throw new CustomException(UnderwritingBatchJobConstants.APP_NOT_FOUND_EX);
        }
        applicationObj = applist[0];
        applicantList = [SELECT Id ,
                                Mogo_Total_Monthly_Income__c,
                                Mogo_Gamb_Txn_Amt__c,
                                EidV_Verification_Status__c,
                                Customer_Stated_Net_Monthly_Income__c,
                                Customer_Stated_Decrease_in_Income__c,
                                Customer_Stated_Primary_Income__c,
                                Customer_Stated_Govt_Allowance__c,
                                Customer_Stated_Additional_Income__c,
                                clcommon__Account__c,
                                Customer_Stated_Investment_on_Property__c,
                                Customer_Stated_Rental_Share__c,
                                Number_of_open_overdraft_accounts__c,
                                Income_Verification_Process__c,
                                Mogo_Overdraw_Fee_Count__c,
                                Mogo_Dishonors_Count__c,
                                Mogo_Has_PayDay__c,
                                Mogo_Reverse_Payment_Count__c,
                                Mogo_Joint_Account_Flag__c,
                                Do_any_of_your_loans_require_a_lump_sum__c,
                                Mogo_Applicant_Account_Name_Different__c,
                                Income_Verified__c,
                                clcommon__Account__r.Age__c,
                                (SELECT Id, 
                                        Party__c 
                                        FROM Credit_Reports__r
                                        ORDER BY CreatedDate DESC 
                                        LIMIT 1),
                                (SELECT Id, 
                                        genesis__Occupation__c 
                                        FROM Employment_Information__r) ,
                                (SELECT Id,
                                        primary_amount__c,
                                        Goverment_Allowance_Amount__c,
                                        Goverment_Allowance_Frequency__c,
                                        genesis__Frequency__c,  
                                        Name, 
                                        RecordTypeId,
                                        Anticipate_Decrease_in_Income__c, 
                                        Expected_Circumstantial_Change__c,
                                        Recieve_Government_Allowance_or_Pensio__c,
                                        genesis__Amount__c ,
                                        RecordType.Name,
                                        Income_source__c
                                        FROM Incomes__r ),
                                (SELECT Id,
                                       Party__c
                                        FROM EfxReports__r
                                        ORDER BY CreatedDate DESC 
                                        LIMIT 1)
                                FROM clcommon__Party__c 
                                WHERE genesis__Application__c = :this.appId
                                AND clcommon__Type__r.Name = :UnderwritingBatchJobConstants.BORROWER
                                ];
        if(applicantList.size()==0 || applicantList.size()>2){
            throw new CustomException(UnderwritingBatchJobConstants.PARTY_COUNT_EX);
        }
        Set<Id> applicantIdList = (new Map<Id,clcommon__Party__c>(applicantList)).keySet();
        List<genesis__Monthly_Income_Expense_Info__c> explist = [ SELECT ID,
                                                                         Party__c,
                                                                         Repayment_Amount__c,
                                                                         Share_of_monthly_rent__c,
                                                                         Total_Limit__c,
                                                                         Loan_Type__c,
                                                                         CC_financial_institution__c,
                                                                         Repayment_Frequency__c,
                                                                         RecordType.Name
                                                                        From genesis__Monthly_Income_Expense_Info__c 
                                                                        WHERE Party__c IN :applicantIdList ];
        setOtherLoanMap(explist);
        setCCLimit(explist);
        setExpenseMap(explist);
        setCreditBureauMap();
        if(stage==UnderwritingBatchJobConstants.PREILLION||stage=='Final'){
            setEfxMaps();
        }
        List<Id> accountIdList = new List<Id>();
        for( clcommon__Party__c applicant : applicantList ){
            accountIdList.add(applicant.clcommon__Account__c);
        }
        applicantAccountList = [SELECT Id,
                                        Age__c,
                                        Are_you_an_existing_Kiwibank_customer__c,
                                        Country__c
                                        FROM Account
                                        WHERE Id IN :accountIdList];
        if(applicantAccountList.size()!=applicantList.size()){
            throw new CustomException(UnderwritingBatchJobConstants.ACCOUNT_COUNT_EX);
        }
    }

    private Boolean countryCheck(){
        for(Account acc : applicantAccountList){
            if(acc.Country__c != null && !(acc.Country__c == UnderwritingBatchJobConstants.NZ || 
                acc.Country__c == UnderwritingBatchJobConstants.New_Zealand || 
                acc.Country__c == UnderwritingBatchJobConstants.nz1 || 
                acc.Country__c == UnderwritingBatchJobConstants.New_zealand2 || 
                acc.Country__c == UnderwritingBatchJobConstants.new_zealand3 )){
                    return true;
            }
        }
        return false;
    }
    private Boolean underAgeCheck(){
        for(Account acc : applicantAccountList){
            if( acc.Age__c != null && acc.Age__c < 18)
            {
                return true;  
            }
        }
        return false;
    }
   private Boolean hasBeenDeclinedWithin1M(Id appId,String Company){
        List<Id> accListId = new List<Id>();
        for(Account acc : applicantAccountList){
            accListId.add(acc.Id);
        }
        List<clcommon__party__c> partylist = [SELECT Id, 
                                                        Name,
                                                        genesis__Application__c
                                                    FROM clcommon__party__c 
                                                    WHERE clcommon__Account__c IN :accListId
                                                    AND clcommon__Type__r.Name = :UnderwritingBatchJobConstants.BORROWER
                                                    AND Brand__c =: Company
                                                    WITH SECURITY_ENFORCED
                                                    ];
        List<Id> appIdList = new List<Id>();
        for(clcommon__Party__c party : partylist ){
            appIdList.add(party.genesis__Application__c);
        }
        Date presentDate = FlowfiUtil.currentSystemDate;
        Date moddedDate = presentDate.addMonths(-1);
        List<genesis__Applications__c> applist = [SELECT Id,
                                                        genesis__Account__c 
                                                        FROM genesis__Applications__c 
                                                        WHERE Id <> :appId
                                                        AND Company__c =: Company
                                                        AND Id IN :appIdList 
                                                        AND (genesis__Status__c = :UnderwritingBatchJobConstants.APP_AUTO_DECLINED 
                                                        OR genesis__Status__c = :UnderwritingBatchJobConstants.APP_DECLINED)
                                                        AND ( Declined_On__c >= :moddedDate 
                                                        OR Auto_Declined_On__c >= :moddedDate)
                                                        WITH SECURITY_ENFORCED
                                                        ];
        List<genesis__Quick_Quotes__c> qqlist = [SELECT Id,
                                                        Name
                                                        FROM genesis__Quick_Quotes__c
                                                        WHERE genesis__Status__c = :UnderwritingBatchJobConstants.FAILURE
                                                        AND Declined_On__c >= :moddedDate
                                                        AND Company__c =: Company
                                                        AND genesis__Account__c =:applicationObj.genesis__Account__c
                                                        ORDER BY Creation_Date__c  ];               
        if(applist.size() > 0  || qqlist.size() > 0 ){
            return true;
        }
      return false;
    }
    private void setOtherLoanMap(List<genesis__Monthly_Income_Expense_Info__c> explist){
        List<String> finInst = System.Label.Financial_Institution.split(',');
        for(genesis__Monthly_Income_Expense_Info__c exp : explist){
            if(!applicantOtherLoanMap.containsKey(exp.Party__c)){
                applicantOtherLoanMap.put(exp.Party__c, new List<genesis__Monthly_Income_Expense_Info__c>());
                applicantRepaymentAmountMap.put(exp.Party__c, 0);
            }
            if(exp.RecordType.Name == 'Other Loan') {
                List<genesis__Monthly_Income_Expense_Info__c> tempList = applicantOtherLoanMap.get(exp.Party__c);
                tempList.add(exp);
                applicantOtherLoanMap.put(exp.Party__c,tempList);
                if(finInst.contains(exp.CC_financial_institution__c) && exp.Loan_Type__c == 'Personal loan'){
                    applicantRepaymentAmountMap.put(exp.Party__c, applicantRepaymentAmountMap.get(exp.Party__c) + getMonthlyAmount(exp.Repayment_Amount__c,exp.Repayment_Frequency__c));
                }
            }
        }
    }
    private void setExpenseMap(List<genesis__Monthly_Income_Expense_Info__c> explist){
        List<String> finInst = System.Label.Financial_Institution.split(',');
        for(genesis__Monthly_Income_Expense_Info__c exp : explist){
            if(exp.RecordType.Name == 'Expense') {
                applicantExpenseMap.put(exp.Party__c,exp);
            }
        }
    }
    private void setCCLimit(List<genesis__Monthly_Income_Expense_Info__c> explist){
        List<String> finInst = System.Label.CC_Financial_Institution.split(',');
        for(genesis__Monthly_Income_Expense_Info__c exp : explist){
            if(exp.RecordType.Name == 'Credit Card' && finInst.contains(exp.CC_financial_institution__c)){
                if(applicantCCLimitMap.containsKey(exp.Party__c)){
                    applicantCCLimitMap.put(exp.Party__c, applicantCCLimitMap.get(exp.Party__c) + exp.Total_Limit__c);
                } else {
                    applicantCCLimitMap.put(exp.Party__c, exp.Total_Limit__c ==null ?0 :exp.Total_Limit__c);
                }
            }
        }
    }
    private void setEfxMaps(){
        List<ints__EfxReport__c> crdlist = new List<ints__EfxReport__c>();// credit report query using IN : applicantIdList ORDER BY CreatedDate Desc;
        
        for(clcommon__Party__c party : applicantList){
            if(party.EfxReports__r.size()==0){
                continue;
            }
            crdlist.add(party.EfxReports__r[0]);
            applicantEfxScoreMap.put(party.Id,new Map<String,String>());
            applicantEfxCollectionMap.put(party.Id,new List<ints__EfxReport_Collection__c>());
            applicantDefaultMap.put(party.Id,new List<ints__EfxReport_Consumer_Statement__c>());
        }
        if(crdlist==null || crdlist.size()==0){
            return;
        }
        Map<Id,ints__EfxReport__c> crdPartyMap = new  Map<Id,ints__EfxReport__c>(crdList);
        List<ints__EfxReport_Score__c> credEfxScorelist = [SELECT Id,
                                                                  ints__EfxReport__c,
                                                                  ints__description__c,
                                                                  ints__Value__c
                                                                  FROM ints__EfxReport_Score__c
                                                                  WHERE ints__EfxReport__c IN : crdPartyMap.keySet()];
        for(ints__EfxReport_Score__c credScore : credEfxScorelist){
            Id partyId = (crdPartyMap.get(credScore.ints__EfxReport__c)).Party__c ;
            Map<String,String> tempMap = applicantEfxScoreMap.get(partyId);
            tempMap.put(credScore.ints__description__c,credScore.ints__Value__c);
            applicantEfxScoreMap.put(partyId,tempMap);
            
         }
        List<ints__EfxReport_Collection__c> credEfxColleclist = [SELECT Id,
                                                                  ints__EfxReport__c,
                                                                  ints__Code__c,
                                                                  Limit__c,
                                                                  Worst_Payment_Status_L3__c,
                                                                  Credit_Provider__c,
                                                                  Product_Type__c,
                                                                  Responsibility__c
                                                                  FROM ints__EfxReport_Collection__c
                                                                  WHERE ints__EfxReport__c IN : crdPartyMap.keySet()];
        for(ints__EfxReport_Collection__c credCollec : credEfxColleclist){
            Id partyId = (crdPartyMap.get(credCollec.ints__EfxReport__c)).Party__c ;

            List<ints__EfxReport_Collection__c> tempList = applicantEfxCollectionMap.get(partyId);
            tempList.add(credCollec);
            applicantEfxCollectionMap.put(partyId,tempList);
        }
        List<ints__EfxReport_Consumer_Statement__c> consumerStatementQuery = [SELECT Id,
                                                                              ints__DateReported__c,       
                                                                              Defaulted_Balance_Amount__c,
                                                                              ints__EfxReport__c
                                                                              FROM ints__EfxReport_Consumer_Statement__c
                                                                              WHERE ints__EfxReport__c IN : crdPartyMap.keySet()];
        for(ints__EfxReport_Consumer_Statement__c consumerStatement :consumerStatementQuery ){
            Id partyId = (crdPartyMap.get(consumerStatement.ints__EfxReport__c)).Party__c ;
            List<ints__EfxReport_Consumer_Statement__c> consumerList = applicantDefaultMap.get(partyId);
            consumerList.add(consumerStatement);
            applicantDefaultMap.put(partyId, consumerList);
        }
            

    }
    private void setCreditBureauMap(){
        List<ints__Credit_Report__c> crdlist = new List<ints__Credit_Report__c>();// credit report query using IN : applicantIdList ORDER BY CreatedDate Desc;
        for(clcommon__Party__c party : applicantList){
            if(party.Credit_Reports__r.size()==0){
                continue;
            }
            crdlist.add(party.Credit_Reports__r[0]);
        }
        if(crdlist==null || crdlist.size()==0){
            return;
        }
        Map<Id,ints__Credit_Report__c> crdPartyMap = new  Map<Id,ints__Credit_Report__c>(crdList);
        List<ints__Credit_File__c> credFileList = [ SELECT Id,
                                                            CLV_Max_Delinquency_L24M__C,
                                                            Revolving_Block_Code__C,
                                                            Digit_6_GPay_Worst_Account_Status__c,
                                                            Digit_7_Gpay_Delinquency_Status__c,
                                                            CLV_Months_Since_30__c,
                                                            CLV_Months_Since_CO__c,
                                                            ints__Credit_Report__c,
                                                            Monthly_payment_due_instalment_ICBS__c,
                                                            CLV_Current_Cards_Credit_Limit__c,
                                                            CLV_Current_Product_Holdings__c
                                                            FROM ints__Credit_File__c
                                                            WHERE ints__Credit_Report__c IN :crdPartyMap.keySet()];
        for(ints__Credit_File__c credFile : credFileList){
            Id partyId = (crdPartyMap.get(credFile.ints__Credit_Report__c)).Party__c ;
            applicantIBCreditFileMap.put(partyId,credFile);
        }
    }

    public void getPreBureauCheck(){
        applicationObj.Country_Check__c = countryCheck();
        applicationObj.Has_Low_Stated_Income__c = incomeStatedLow();
        applicationObj.Age_Check__c = underAgeCheck();
        applicationObj.Total_No_of_PL_refinances_in_last_12M__c = getPLRefinancesCount();
        applicationObj.No_Primary_Income_Check__c = noPrimaryIncomeCheck();
        applicationObj.Recently_declined_customer__c = hasBeenDeclinedWithin1M(this.appId,applicationObj.Company__c);
        if(applicantIBCreditFileMap.keySet().size()>0){
            applicationObj.GPAY_Delinquency__c = gpayDelinquency();
            applicationObj.CLV_Months_Since_30__c = lfsDelinquency();
           
        }
        update applicationObj;
    }
    public void getPreIllionCheck(){
        if(applicationObj.Company__c != 'GEM' && applicantAccountList[0].Are_you_an_existing_Kiwibank_customer__c != 'Yes'){
            applicantAccountList[0].Are_you_an_existing_Kiwibank_customer__c = kiwiHomeLoanCheck();
            update applicantAccountList;
        }
        applicationObj.Has_judgements_Or_insolvencies__c = hasJudgementsOrinsolvencies();
        applicationObj.Efx_Default_Balance_Amount__c = HasUnpaidDefaultBalanceAmount();
        applicationObj.Equifax_Current_Hardship__c = hasEquifaxCurrentHardship();
        applicationObj.Worst_Payment_Status_L3__c = worstPaymentStatusL3Check();
        applicationObj.Worst_Payment_Status_L3_Check__c = worstPaymentStatusL3DeclineCheck();
        update applicationObj;
    }
    public void getPostIllionCheck(){

    }
    public void getFinalCheck(){
        if(applicantIBCreditFileMap.keySet().size()>0){
            applicationObj.LFS90DaysOverdue__c = LFS90DaysOverdue();
            applicationObj.Has_LFS_Adverse_Block_Code_on_Product__c  = hasAdverseBlockCodeLFSProduct();
            applicationObj.Has_Undisclosed_LFS_Debts__c = undisclosedLFSdebt();
            applicationObj.CLV_Months_Since_CO__c = lfsChargeOffL60M();
            applicationObj.Active_Creditline_Account__c = ActiveCreditlineAccount();
            applicationObj.Is_LFS_Top_Up_Application__c = TopUpApplication();
        }
        applicationObj.Loan_Purposes_In_Text__c = applicationObj.Loan_Purposes__c;
        applicationObj.Expects_circumstantial_change_in_Income__c = expectCicumstantialChangeInIncome();
        applicationObj.Has_Undisclosed_Efx_CCR_Debts__c = hasEfxUndisclosedDebts();
        applicationObj.Has_Involuntary_Close_Suspended_Account__c = hasInvoluntaryCloseSuspendedAccound();
        applicationObj.Mortgage_Repayment_Variance__c = calculateMortgageRepaymentVariance();
        applicationObj.Mogo_Has_PayDay__c = hasPayDay();
        applicationObj.Worst_Payment_Status_L3__c = worstPaymentStatusL3Check();
        applicationObj.Has_Bank_Statement_Adverse_History__c = hasBankStatementAdverseHistory();
        applicationObj.Has_Less_Mogo_Income__c = hasMogoIncomeUnder25();
        applicationObj.Income_Variance__c = calculateIncomeVariance();
        applicationObj.Mogo_Applicant_Account_Name_Different__c = hasDifferentMogoName();
        applicationObj.Has_Rental_Income__c = hasRentalIncome();
        applicationObj.Wrong_Rental_Mortgage_Info__c = wrongRentalMortgageInfoCheck();
        applicationObj.Income_Verified__c = hasIncomeVerified();
        applicationObj.Thin_bureau_file_referral__c = hasBureauFileReferral();
        applicationObj.Has_Lump_Sum_or_Balloon_Payment__c = hasLumpSumOrBallonPayment();
        applicationObj.Mogo_Joint_Account_Flag__c = isMogoJointApplication();
        applicationObj.Is_Self_Employed__c = isSelfEmployed();
        applicationObj.Has_Active_LFS_Accounts_No_IB_Match__c = HasActiveLFSAccountsNoIBMatch();
        applicationObj.Gambling_amount_Net_income__c = maxGamblingPerNetIncome();
        applicationObj.Total_Loan_Above_Referral_Limit__c = appAboveReferralLimit(applicationObj);
        applicationObj.Is_Eidv_Failed__c = isEidvFailed();
        applicationObj.Is_Bio_Needed__c = isBioRequired();
        applicationObj.Has_Another_Inflight_Application__c = hasAnotherInflightApplication();
        if(applicationObj.DupId_check__c != true)
        {
            applicationObj.DupId_check__c = dupidCheck();
        }
        update applicationObj;
    }
    private Boolean gpayDelinquency(){
        for(Id partyId : applicantIBCreditFileMap.keySet()){
            ints__Credit_File__c cred = applicantIBCreditFileMap.get(partyId);
            if(( cred.Digit_6_GPay_Worst_Account_Status__c != null && cred.Digit_6_GPay_Worst_Account_Status__c > 0 )|| ( cred.Digit_7_Gpay_Delinquency_Status__c != null && cred.Digit_7_Gpay_Delinquency_Status__c >= 3 )){  
                return true;
            }
        }
        return false;
    }
    private Boolean lfsDelinquency(){
        for(Id partyId : applicantIBCreditFileMap.keySet()){
            ints__Credit_File__c cred = applicantIBCreditFileMap.get(partyId);
            if( cred.CLV_Months_Since_30__c <= 12){  
                return true;
            }
        }
        return false;
    }
    private Boolean lfsChargeOffL60M(){
        for(Id partyId : applicantIBCreditFileMap.keySet()){
            ints__Credit_File__c cred = applicantIBCreditFileMap.get(partyId);
            if( cred.CLV_Months_Since_CO__c >= 0 && cred.CLV_Months_Since_CO__c <= 60){  
                return true;
            }
        }
        return false;
    }
    private Boolean undisclosedLFSdebt(){
        for(Id partyId : applicantIBCreditFileMap.keySet()){
            ints__Credit_File__c cred = applicantIBCreditFileMap.get(partyId);
            if(((cred.Monthly_payment_due_instalment_ICBS__C > 0 && !applicantRepaymentAmountMap.containsKey(partyId))|| applicantRepaymentAmountMap.get(partyId)< 0.95* cred.Monthly_payment_due_instalment_ICBS__C )
            || ((cred.CLV_Current_Cards_Credit_Limit__c > 0 && !applicantCCLimitMap.containsKey(partyId)) || cred.CLV_Current_Cards_Credit_Limit__c > applicantCCLimitMap.get(partyId))){
                return true;
            }
        }
        return false;
    }
    private String worstPaymentStatusL3Check(){
        List<Worst_Payment_Status__mdt> WorstpaymentStatus =[SELECT Code__c,
                                                                        Hierarchy_Value__c
                                                                FROM Worst_Payment_Status__mdt
                                                                ];
        Map<String,Decimal> WorstpaymentStatusMap = new Map<String,Decimal>();
        for(Worst_Payment_Status__mdt paymStatus: WorstpaymentStatus)
        {
            WorstpaymentStatusMap.put(paymStatus.Code__c,paymStatus.Hierarchy_Value__c);
        }
        Decimal StatusvalueInt = -1;
        String WorstStatus =' ';
        for(Id partyId : applicantEfxCollectionMap.keySet()){
            List<ints__EfxReport_Collection__c> checkVallisted = applicantEfxCollectionMap.get(partyId);
            for(ints__EfxReport_Collection__c collectionValuecheck : checkVallisted ){
                String StatusValue = collectionValuecheck.Worst_Payment_Status_L3__c ;
                Decimal Statusvaluecheck = WorstpaymentStatusMap.get(StatusValue);
                if(Statusvaluecheck>StatusvalueInt)
                {
                    StatusvalueInt = Statusvaluecheck;
                    WorstStatus = StatusValue;
                }     
            }
        }
        return WorstStatus;
    }
    private Boolean worstPaymentStatusL3DeclineCheck(){
        for(Id partyId : applicantEfxCollectionMap.keySet()){
            List<ints__EfxReport_Collection__c> checkVallisted = applicantEfxCollectionMap.get(partyId);
            List<String> paymentStatusDeclineValue = System.Label.Worst_Payment_Status_L3_Check.split(',');
            for(ints__EfxReport_Collection__c collectionValuecheck : checkVallisted ){
                String StatusValue = collectionValuecheck.Worst_Payment_Status_L3__c ;
                if(paymentStatusDeclineValue.contains(StatusValue))
                {
                    return true;
                }  
            }
        }
        return false;
    }
    private Boolean incomeStatedLow(){
        for(clcommon__Party__c applicant : applicantList){
            Decimal netIncomeStated = getTotalStatedIncome(applicant.Incomes__r);
            if(netIncomeStated >= 1975){
                return false;
            }
        }
        return true;
    }
    private Boolean hasBankStatementAdverseHistory(){
        for(clcommon__Party__c party : applicantList){
            if((party.Income_Verification_Process__c == UnderwritingBatchJobConstants.ILLION_OCR || 
                party.Income_Verification_Process__c == UnderwritingBatchJobConstants.ILLION_DIGITAL)
                && (party.Mogo_Reverse_Payment_Count__c > UnderwritingBatchJobConstants.MAX_MOGO_REVERSE_PAYMENT || party.Mogo_Dishonors_Count__c > UnderwritingBatchJobConstants.MAX_MOGO_DISHONORS_COUNT || party.Mogo_Overdraw_Fee_Count__c > UnderwritingBatchJobConstants.MAX_MOGO_OVERDRAW_FEE_COUNT)){
                    return true;
            }
        }
        return false;
    }
    private Boolean wrongRentalMortgageInfoCheck(){
        if(applicationObj.Residential_Status__c == UnderwritingBatchJobConstants.RENT 
        || applicationObj.Residential_Status__c == UnderwritingBatchJobConstants.HOME_WITH_MORTGAGE){
            for(Id partyId :  applicantExpenseMap.keySet()){
                if(applicantExpenseMap.get(partyId)==null){
                    throw new CustomException(UnderwritingBatchJobConstants.EXP_LIST_NOT_FOUND_EX);
                }
                if(applicantExpenseMap.get(partyId).Share_of_monthly_rent__c != null && applicantExpenseMap.get(partyId).Share_of_monthly_rent__c > 0){
                    return false;
                }
            }
        } else{
            return false;
        }
        return true;
    }
    private Boolean noPrimaryIncomeCheck(){
        Boolean result = true;
        for(clcommon__Party__c party: applicantList){
            result = result && (party.Employment_Information__r[0].genesis__Occupation__c.equalsIgnoreCase(UnderwritingBatchJobConstants.UNEMPLOYED));
        }
        return result;
    }
    private Decimal getTotalStatedIncome(List<genesis__Income__c> incomeList){
        Decimal totalIncome = 0;
        for(genesis__Income__c inc : incomeList){
            if(inc.RecordTypeId == Schema.SObjectType.genesis__Income__c.getRecordTypeInfosByDeveloperName().get(UnderwritingBatchJobConstants.PRIMARY_INC).getRecordTypeId()){
                totalIncome += getMonthlyAmount(inc.primary_amount__c==null?0:inc.primary_amount__c,String.valueOf(inc.genesis__Frequency__c));
            } else if(inc.RecordTypeId == Schema.SObjectType.genesis__Income__c.getRecordTypeInfosByDeveloperName().get(UnderwritingBatchJobConstants.ADDITIONAL_INC).getRecordTypeId()){
                totalIncome += getMonthlyAmount(inc.genesis__Amount__c==null?0:inc.genesis__Amount__c,String.valueOf(inc.genesis__Frequency__c));
            }
        }
        return totalIncome;
    }
    private Boolean LFS90DaysOverdue(){
        for(Id partyId : applicantIBCreditFileMap.keySet()){
            ints__Credit_File__c cred = applicantIBCreditFileMap.get(partyId);
            if( cred.CLV_Max_Delinquency_L24M__C >= 4 && cred.CLV_Max_Delinquency_L24M__C <= 7 ){  
                return true;
             }
        }
       return false;
    }
    private Boolean ActiveCreditlineAccount(){
        for(Id partyId : applicantIBCreditFileMap.keySet()){
            ints__Credit_File__c cred = applicantIBCreditFileMap.get(partyId);
            if( (cred.CLV_Current_Product_Holdings__c >= 100000 && cred.CLV_Current_Product_Holdings__c <= 199999) || (cred.CLV_Current_Product_Holdings__c >= 300000 && cred.CLV_Current_Product_Holdings__c <= 399999) ){  
                return true;
             }
        }
       return false;
    }
    private Boolean TopUpApplication(){
        for(Id partyId : applicantIBCreditFileMap.keySet()){
            ints__Credit_File__c cred = applicantIBCreditFileMap.get(partyId);
            List <String> validOptionList = new List <String> {'1','2','3'};
            String clvProd;
            try{
                clvProd = String.valueof(cred.CLV_Current_Product_Holdings__c);
            }catch(Exception e){
                clvProd = '';
            } 
            String sub = clvProd.length()>=3 ? clvProd.substring(2,3) : '';
            if(cred.CLV_Current_Product_Holdings__c > 0 && (validOptionList.contains(sub)) ){
                    return true;
                } 
        }
       return false;
    }
    private Boolean hasAdverseBlockCodeLFSProduct(){
        for(Id partyId : applicantIBCreditFileMap.keySet()){
            ints__Credit_File__c cred = applicantIBCreditFileMap.get(partyId);
            if( cred.Revolving_Block_Code__C >= 1 && cred.Revolving_Block_Code__C < 12){  
                return true;
             }
        }
       return false;
    }
    private Boolean hasMogoIncomeUnder25(){
        for(clcommon__Party__c party: applicantList){
            if ((party.Mogo_Total_Monthly_Income__c !=null) && ((party.Mogo_Total_Monthly_Income__c*12) > 25000)) {
                return false;
            }
        }
        return true;
    }
    private Boolean hasRentalIncome(){
        for(clcommon__Party__c party: applicantList){
            if(party.Incomes__r.size() == 0){
                continue ;
            }
            for(genesis__Income__c inc : party.Incomes__r){
                if(inc.Income_source__c == UnderwritingBatchJobConstants.RENTAL_PPTY_INC){
                    return true;
                }
            }
        }
        return false;
    }
    private Boolean hasLumpSumOrBallonPayment(){
        for(clcommon__Party__c party: applicantList){
            if(party.Do_any_of_your_loans_require_a_lump_sum__c == UnderwritingBatchJobConstants.YES){
                return true;
            }
        }
        return False;
    }
    private Boolean isMogoJointApplication(){
        for(clcommon__Party__c party : applicantList){
            if(party.Mogo_Joint_Account_Flag__c){
                return true;
            }
        }
        return false;
    }
    private Decimal calculateIncomeVariance(){
        //(verified income - declared monthly net income)/declared monthly net income <-30% OR >10%
        verifiedIncome = 0 ;
        Decimal statedIncome = 0;
        Decimal calculatedVariance;
        for(clcommon__Party__c party : applicantList){
            Decimal ADDITIONAL_INC = party.Customer_Stated_Additional_Income__c == null?0: party.Customer_Stated_Additional_Income__c;
            Decimal PRIMARY_INC = party.Customer_Stated_Primary_Income__c == null ? 0:party.Customer_Stated_Primary_Income__c;
            Decimal Goverment_Allowance_INC = party.Customer_Stated_Govt_Allowance__c==null?0: party.Customer_Stated_Govt_Allowance__c;
            Decimal decreaseInIncome = truncateNum(party.Customer_Stated_Decrease_in_Income__c == null ? 0 : party.Customer_Stated_Decrease_in_Income__c);
            verifiedIncome = truncateNum( party.Mogo_Total_Monthly_Income__c == null ? 0 : party.Mogo_Total_Monthly_Income__c );
            statedIncome = ADDITIONAL_INC + PRIMARY_INC +  Goverment_Allowance_INC ;

            if(statedIncome == 0){
                continue ;
            }
            calculatedVariance = truncateNum(((verifiedIncome - statedIncome)*100) / statedIncome) ;
            if(calculatedVariance > 10 || calculatedVariance < -30 ){
                return calculatedVariance ;
            }
        }
        return calculatedVariance;
    }
    public Decimal getMonthlyAmount(Decimal amt , String frequency){
        Decimal calcAmt = 0;
        // amt = truncateNum(amt);
        if(frequency == UnderwritingBatchJobConstants.MONTHLY){
            calcAmt = amt ;
        } else if(frequency == UnderwritingBatchJobConstants.WEEKKLY){
            calcAmt = ( (amt * 52) / 12 );
        } else if(frequency == UnderwritingBatchJobConstants.BI_WEEKLY||frequency == UnderwritingBatchJobConstants.FORTNIGHTLY){
            calcAmt = ( (amt * 26) / 12 );
        } else if(frequency == UnderwritingBatchJobConstants.YEARLY){
            calcAmt = ( amt / 12);
        }
        return calcAmt.setScale(2,System.RoundingMode.DOWN);
    }
    private Boolean isSelfEmployed(){  
        Boolean result = false;
        for(clcommon__Party__c party: applicantList){
            if(party.Employment_Information__r.size() == 0){
                throw new CustomException(UnderwritingBatchJobConstants.NO_EMPLOYMENT_EX+party.Id);
            }
            result = result || (party.Employment_Information__r[0].genesis__Occupation__c.equalsIgnoreCase(UnderwritingBatchJobConstants.SELF_EMPLOYED_EMP));
        }
        return result;
    }
    private Boolean hasDifferentMogoName(){
        for(clcommon__Party__c party: applicantList){
            if(party.Mogo_Applicant_Account_Name_Different__c){
                return true;
            }
        }
        return false;
    }
    private Boolean hasIncomeVerified(){
        for(clcommon__Party__c party: applicantList){
            if(party.Income_Verified__c||party.Mogo_Total_Monthly_Income__c>0){
                return true;
            }
        }
        return false;
    }
    /**
    * @description This method check the conditions for rule 'Thin Bureau File Referral (CPU/UW)'
    * @author Trina Das | 22-09-2023 
    * @return Boolean 
    **/
    private Boolean hasBureauFileReferral(){
        for(clcommon__Party__c party: applicantList){
            Map<String,String> efxCheckMap  = applicantEfxScoreMap.get(party.Id);
            Decimal ageOfLoanInMonths = UnderwritingBatchJobConstants.AGE_OF_LOAN_IN_MONTHS;
            if(efxCheckMap.get(UnderwritingBatchJobConstants.AGE_OF_OLDEST_FILE_LOAN)!=null){
                ageOfLoanInMonths = Decimal.valueOf(efxCheckMap.get(UnderwritingBatchJobConstants.AGE_OF_OLDEST_FILE_LOAN));
            }   
            if(party.clcommon__Account__r.Age__c > UnderwritingBatchJobConstants.APPLICANT_AGE && ageOfLoanInMonths < UnderwritingBatchJobConstants.AGE_OF_OLDEST_FILE){
                return true;
            }
        }
        return false;
    }
    private Boolean hasEfxUndisclosedDebts(){
        Double NoOfOpenMortgageAcValue = 0;
        Double NoOfOpenPersonalLoanAcValue = 0;
        Double SumOfOpenCreditcardAcLimitValue = 0;
        Double EfxScoredefValue = 0;
        Double rentPlusInvstment = 0;
        Double creditCardLimit = 0;
        Double sumOfMortgage = 0 ;
        Double sumOfOtherLoans = 0;
        Double sumOfCreditCardLimits = 0;
        Double statedOtherLoansCount = 0 ;
        List<genesis__Monthly_Income_Expense_Info__c> ccList = [ SELECT Id,
                            RecordType.Name,
                            Party__c,
                            Total_Limit__c,
                            Credit_Card_Limit__c, 
                            Total_Balance__c,
                            To_be_paid_out__c, 
                            CC_financial_institution__c, 
                            CC_Other_financial_Institution__c 
                            FROM genesis__Monthly_Income_Expense_Info__c
                            WHERE Application__c = :applicationObj.Id
                            AND RecordTypeId = :Schema.SObjectType.genesis__Monthly_Income_Expense_Info__c.getRecordTypeInfosByDeveloperName().get(UnderwritingBatchJobConstants.CREDIT_CARD).getRecordTypeId()
                            WITH SECURITY_ENFORCED ];
        for(genesis__Monthly_Income_Expense_Info__c cc : ccList){
            creditCardLimit += (cc.Total_Limit__c == null ) ? 0: cc.Total_Limit__c;
        }
        Map<String,Decimal> OpenOverdraftAcMap = returnOverdraftCount();

        for(clcommon__Party__c party: applicantList){
            Map<String,String> EfxCheck  = applicantEfxScoreMap.get(party.Id);
            String NoOfOpenMortgageAc = EfxCheck.get('VCR002');
            NoOfOpenMortgageAcValue = returnDecimalValue(NoOfOpenMortgageAc);
            String NoOfOpenPersonalLoanAc = EfxCheck.get('VCR009');
            NoOfOpenPersonalLoanAcValue = returnDecimalValue(NoOfOpenPersonalLoanAc);
            String SumOfOpenCreditcardAcLimit = EfxCheck.get('VCR044');
            SumOfOpenCreditcardAcLimitValue = returnDecimalValue(SumOfOpenCreditcardAcLimit);
            Decimal OpendreftV = OpenOverdraftAcMap.get(party.Id);
            sumOfMortgage += NoOfOpenMortgageAcValue ;
            sumOfOtherLoans += NoOfOpenPersonalLoanAcValue + OpendreftV;
            sumOfCreditCardLimits += SumOfOpenCreditcardAcLimitValue;
           //creditCardLimit += party.Customer_Stated_Combined_CC_Limit__c;
            rentPlusInvstment += party.Customer_Stated_Investment_on_Property__c;
            rentPlusInvstment += party.Customer_Stated_Rental_Share__c;
            statedOtherLoansCount += applicantOtherLoanMap.get(party.Id).size();
            
        }
        if((sumOfMortgage >= 1 && rentPlusInvstment == 0) 
            ||(sumOfOtherLoans > statedOtherLoansCount)
            ||(sumOfCreditCardLimits > creditCardLimit)){
        return true;
        }
        return false;

    }
    private Boolean hasInvoluntaryCloseSuspendedAccound(){

        for(Id partyId : applicantEfxCollectionMap.keySet()){
            List<ints__EfxReport_Collection__c> checkValueListType = applicantEfxCollectionMap.get(partyId);
            List<String> NegAccountTypelist = System.Label.NegativeAccountType.split(',');
            for(ints__EfxReport_Collection__c checkValue : checkValueListType ){
                if(NegAccountTypelist.contains(checkValue.ints__Code__c))
                {
                    return true;
                }
            }
        }
        return false;
    }
    
    /**
    * @description This method checks the condition for rule 'System calculated Mortgage repayment variance >10%'
    * @author Souvik Sen | 27.09.2024 | Ticket LMNZ-762
    * @return Boolean 
    **/
    private Boolean calculateMortgageRepaymentVariance(){
      Double systemMortgageAmount = 0;
      List<clcommon__Category_Attachment_Association__c> bankDocumentList = new List<clcommon__Category_Attachment_Association__c>();
      bankDocumentList=[SELECT Id,Type__c 
                                FROM clcommon__Category_Attachment_Association__c 
                                WHERE clcommon__Document_Category__r.genesis__Application__c = :appId 
                                AND clcommon__Document_Category__r.clcommon__Category_Name__c = :UnderwritingBatchJobConstants.BANK_DOCUMENT_TYPE
                                AND Type__c = :UnderwritingBatchJobConstants.BANK_DOCUMENT_CATEGORY
                                WITH SYSTEM_MODE];
      
        for(Id partyId : applicantEfxCollectionMap.keySet()){
            List<ints__EfxReport_Collection__c> efxReportValueListType = applicantEfxCollectionMap.get(partyId);
            for(ints__EfxReport_Collection__c efxReportValue : efxReportValueListType){
                if(efxReportValue.Product_Type__c == 'RM' && efxReportValue.Responsibility__c == 1 && bankDocumentList.isEmpty()){
                     systemMortgageAmount += Double.valueOf(Double.valueOf(efxReportValue.Limit__c) * ((Nz_custom_settings__c.getInstance().Flat_APR_Rate__c/100)/12) * math.pow(Double.valueOf(1+(Nz_custom_settings__c.getInstance().Flat_APR_Rate__c/100)/12), Double.valueOf(Nz_custom_settings__c.getInstance().Term_Of_Loan__c))/ (math.pow(Double.valueOf(1+ (Nz_custom_settings__c.getInstance().Flat_APR_Rate__c/12)),Double.valueOf(Nz_custom_settings__c.getInstance().Term_Of_Loan__c)) -1));                   
                }
            }
        }
        return systemMortgageAmount>0? Double.valueOf(applicantList[0].Customer_Stated_Rental_Share__c/systemMortgageAmount)>Nz_custom_settings__c.getInstance().Referral_Rule_Variance__c:false;
    }


    private Boolean hasJudgementsOrinsolvencies(){
        Double EfxjudgementValue = 0;
        Double EfxInsolvencyValue =0;
        Double EfxbankruptcyValue =0;
        for(Id partyId : applicantEfxScoreMap.keySet()){
            Map<String,String> EfxCheck  = applicantEfxScoreMap.get(partyId);
            String Efxjudgement = EfxCheck.get('judgement-count');
            EfxjudgementValue = returnDecimalValue(Efxjudgement);
            String EfxInsolvency = EfxCheck.get('insolvency-count');
            EfxInsolvencyValue = returnDecimalValue(EfxInsolvency);
            String Efxbankruptcy = EfxCheck.get('bankruptcy-count');
            EfxbankruptcyValue = returnDecimalValue(Efxbankruptcy);
            
            if(EfxjudgementValue >= 1 || EfxInsolvencyValue >= 1 || EfxbankruptcyValue >= 1)
            {
                return true;
            }
        }
        return false;
    }
    public Map<String,Decimal> returnOverdraftCount(){
        Map<String,Decimal> overDraftPartyMap = new Map<String,Decimal>();
        for(Id partyId : applicantEfxCollectionMap.keySet()){
            List<ints__EfxReport_Collection__c> checkValueList = applicantEfxCollectionMap.get(partyId);
            List<String> codelist = System.Label.OverdraftLabel.split(',');
            Integer countOverdraft = 0;
            for(ints__EfxReport_Collection__c checkValue : checkValueList ){
                if(codelist.contains(checkValue.ints__Code__c) &&  returnDecimalValue(checkValue.Limit__c) < 50000 && checkValue.Product_Type__c =='OD')
                {
                    countOverdraft +=1;
                }
            }
            overDraftPartyMap.put(partyId,countOverdraft);
        }
        return overDraftPartyMap;
    }
    public Decimal returnDecimalValue(String stringObj){
        try{
            return Decimal.valueOf(stringObj);
        } catch( Exception e ){
            return 0;
        }
    }
    private Decimal HasUnpaidDefaultBalanceAmount(){
        Decimal maxDefault = 0 ;
        for(Id partyId : applicantDefaultMap.keySet()){
            List<ints__EfxReport_Consumer_Statement__c> consumerValueList = applicantDefaultMap.get(partyId);
            Date presentDate = FlowfiUtil.currentSystemDate;
            Date moddedDate = presentDate.addMonths(-12);
            Decimal val = 0;
            for(ints__EfxReport_Consumer_Statement__c consumerValue : consumerValueList ){
                if(Date.valueOf(consumerValue.ints__DateReported__c) > moddedDate && Date.valueOf(consumerValue.ints__DateReported__c) <= presentDate){
                     val += consumerValue.Defaulted_Balance_Amount__c!=null?consumerValue.Defaulted_Balance_Amount__c:0;
                }
            }
            if(maxDefault<val){
                maxDefault = val ;
            }
        }
        return maxDefault;
     }
     private Boolean hasPayDay(){
        for(clcommon__Party__c party : applicantList){
            if(party.Mogo_Has_PayDay__c && party.Mogo_Dishonors_Count__c>0){
                return true;
            }
        }
        return false;
    }
     private Boolean hasEquifaxCurrentHardship(){

        for(Id partyId : applicantEfxCollectionMap.keySet()){
            List<ints__EfxReport_Collection__c> collectionList = applicantEfxCollectionMap.get(partyId);
            List<String> negAccountTypelist = System.Label.Hardship_Account_Status.split(',');
            for(ints__EfxReport_Collection__c collectionValue : collectionList ){  
                if(negAccountTypelist.contains(collectionValue.ints__Code__c))
                {
                    return true;
                }
            }
        }
        for(Id partyId : applicantEfxScoreMap.keySet()){
            Map<String,String> EfxCheck  = applicantEfxScoreMap.get(partyId);
            String currentHardship = EfxCheck.get('VCR172');
            if(currentHardship == 'H'){
                return true;
            }
        }
        return false;
    }
    private Boolean IsEFXLatitudeAccount(Id partyId){
        List<ints__EfxReport_Collection__c> collectionList = applicantEfxCollectionMap.get(partyId);
        List<String> lfsActiveAccountStatusList = System.Label.Active_LFS_Account_Status.split(',');
        List<String> lfsActiveCreditProviderList = System.Label.Active_LFS_Credit_Provider.split(',');
        for(ints__EfxReport_Collection__c collectionValue : collectionList ){  
            if(lfsActiveAccountStatusList.contains(collectionValue.ints__Code__c) && lfsActiveCreditProviderList.contains(collectionValue.Credit_Provider__c))
            {
                return true;
            }
        }
        return false;
    }
    private Boolean IsIBExistingLoan(Id partyId){
        ints__Credit_File__c cred = applicantIBCreditFileMap.get(partyId);
        if( cred.CLV_Current_Product_Holdings__c == 0 || cred.CLV_Current_Product_Holdings__c == 999999 ){  
            return true;
        }
        return false;
    }
    private Boolean HasActiveLFSAccountsNoIBMatch(){
        for(Id partyId : applicantEfxCollectionMap.keySet() ){
            if((applicantEfxCollectionMap.containsKey(partyId) && IsEFXLatitudeAccount(partyId))&&
            (!applicantIBCreditFileMap.containsKey(partyId) || IsIBExistingLoan(partyId))){
                return true;
            }
        }
        return false;
    }
    private Decimal getPLRefinancesCount(){
        Double refinanceCount = 0;
        List<loan__Loan_Account__c> loanAclist;
        Date presentDate = FlowfiUtil.currentSystemDate;
        Date moddedDate = presentDate.addMonths(-12);
        for(Account acc : applicantAccountList){
            loanAclist = [Select Id,Top_Up__c From loan__Loan_Account__c Where loan__Account__c =: acc.Id and Top_Up__c =true and CreatedDate >= :moddedDate];
        }
        for(loan__Loan_Account__c loanAc :loanAclist)
        {
                refinanceCount += refinanceCount;
        }
        return refinanceCount;
    }
    private Decimal maxGamblingPerNetIncome(){
        Decimal gamblingPercent = 0 ;
        Decimal maxGamblingPercent = 0;
        for(clcommon__Party__c applicant: applicantList){
            Decimal netStatedIncome = applicant.Customer_Stated_Net_Monthly_Income__c == null ? 0 : applicant.Customer_Stated_Net_Monthly_Income__c;
            Decimal netVerifiedIncome = applicant.Mogo_Total_Monthly_Income__c == null ? 0 : applicant.Mogo_Total_Monthly_Income__c;
            Decimal netIncome = netStatedIncome > netVerifiedIncome ? netStatedIncome : netVerifiedIncome;
            if(netIncome == 0){
                continue;
            }
            gamblingPercent = (applicant.Mogo_Gamb_Txn_Amt__c == null ? 0 : applicant.Mogo_Gamb_Txn_Amt__c)/netIncome;
            if(gamblingPercent > maxGamblingPercent){
                maxGamblingPercent = gamblingPercent;
            }
        }
        return truncateNum(maxGamblingPercent * 100);
    }
    private Boolean appAboveReferralLimit(genesis__Applications__c appObj){
        Decimal referralLimit = (appObj.genesis__CL_Product_Name__c!=null && appObj.genesis__CL_Product_Name__c.contains('Secured'))?appObj.Secured_Referral_Limit__c:appObj.Unsecured_Referral_Limit__c;
        if(referralLimit < appObj.genesis__Loan_Amount__c){
            return true;
        }
        return false;
    }
    //no joint logic taken into consideration for EIDV Failed
    private Boolean isEidvFailed(){
        for(clcommon__Party__c applicant : applicantList){
            if(applicant.EidV_Verification_Status__c == 'NOT VERIFIED'){
                return true;
            }
        }
        return false;
    }
    //no joint logic taken into consideration for BIO
    private Boolean isBioRequired(){
        for(clcommon__Party__c applicant : applicantList){
            if(applicant.EidV_Verification_Status__c == 'PARTIALLY VERIFIED'){
                return true;
            }
        }
        return false;
    }
    private Boolean expectCicumstantialChangeInIncome(){
        for(clcommon__Party__c applicant : applicantlist){
            for(genesis__Income__c inc : applicant.Incomes__r){
                if(inc.RecordType.Name == 'Primary' && inc.Expected_Circumstantial_Change__c == UnderwritingBatchJobConstants.YES){
                    return true;
                }
            }
        }
        return false;
    }
    private Boolean dupidCheck()
    {
        Boolean result = false;
        List<genesis__Application_Department__c> appdept = [SELECT ID,
                                                                    genesis__Application__c,
                                                                    genesis__Status__c,
                                                                    genesis__Department__c
                                                            FROM genesis__Application_Department__c
                                                            WHERE genesis__Application__c =:applicationObj.Id 
                                                            AND genesis__Status__c =: 'Active'
                                                            LIMIT 1];
        if(applicationObj.Fraud_Triggered_Rules__c != null && applicationObj.Fraud_Triggered_Rules__c.contains('dupID'))
        {
            List<genesis__Task_Setup__c> tasksetupcheck = [SELECT ID,
                                                   genesis__Task_Name__c 
                                            FROM genesis__Task_Setup__c
                                            WHERE genesis__Task_Name__c =: 'DUPLICATE IDENTITY DOCUMENT CHECK'
                                            LIMIT 1];
            List<genesis__Department__c> dept  = [SELECT ID,
                                                        Name 
                                                   FROM genesis__Department__c
                                                   WHERE Name=: 'Sales Department' 
                                                   LIMIT 1];                         
            Task taskassign = new Task();
            taskassign.genesis__Department__c = appdept == null || appdept.size() == 0 || appdept[0].genesis__Department__c == null ? dept[0].Id :appdept[0].genesis__Department__c;
            taskassign.genesis__Task_Setup__c = tasksetupcheck[0].ID;
            taskassign.Subject = tasksetupcheck[0].genesis__Task_Name__c;
            taskassign.OwnerId = applicationObj.OwnerId;
            taskassign.genesis__Task_Order__c = 1;
            taskassign.TaskSubtype = 'Task';
            taskassign.genesis__Application__c = applicationObj.Id;
            taskassign.WhatId = applicationObj.Id;
            taskassign.Status = 'OPEN';
            taskassign.Priority ='HIGH';
            taskassign.genesis__Completion_Mandatory__c = true;
            insert taskassign;
            result = true;
        }
        return result;

    }
    private String kiwiHomeLoanCheck(){
        String YES ='Yes',NO ='No'; 
        for(Id partyId : applicantEfxCollectionMap.keySet()){
            List<ints__EfxReport_Collection__c> checkValueListType = applicantEfxCollectionMap.get(partyId);
            List<String> KiwiHomeLoanAccountStatus = System.Label.KiwiHome_Loan.split(',');
            for(ints__EfxReport_Collection__c checkValue : checkValueListType ){
                if(KiwiHomeLoanAccountStatus.contains(checkValue.ints__Code__c) && checkValue.Credit_Provider__c =='KIWIBANK LIMITED' && checkValue.Product_Type__c =='RM')
                {
                    return YES;
                }
            }
        }
        return NO;
    }
    private Boolean hasAnotherInflightApplication(){
        List<String> applicationInFlightStatus = new List<String>{UnderwritingBatchJobConstants.APP_APPROVED, 
                                    UnderwritingBatchJobConstants.APP_DRAW_DOWN_PENDING,
                                    UnderwritingBatchJobConstants.APP_SALES_REFERRED,
                                    UnderwritingBatchJobConstants.APP_CPU_REFERRED,
                                    UnderwritingBatchJobConstants.APP_CCT_REFERRED,
                                    UnderwritingBatchJobConstants.PENDING_DOCUMENTS,
                                    UnderwritingBatchJobConstants.REVIEW_DOCUMENTS,
                                    UnderwritingBatchJobConstants.DISB_INFO_INCOMPLETE,
                                    UnderwritingBatchJobConstants.SERVICE_UNAVAILABLE };
        List<genesis__Applications__c> appInFlightList = [SELECT Id 
                                                                FROM genesis__Applications__c 
                                                                WHERE Borrower_Email__c =: applicationObj.Borrower_Email__c
                                                                AND genesis__Status__c IN :applicationInFlightStatus
                                                                WITH SECURITY_ENFORCED];
        if((!applicationInFlightStatus.contains(applicationObj.genesis__Status__c)&&appInFlightList.size()>0)
        ||appInFlightList.size()>1){
            return true;
        } else {
            return false;
        }
    }
}

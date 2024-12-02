/*********************************************************************************************************
@Class          : BrokerServiceabilityCalculatorTest
@Description    : Test class for BrokerServiceabilityCalculator
@Created Date   : 23/05/2022
@Developer      : Reet Roy
@History        : 
**********************************************************************************************************/
@isTest
private class BrokerServiceabilityCalculatorTest {
    @TestSetup
    static void makeData(){
        FlowfiTestHelper.creatCustomSettings();
        System_Configuration__c systemConfigObj = [Select id,name,Other_Card_Rate__c from System_Configuration__c LIMIT 1];
        systemConfigObj.Other_Card_Rate__c = 0.0382;
		update systemConfigObj;
        Profile profile1 = [Select Id from Profile where name = 'Community User Broker'];
        //Create account
        Account brokerAccount = FlowfiTestHelper.accountCreator();
        brokerAccount.Name = 'Roy Broker';
        insert brokerAccount;
        List<Account> accList = [SELECT Id, 
                                        Name 
                                        from Account 
                                        WHERE Name = 'Roy Broker' 
                                        AND Id = :brokerAccount.Id LIMIT 1];
        System.assert(accList.size()==1,'Account not inserted');
        //Create contact
        Contact contact1 = FlowfiTestHelper.contactCreator(brokerAccount.Id);
        contact1.FirstName = 'Roy';
        contact1.Lastname = 'Broker';
        contact1.Email = 'bruce.wayne@wayneenterprises.com';
        insert contact1;
        List<Contact> conList = [SELECT Id, 
                                        Name 
                                        from Contact 
                                        WHERE Email = 'bruce.wayne@wayneenterprises.com'
                                        AND Id = :contact1.Id LIMIT 1];
        System.assert(conList.size()==1,'Contact not insertedd');

        User brokerUser = new User(
        ProfileId = profile1.Id,
        Username ='bruce.wayne@wayneenterprises.com',
        Alias = 'sp',
        Email='bruce.wayne@wayneenterprises.com',
        EmailEncodingKey='UTF-8',
        Firstname='Roy',
        Lastname='Broker',
        LanguageLocaleKey='en_US',
        LocaleSidKey='en_US',
        TimeZoneSidKey='America/Chicago',
        ContactId = contact1.Id
        );
        insert brokerUser;
        List<User> usrList = [SELECT Id
                                        FROM User 
                                        WHERE Email = 'bruce.wayne@wayneenterprises.com'
                                        AND Id = :brokerUser.Id LIMIT 1];
        System.assert(usrList.size()==1,'User not insertedd');
    }
    @isTest 
    static void successTest(){
        User brokerUser = [SELECT Id 
                                    FROM User 
                                    WHERE Email = 'bruce.wayne@wayneenterprises.com'
                                    AND ISACTIVE = TRUE
                                    LIMIT 1];
        System.runAs(brokerUser){
            BrokerServiceabilityCalculator servObj = new BrokerServiceabilityCalculator();
            Map<String,Object> param = new Map<String,Object>();
            param.put('jsonData','[{\"Broker_Fee\":100,\"rent_mortgage\":1,\"Loan_Amount\":14000,\"Primary_Monthly_Income_Amount_After_Tax\":11,\"calculator_residential_Status\":\"Renting\",\"Interest_Rate\":6,\"Dependants\":\"1\",\"rate_type\":\"Variable\",\"Loan_Term\":\"2\",\"Marital_Status\":\"Divorced/Separated\",\"No_of_dependents\":\"No, half or less\",\"Client_Name\":\"Sandip\"}]');
            clcommon.Response res;
            Test.startTest();
            servObj.setParams(param);
            servObj.execute();
            res = servObj.getPortalResponse();
            Test.stopTest();
            System.assertEquals('SUCCESS',res.status,'Not SUCCESS');
        }
    }
    @isTest
    static void accessDeniedTest(){
        BrokerServiceabilityCalculator servObj = new BrokerServiceabilityCalculator();
        Map<String,Object> param = new Map<String,Object>();
        param.put('jsonData','[{\"Broker_Fee\":100,\"rent_mortgage\":1,\"Loan_Amount\":14000,\"Primary_Monthly_Income_Amount_After_Tax\":11,\"calculator_residential_Status\":\"Renting\",\"Interest_Rate\":6,\"Dependants\":\"1\",\"rate_type\":\"Variable\",\"Loan_Term\":\"2\",\"Marital_Status\":\"Divorced/Separated\",\"No_of_dependents\":\"No, half or less\",\"Client_Name\":\"Sandip\"}]');
        clcommon.Response res;
        Test.startTest();
        servObj.setParams(param);
        servObj.execute();
        res = servObj.getPortalResponse();
        Test.stopTest();
        System.assertEquals('SUCCESS',res.status,'Not SUCCESS');
    }
    @isTest 
    static void nullParamTest(){
        User brokerUser = [SELECT Id 
                                   FROM User 
                                   WHERE Email = 'bruce.wayne@wayneenterprises.com'
                                   AND ISACTIVE = TRUE
                                   LIMIT 1];
        System.runAs(brokerUser){
            BrokerServiceabilityCalculator servObj = new BrokerServiceabilityCalculator();
            Map<String,Object> param = new Map<String,Object>();
            clcommon.Response res;
            Test.startTest();
            servObj.setParams(param);
            servObj.execute();
            res = servObj.getPortalResponse();
            Test.stopTest();
            System.assertEquals('SUCCESS',res.status,'Not SUCCESS');
        }
    }
    @isTest 
    static void mandatoryParamNullTest(){
        User brokerUser = [SELECT Id 
                                    FROM User 
                                    WHERE Email = 'bruce.wayne@wayneenterprises.com'
                                    AND ISACTIVE = TRUE
                                    LIMIT 1];
        System.runAs(brokerUser){
            BrokerServiceabilityCalculator servObj = new BrokerServiceabilityCalculator();
            Map<String,Object> param = new Map<String,Object>();
            param.put('jsonData','[{\"rent_mortgage\":1,\"Loan_Amount\":14000,\"Primary_Monthly_Income_Amount_After_Tax\":11,\"calculator_residential_Status\":\"Renting\",\"Interest_Rate\":6,\"Dependants\":\"1\",\"rate_type\":\"Variable\",\"Loan_Term\":\"2\",\"Marital_Status\":\"Divorced/Separated\",\"No_of_dependents\":\"No, half or less\",\"Client_Name\":\"Sandip\"}]');
            clcommon.Response res;
            Test.startTest();
            servObj.setParams(param);
            servObj.execute();
            res = servObj.getPortalResponse();
            Test.stopTest();
            System.assertEquals('SUCCESS',res.status,'Not SUCCESS');
        }
    }


    @isTest
    static void borrowingLimitTest(){
        User brokerUser = [SELECT Id 
                                    FROM User 
                                    WHERE Email = 'bruce.wayne@wayneenterprises.com'
                                    AND ISACTIVE = TRUE
                                    LIMIT 1];
        System.runAs(brokerUser){
            BrokerServiceabilityCalculator servObj = new BrokerServiceabilityCalculator();
            Map<String,Object> param = new Map<String,Object>();
            Decimal rate = 5;
            Integer term = 5; 
            Decimal umi = 20623.70; 
  
            Decimal borrowingLimit = servObj.calculateBorrowingLimit(rate, term, umi).setScale(2,RoundingMode.DOWN);
            Decimal expectedBorrowingLimit = 1092792.46;

            System.assertEquals(expectedBorrowingLimit, borrowingLimit, 'The borrowing limit calculation is incorrect');
        }
    }
}

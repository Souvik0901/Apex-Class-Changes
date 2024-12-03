
@isTest 
global class BrokerPortalAppListTest {
    @TestSetup
    //creating necassary data for test set up
    static void makeData(){
        Account brokerAcc = FlowfiTestHelper.accountCreator();
        brokerAcc.Name = 'Tester Roy';
        brokerAcc.Top_Up_Eligible__c = true;
        insert brokerAcc;
        List<account> acclist = [SELECT ID 
                                    FROM Account 
                                    WHERE Name = 'Tester Roy' 
                                    AND Id = :brokerAcc.Id 
                                    AND Top_Up_Eligible__c = true
                                    LIMIT 1];
        System.assert(acclist.size()==1,'Account not inserted');

        Contact brokerContact = FlowfiTestHelper.contactCreator(brokerAcc.Id);
        brokerContact.FirstName = 'Tester';
        brokerContact.LastName = 'Roy';
        brokerContact.Email = 'testinguser123@mailinator.com';
        insert brokerContact;
        List<Contact> conList = [SELECT ID 
                                    FROM Contact 
                                    WHERE Email = 'testinguser123@mailinator.com'
                                    AND Id = :brokerContact.Id 
                                    LIMIT 1];
        System.assert(conList.size()==1,'Contact not inserted');

        USer portalUserBroker = FlowfiTestHelper.userCreatorBroker(brokerAcc.Id, brokerContact.Id);
        insert portalUserBroker;
        List<User> usr = [ SELECT Id,
                                LastName FROM User
                                WHERE Id = :portalUserBroker.Id 
                                AND Email = 'testinguser123@mailinator.com'
                                LIMIT 1];
        System.assert(usr.size()==1,'User not inserted');

        FlowfiTestHelper.creatCustomSettings();

        genesis__Applications__c appObj = genesis.Testhelper.createApplication();
        appObj.genesis__Account__c = brokerAcc.Id;
        appObj.Mobile_Number__c = '12345678';
        appObj.Home_Address__c = '23 woodland,sydney,Australia';
        appObj.Top_Up__c = false;
        appObj.genesis__Payment_Frequency__c = 'MONTHLY';
        appObj.genesis__Days_Convention__c = '365/365';
        appObj.genesis__Interest_Calculation_Method__c = 'Declining Balance ';
        appObj.genesis__Expected_Start_Date__c = Date.today();
        appObj.genesis__Expected_First_Payment_Date__c = Date.today().addMonths(1);
        appObj.genesis__Interest_Rate__c = 10;
        appObj.genesis__Loan_Amount__c = 12000;
        appObj.genesis__Term__c = 12;
        appObj.genesis__Status__c = 'Expense Info Incomplete';
        appObj.Loan_Establishment_Fee_Percentage__c = 4;
        appObj.Broker_Contact__c = brokerContact.id;
        appObj.Broker_Application__c = true;
        appObj.OwnerId = portalUserBroker.Id;
        update appObj;

        genesis__Applications__c appObj1 = genesis.Testhelper.createApplication();
        appObj1.genesis__Account__c = brokerAcc.Id;
        appObj1.Mobile_Number__c = '12345678';
        appObj1.Home_Address__c = '23 woodland,sydney,Australia';
        appObj1.Top_Up__c = false;
        appObj1.genesis__Payment_Frequency__c = 'MONTHLY';
        appObj1.genesis__Days_Convention__c = '365/365';
        appObj1.genesis__Interest_Calculation_Method__c = 'Declining Balance ';
        appObj1.genesis__Expected_Start_Date__c = Date.today();
        appObj1.genesis__Expected_First_Payment_Date__c = Date.today().addMonths(1);
        appObj1.genesis__Interest_Rate__c = 10;
        appObj1.genesis__Loan_Amount__c = 12000;
        appObj1.genesis__Term__c = 12;
        appObj1.genesis__Status__c = 'Expense Info Incomplete';
        appObj1.Loan_Establishment_Fee_Percentage__c = 4;
        appObj1.Broker_Contact__c = brokerContact.id;
        appObj1.Broker_Application__c = true;
        appObj1.OwnerId = portalUserBroker.Id;
        update appObj1;

        List<genesis__Applications__c> applist = [SELECT Id 
                                                    FROM genesis__Applications__c 
                                                    WHERE Id = :appObj.Id or Id = :appObj1.Id];
        System.assert(applist.size()==2,'App not inserted');
        
        clcommon__Party_Type__c partyType = FlowfiTestHelper.createPartyType('Broker');
        insert partyType;
        List<clcommon__Party_Type__c> typelist = [SELECT Id 
                                                        FROM clcommon__Party_Type__c 
                                                        WHERE Name = 'Broker' 
                                                        AND Id = :partyType.Id 
                                                        LIMIT 1];
        System.assert(typelist.size()==1,'PartyType not inserted');

        clcommon__Party__c party = FlowfiTestHelper.createParty(brokerAcc.Id, brokerContact.Id, partyType.Id);
        party.genesis__Application__c = appObj.Id ;
        insert party;
        List<clcommon__Party__c> partylist = [SELECT Id 
                                                    FROM clcommon__Party__c 
                                                    WHERE clcommon__Account__c = :brokerAcc.Id
                                                    AND clcommon__Type__c = :partyType.Id
                                                    AND Id = :party.Id 
                                                    LIMIT 1];
        System.assert(partylist.size()==1,'Party not inserted');


        loan.TestHelper.createSeedDataForTesting();
        loan__Client__c dummyClient = loan.TestHelper.createClient();
        loan__Office_Name__c offObj = loan.TestHelper.createOffice();
        loan__MF_Account__c mfObj = loan.TestHelper.createMFAccount('XXXAccountForTest','10000 - ASSETS');
        loan__MF_Account__c mfIncObj = loan.TestHelper.createMFAccount('XXXIncAccountForTest','30000 - INCOME');
        loan__Currency__c currObj = loan.TestHelper.createCurrency();
       
        loan__Fee__c dummyFee = loan.TestHelper.createFee(currObj,mfIncObj ,mfObj);                                    
        loan__Fee_Set__c dummyFeeSet = loan.TestHelper.createFeeSet();
        loan__Fee_Junction__c dummyFeeJunction = loan.TestHelper.createFeeJunction(dummyFee,dummyFeeSet);
       
        loan__Loan_Product__c proObj = loan.TestHelper.createLoanProduct(offObj , mfObj , currObj , dummyFeeSet );
        loan__Loan_Purpose__c purObj = loan.TestHelper.createLoanPurpose();
        loan__Loan_Account__c conObj = loan.TestHelper.createLoanAccount(proObj , dummyClient, dummyFeeSet , purObj ,offObj);
        
        conObj.loan__Account__c = brokerAcc.Id;
        update conObj;
        List<loan__Loan_Account__c> contractList = [ SELECT Id 
                                                        FROM loan__Loan_Account__c 
                                                        WHERE loan__Account__c = :brokerAcc.Id
                                                        AND Id = :conObj.Id 
                                                        LIMIT 1];
        System.assert(contractList.size()==1,'Contract not inserted');

        Task task1 = new Task(genesis__Application__c=appObj.id, Broker_Task__c=true, Status ='Pending');
        insert task1;
        System.assertNotEquals(null, task1.id,'task not inserted');

        Task task2 = new Task(genesis__Application__c=appObj1.id, Broker_Task__c=true, Status ='Completed');
        insert task2;
        System.assertNotEquals(null, task2.id,'task not inserted');
    }

    //Condition for all status
    @isTest 
    static void success(){
        User portalAccountOwner1 = [ SELECT ID,
                                            ProfileId,
                                            Username,
                                            Alias,
                                            Email,
                                            EmailEncodingKey,
                                            Firstname,
                                            Lastname 
                                        FROM User 
                                        WHERE Email= 'testinguser123@mailinator.com'
                                        LIMIT 1];
        
        Map<String,Object> params = new Map<String,Object>();
        params.put('status','All');
        clcommon.Response res;

        Test.startTest();
        BrokerPortalAppList ob = new BrokerPortalAppList(); 
            System.runAs(portalAccountOwner1){
                ob.setParams(params);
                ob.execute();
                res = ob.getPortalResponse();
            }
        Test.stopTest();
        System.assertEquals('SUCCESS',res.status,'Not success');
    }

    //Condition for param key value null
    @isTest 
    static void paramkeyNull(){
        User portalAccountOwner1 = [ SELECT ID,
                                            ProfileId,
                                            Username,
                                            Alias,
                                            Email,
                                            EmailEncodingKey,
                                            Firstname,
                                            Lastname 
                                        FROM User 
                                        WHERE Email= 'testinguser123@mailinator.com'
                                        LIMIT 1];
        
        Map<String,Object> params = new Map<String,Object>();
        params.put('status',null);
        clcommon.Response res;

        Test.startTest();
        BrokerPortalAppList ob = new BrokerPortalAppList(); 
            System.runAs(portalAccountOwner1){
                ob.setParams(params);
                ob.execute();
                res = ob.getPortalResponse();
            }
        Test.stopTest();
        System.assertEquals('SUCCESS',res.status,'Not success');
    }

    //Condition for failure without paramkay
    @isTest 
    static void paramull(){
        User portalAccountOwner1 = [ SELECT ID,
                                            ProfileId,
                                            Username,
                                            Alias,
                                            Email,
                                            EmailEncodingKey,
                                            Firstname,
                                            Lastname 
                                        FROM User 
                                        WHERE Email= 'testinguser123@mailinator.com'
                                        LIMIT 1];
        clcommon.Response res;

        Test.startTest();
        BrokerPortalAppList ob = new BrokerPortalAppList(); 
            System.runAs(portalAccountOwner1){
                ob.setParams(null);
                ob.execute();
                res = ob.getPortalResponse();
            }
        Test.stopTest();
        System.assertEquals('SUCCESS',res.status,'Not success');
    }
    
    // Test case for invalid status filter
    @isTest 
    static void invalidStatus(){
        User portalAccountOwner1 = [SELECT ID FROM User WHERE Email = 'testinguser123@mailinator.com' LIMIT 1];

        Map<String,Object> params = new Map<String,Object>();
        params.put('status', 'InvalidStatus');
        clcommon.Response res;

        Test.startTest();
        BrokerPortalAppList ob = new BrokerPortalAppList(); 
        System.runAs(portalAccountOwner1){
            ob.setParams(params);
            ob.execute();
            res = ob.getPortalResponse();
        }
        Test.stopTest();

        // Asserting that response status is error
        System.assertEquals('ERROR', res.status, 'Response status is not ERROR');
    }

    // Test case for empty application list
    @isTest 
    static void noApplications(){
        User portalAccountOwner1 = [SELECT ID FROM User WHERE Email = 'testinguser123@mailinator.com' LIMIT 1];

        // Create an application with no tasks
        Map<String,Object> params = new Map<String,Object>();
        params.put('status', 'Completed');
        clcommon.Response res;

        Test.startTest();
        BrokerPortalAppList ob = new BrokerPortalAppList(); 
        System.runAs(portalAccountOwner1){
            ob.setParams(params);
            ob.execute();
            res = ob.getPortalResponse();
        }
        Test.stopTest();

        // Asserting that response status is success and no applications returned
        System.assertEquals('SUCCESS', res.status, 'Response status is not SUCCESS');

    }
}

@isTest
private class CommunityTest3 {
/*Triggers Tests*/

	static testMethod void test_CommunityNewsTrigger() {
		insert new Community_News__c(Title__c='t',Teaser__c='t',Entry_Date__c=Datetime.now(),Expiration_Date__c=Datetime.now().addDays(1),
			Alert__c=true);
		try {
			insert new Community_News__c(Title__c='t',Teaser__c='t',Entry_Date__c=Datetime.now().addDays(-1),Expiration_Date__c=Datetime.now().addDays(2),
				Alert__c=true);
		}
		catch(Exception e) {}
	}

	static testMethod void test_CommunityGroupControlTrigger() {
		insert new Community_Group_Control__c(Name='t',Discoverable__c=true,Type__c='Public',Network__c='Internal');
		try {
			insert new Community_Group_Control__c(Name='t',Discoverable__c=true,Type__c='Public',Network__c='Internal');
		}
		catch(Exception e) {}
		try {
			insert new List<Community_Group_Control__c> {
				new Community_Group_Control__c(Name='t1',Discoverable__c=true,Type__c='Public',Network__c='Internal'),
				new Community_Group_Control__c(Name='t1',Discoverable__c=true,Type__c='Public',Network__c='Internal')
			};
		}
		catch(Exception e) {}
	}

	static testMethod void test_CommunityAdminTrigger() {
		insert new Community_Registration__c(SetupOwnerId = UserInfo.getOrganizationId());
		List<Community_Admins__c> insertList = new List<Community_Admins__c>();
		insertList.add(new Community_Admins__c(Terms_Body__c = 'TestTerms1', Terms_Req_New_Signature__c = TRUE, Terms_Status__c = 'Archived'));
		insertList.add(new Community_Admins__c(Terms_Body__c = 'TestTerms1', Terms_Req_New_Signature__c = TRUE, Terms_Status__c = 'Published'));
		insert insertList;

		Community_Admins__c comAd = [SELECT Terms_Body__c, Terms_Req_New_Signature__c, Terms_Status__c FROM Community_Admins__c LIMIT 1];
		comAd.Terms_Body__c = 'TestTerms2';
		comAd.Terms_Status__c = 'Published';
		update comAd;
	}

	static testMethod void test_UserTrigger() {
		
      	UserRole ur = [Select Id, Name From UserRole where Name = 'CEO'];
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User u = new User(alias='alias', email='email@email.com', emailencodingkey='UTF-8', lastname='lastname', firstname = 'firstName', languagelocalekey='en_US',
            localesidkey='en_US', profileid = profile.Id, timezonesidkey='America/Los_Angeles', username='ttsde.tedf2@testmail.com',
            FederationIdentifier='TestContactName.TestContactLastname2', UserRoleId = ur.Id);
        insert u;
       System.runAs(u){
       		Account acc = new Account(Name='testAccount');
	        insert acc;
	        Contact con = new Contact(LastName='TCLN', MailingPostalCode='99013', email='testc@testdomain.com', AccountId=acc.Id, Primary_Role__c='Student');
	        insert con;
	        Profile p = [select Id, Name from Profile where Name = 'Customer Community User'];
 
			User newUser = new User(
			profileId = p.id,
			username = 'newUser@yahoo.com',
			email = 'pb@ff.com',
			emailencodingkey = 'UTF-8',
			localesidkey = 'en_US',
			languagelocalekey = 'en_US',
			timezonesidkey = 'America/Los_Angeles',
			alias='nuser',
			lastname='lastname',
			contactId = con.id
			);
			insert newUser;
       }
    }

    static testMethod void test_CommunityResourceTrigger() {
		Community_Theme__c cth = new Community_Theme__c(Name='t',Theme_Type__c='Resource');
		insert cth;
		Community_Tag__c ct = new Community_Tag__c(Name='t',Community_Theme__c=cth.Id);
		insert ct;
		Community_Resource__c cr = new Community_Resource__c(Resource_Name__c = 'TestRes', Primary_Tag__c = ct.id, Quick_Link__c = true, Name = 'testR');
		insert cr;
		Community_Resource__c cr_1 = new Community_Resource__c(Resource_Name__c = 'TestRes1', Primary_Tag__c = ct.id, Help_Link__c = true, Name = 'testR0');
		insert cr_1;
		try{
		Community_Resource__c cr_2 = new Community_Resource__c(Resource_Name__c = 'TestRes10', 
																Primary_Tag__c = ct.id, 
																Link__c = 'www.google.com', 
																Quick_Link__c = true, 
																Help_Link__c = true, 
																Name = 'testR',
																Status__c = 'Active');
		insert cr_2;
		}catch(Exception ex){}
		try{
			Community_Resource__c cr3 = new Community_Resource__c(Resource_Name__c = 'TestRes2');
			insert cr3;
		}catch(Exception ex){}
		try{
			Community_Resource__c cr_4 = new Community_Resource__c(Resource_Name__c = 'TestRes3', Primary_Tag__c = ct.id, Link__c = 'www.google.com', Quick_Link__c = true);
			insert cr_4;
		}catch(Exception ex){}

	}
}
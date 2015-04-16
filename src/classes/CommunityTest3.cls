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
}
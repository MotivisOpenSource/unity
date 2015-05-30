@isTest(SeeAllData=true)
private class CommunityTest4 {
/*Utility Class Tests*/

	static testMethod void test_CommunityUrlRewriter() {
		CommunityUrlRewriter rewriter = new CommunityUrlRewriter();
		System.assert(rewriter.generateUrlFor(null) == null);
		List<CollaborationGroup> cg = [SELECT Id, Name FROM CollaborationGroup LIMIT 1];
		List<User> us = [SELECT Id, Name FROM User LIMIT 1];
		rewriter.mapRequestUrl(new PageReference('https://motivis-developer-edition.ap2.force.com/studentcommunity/_ui/core/chatter/groups/GroupProfilePage?g='+cg[0].ID+'&filter=requests&fromEmail=1'));
		rewriter.mapRequestUrl(new PageReference('https://motivis-developer-edition.ap2.force.com/studentcommunity/_ui/core/chatter/groups/GroupProfilePage?g='+cg[0].ID+'&u='+us[0].ID+'&fromEmail=1'));
		rewriter.mapRequestUrl(new PageReference('https://motivis-developer-edition.ap2.force.com/studentcommunity/_ui/core/userprofile/?u='+us[0].Id));
		
	}

	static testMethod void test_CommunityUtils() {
		Community_Theme__c cth = new Community_Theme__c(Name='t',Theme_Type__c='Interest');
		insert cth;
		Community_Tag__c ct = new Community_Tag__c(Name='t',Community_Theme__c=cth.Id);
		insert ct;
		//add user and account
		Account acc = new Account(Name='testAccount');
		insert acc;
		Account acc2 = new Account(Name='testAccount2');
		insert acc2;
		Contact con = new Contact(LastName='TCLN', MailingPostalCode='99013', email='testc@testdomain.com', AccountId=acc.Id, Primary_Role__c='Student');
		insert con;
		Contact con2 = new Contact(LastName='TCLN2', MailingPostalCode='99013', email='testc2@testdomain.com', AccountId=acc2.Id, Primary_Role__c='Student');
		insert con2;
		Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		Profile profile2 = [SELECT Id FROM Profile WHERE Name = 'Chatter Free User'];
		User u1 = new User(alias='alias', email='email1@email.com', emailencodingkey='UTF-8', lastname='lastname', firstname = 'firstName', languagelocalekey='en_US',
			localesidkey='en_US', profileid = profile.Id, timezonesidkey='America/Los_Angeles', username='ttsde.tedf1@testmail.com',
			FederationIdentifier='TestContactName.TestContactLastname2', Community_Contact_ID__c=con.Id);
		insert u1;
		User u2 = new User(alias='alias', email='emai345l2@email.com', emailencodingkey='UTF-8', lastname='lastn4ame2', firstname = 'firstName2', languagelocalekey='en_US',
			localesidkey='en_US', profileid = profile2.Id, timezonesidkey='America/Los_Angeles', username='ttsde.tedf2@testmail.com',
			FederationIdentifier='TestCon3456tactName.TestContactLastname2', Community_Contact_ID__c=con2.Id);
		insert u2;
		System.runAs(u2) {
			CommunityUtils.isModifyAllData();
			CommunityUtils.isViewAllData();
			CommunityUtils.canCreateGroup();
			CommunityUtils.getPackagePrefix();
		}
		System.runAs(u1) {
			CommunityUtils.isModifyAllData();
			CommunityUtils.isViewAllData();
			CommunityUtils.canCreateGroup();
			CommunityUtils.getPackagePrefix();
			
			CommunityUtils.getActionButton(ConnectApi.GroupMembershipType.GroupOwner, TRUE);
			CommunityUtils.getActionButton(ConnectApi.GroupMembershipType.GroupManager, TRUE);
			CommunityUtils.getActionButton(ConnectApi.GroupMembershipType.StandardMember, TRUE);
			CommunityUtils.getActionButton(ConnectApi.GroupMembershipType.NotAMember, TRUE);
			CommunityUtils.getActionButton(ConnectApi.GroupMembershipType.NotAMemberPrivateRequested, TRUE);
			
			CommunityUtils.getActionButton(ConnectApi.GroupMembershipType.GroupOwner, FALSE);
			CommunityUtils.getActionButton(ConnectApi.GroupMembershipType.GroupManager, FALSE);
			CommunityUtils.getActionButton(ConnectApi.GroupMembershipType.StandardMember, FALSE);
			CommunityUtils.getActionButton(ConnectApi.GroupMembershipType.NotAMember, FALSE);
			CommunityUtils.getActionButton(ConnectApi.GroupMembershipType.NotAMemberPrivateRequested, FALSE);
						
			CommunityUtils.subscriberUser(u2.Id,TRUE);
			CommunityUtils.subscriberUser(u2.Id,FALSE);	
			
			CommunityUtils.GroupAction ga = new CommunityUtils.GroupAction();
			ga.btnLabel = '1';
			ga.btnIcon = '2';
			ga.title = '3';
			ga.action = '4';
			ga.btnStyle = '5';
			ga.groupId = '6';
			ga.memberCount = '7';
			ga.lnkIcon = '8';
			ga.lnkStyle = '9';
			
			List<Community_Group_Control__c> availibleGroupsControll = [SELECT Chatter_Group_ID__c, Id
					 FROM Community_Group_Control__c
					 WHERE Status__c = 'Approved'];
			List<String> groupIds = new List<String>();
			for (Community_Group_Control__c aGroup : availibleGroupsControll){
				groupIds.add(aGroup.Chatter_Group_ID__c); 
			}		
			CommunityUtils.getNamesOfAvailableGroups(groupIds);
			
			
			List<String> checkFieldList = new List<String> {'Building__c', 'Room__c', 'Street_Address__c', 'City__c', 'State__c', 'Zip__c'};
			Set<String> checkFieldSet = new Set<String>();
			checkFieldSet.addAll(checkFieldList);
			checkFieldSet = CommunityUtils.checkFLSFields('Community_Events__c', checkFieldSet);
			checkFieldSet = CommunityUtils.checkFLSFields('Community_Events__c', null);
			
			string year = '2008';
			string month = '10';
			string day = '5';
			string hour = '12';
			string minute = '20';
			string second = '20';
			string stringDate = year + '-' + month + '-' + day + ' ' + hour + ':' + minute +  ':' + second;
			
			CommunityUtils.checkNewsOverlapInterval(' IsDeleted=false ', Datetime.valueOf(stringDate), Datetime.valueOf(stringDate));
			CommunityUtils.checkNewsOverlapInterval(' IsDeleted=false ', null, Datetime.valueOf(stringDate));
			CommunityUtils.checkNewsOverlapInterval(' IsDeleted=false ', Datetime.valueOf(stringDate), null);
			
			Test.setCurrentPage(Page.CommunityHome);		
			CommunityUtils.checkUrl('   ');
			CommunityUtils.checkUrl('/profilephoto/0F9/F');
			CommunityUtils.checkUrl('motivisSKL/profilephoto/0F9/F');
			
			Map<Id,String> contactToRoleMap = new Map<Id,String>();
			contactToRoleMap.put(con.Id, con.Primary_Role__c);
			CommunityUtils.checkPrimaryProfile(contactToRoleMap);
			
			ApexPages.StandardController stdctrl = new ApexPages.StandardController( new Community_News__c ( Id=[select id from Community_News__c limit 1][0].Id ) );
			Community_News__c newsLocal = (Community_News__c)stdctrl.getRecord();
			PageReference pr = CommunityUtils.checkRedirectToStandardView(newsLocal.Id);
			
			// 1 - Create Chatter Group Member
			// 2 - Delete Chatter Group Member
			// 3 - Create Group Manager
			// 4 - Delete Group Manager
			// 5 - Create Join Private Group Request
			// 6 - Delete Join Private Group Request
			// 7 - Accept Join Private Group Request
			// 8 - Decline Join Private Group Request
			
			CollaborationGroup cg = new CollaborationGroup();
			cg.Name = 'newgroup';
			cg.CollaborationType = 'Public' ;
			insert cg;			
			insert new Community_Group_Control__c(Name='1212t',Discoverable__c=true,Type__c='Public',Network__c='Internal', Chatter_Group_ID__c=cg.Id);
			Community_Group_Control__c control = [SELECT id FROM Community_Group_Control__c  Where Chatter_Group_ID__c =: cg.Id LIMIT 1];
			CommunityUtils.membership(UserInfo.getUserId(), control.Id, '1');
			CommunityUtils.membership(UserInfo.getUserId(), control.Id, '3');
			CommunityUtils.membership(UserInfo.getUserId(), control.Id, '5');
			CommunityUtils.getRequestJoinGroupCount(cg.Id) ;
		}	
	}
	
	static testMethod void test_UnityAdminController() {
		UnityAdminController ua = new UnityAdminController();
		ua.getFieldsCR();
		ua.editCR();
		ua.saveCR();
		ua.cancelCR();
		ua.getFieldsCS();
		ua.editCS();
		ua.saveCS();
		ua.cancelCS();
		ua.getFieldsCTS();
		ua.editCTS();
		ua.saveCTS();
		ua.cancelCTS();
		ua.cr = null;
		ua.saveCR();
		ua.cs = null;
		ua.saveCS();
		ua.cts = null;
		ua.saveCTS();
	}

	static testMethod void test_AddLabelToPackage() {
		String ll = Label.LBL_Page_Title;
		String RegGenInfo = Label.LBL_RegGenInfo_Title;
		String RegInterests = Label.LBL_RegInterests_Title;
		String RegProfilePicture = Label.LBL_RegProfilePicture_Title;
		String RegTerms = Label.LBL_RegTerms_Title;
		String leaveLabel = Label.LBL_LeavePage_Message;
	}
}
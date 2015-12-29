/* 
 * Unity - Communities
 * 
 * Community is critical to the student experience--but building community is 
 * just plain hard. Built on Communities and designed specifically for higher ed, 
 * Unity is a powerful networking tool to help you generate engagement and 
 * connect your campus.
 * 
 * Copyright (C) 2015 Motivis Learning Systems Inc.
 * 
 * This program is free software: you can redistribute it and/or modify 
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 * 
 * To contact Motivis Learning Systems Inc.
 * 25 Pelham Road
 * Salem, NH 03790
 * unity@motivislearning.com
 */

@isTest
private class CommunityTest4 {
/*Utility Class Tests*/
	private static final String testUrl = 'testUrl';
	private static final String messageTypeParam = 'emkind';
	private static final String testId = '123456789';

	private static String prepareFeedItemData() {
		FeedItem testFeedItem = new FeedItem(
			ParentId = UserInfo.getUserId(),
			Body = 'testBody'
		);
		insert testFeedItem;

		return testFeedItem.Id;
	}

	static testMethod void test_CommunityHelperWithoutSharing() {
		CommunityTest3.testDataFactory df = new CommunityTest3.testDataFactory(
			new Set<String> {
				'internalUser',
				'secondInternalUser',
				'communitySuperUser',
				'addRoleToContact'
			}
		);
		Id currentUserId = UserInfo.getUserId();
		

		System.runAs(df.communityUser) {
			CommunityHelperWithoutSharing testHelper = new CommunityHelperWithoutSharing();
			CollaborationGroup cg = new CollaborationGroup();
			cg.Name = 'newgroup';
			cg.CollaborationType = 'Public' ;
			insert cg;
			
			Community_Group_Control__c testControl = new Community_Group_Control__c(
				Name = 'testName',
				Discoverable__c = true,
				Type__c = 'Public',
				Network__c = 'Internal',
				Chatter_Group_ID__c = cg.Id
			);
			insert testControl;

			Community_Group_Manager__c testManager = new Community_Group_Manager__c(
				Group_Manager_User__c = currentUserId,
				Group_Control__c = testControl.Id
			);
			insert testManager;

			CollaborationGroupMember cgmem = new CollaborationGroupMember(
				CollaborationGroupId = cg.id,
				CollaborationRole = 'Admin',
				MemberId = currentUserId,
				NotificationFrequency = 'P'
			);
			insert cgmem;

			System.assertNotEquals(null, CommunityHelperWithoutSharing.getCommunityGroupControl(cg.Id));
			CommunityHelperWithoutSharing.getFeeds(new Set<Id>(), null);
			Community_News__c testNews = new Community_News__c();
			testNews.Title__c = 'Test Title';
			insert testNews;
			Attachment testAttach = new Attachment(
				Name = 'TEMPORARY_UPDATE',
				ParentId = testNews.Id,
				Body = Blob.valueOf(JSON.serialize(testNews))
			);
			insert testAttach;
			CommunityHelperWithoutSharing.getAttachment(testAttach.Id);
			CommunityHelperWithoutSharing.membershipWOSH(currentUserId, testControl.Id, '2');
		}
	}

	static testMethod void commonRewriterTest() {
		String feedItemId = prepareFeedItemData();
		CommunityUrlRewriter testRewriter = new CommunityUrlRewriter();

		PageReference testPageRef = new PageReference(testRewriter.STANDARD_USER_DETAIL_PAGE + testUrl);
		testPageRef.getParameters().put('u', testId);
		testPageRef.getParameters().put('fi', testId);
		testRewriter.mapRequestUrl(testPageRef);

		testPageRef = new PageReference(testRewriter.STANDARD_CHATTER_PAGE + testUrl);
		testRewriter.mapRequestUrl(testPageRef);

		testPageRef = new PageReference(testRewriter.STANDARD_GROUP_DETAIL_PAGE + testUrl);
		testPageRef.getParameters().put('u', testId);
		testPageRef.getParameters().put('g', UserInfo.getUserId());
		testRewriter.mapRequestUrl(testPageRef);

		testPageRef = new PageReference(testUrl);
		testPageRef.getParameters().put(messageTypeParam, testRewriter.CHATTER_PRIVATE_MESSAGE_NOTIFICATION);
		testRewriter.mapRequestUrl(testPageRef);

		testPageRef = new PageReference(testUrl);
		testPageRef.getParameters().put(messageTypeParam, testRewriter.CHATTER_POST_NOTIFICATION);
		testPageRef.getParameters().put('fid', testId);
		testRewriter.mapRequestUrl(testPageRef);

		testPageRef = new PageReference(testUrl);
		testPageRef.getParameters().put(messageTypeParam, testRewriter.CHATTER_COMMENT_NOTIFICATION);
		testPageRef.getParameters().put('fId', feedItemId);
		testPageRef.getParameters().put('s1uid', Userinfo.getUserId());
		testRewriter.mapRequestUrl(testPageRef);

		testPageRef = new PageReference(testUrl);
		testPageRef.getParameters().put(messageTypeParam, testRewriter.CHATTER_COMMENT_NOTIFICATION);
		testPageRef.getParameters().put('fId', feedItemId);
		testPageRef.getParameters().put('s1uid', testId);
		testRewriter.mapRequestUrl(testPageRef);

		System.assertEquals(testRewriter.generateUrlFor(new List<PageReference>()), null);
	}

	static testMethod void test_CommunityUrlRewriter() {
		CommunityUrlRewriter rewriter = new CommunityUrlRewriter();
		System.assert(rewriter.generateUrlFor(null) == null);
		CollaborationGroup cg1 = new CollaborationGroup();
		cg1.Name = 'newgroup';
		cg1.CollaborationType = 'Public' ;
		insert cg1;
		List<CollaborationGroup> cg = [SELECT Id, Name FROM CollaborationGroup LIMIT 1];
		List<User> us = [SELECT Id, Name FROM User LIMIT 1];
		rewriter.mapRequestUrl(new PageReference('https://motivis-developer-edition.ap2.force.com/studentcommunity/_ui/core/chatter/groups/GroupProfilePage?g='+cg[0].ID+'&filter=requests&fromEmail=1'));
		rewriter.mapRequestUrl(new PageReference('https://motivis-developer-edition.ap2.force.com/studentcommunity/_ui/core/chatter/groups/GroupProfilePage?g='+cg[0].ID+'&u='+us[0].ID+'&fromEmail=1'));
		rewriter.mapRequestUrl(new PageReference('https://motivis-developer-edition.ap2.force.com/studentcommunity/_ui/core/userprofile/?u='+us[0].Id));
		
	}

	@IsTest(SeeAllData=true) //need for testing ConnectApi
	static void test_CommunityUtils() {
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
			CommunityUtils.systemTagFilter('testString', 'testString');
			CommunityUtils.getHtmlField('testValue');
			CommunityUtils.isModifyAllData();
			CommunityUtils.isViewAllData();
			CommunityUtils.canCreateGroup();
			CommunityUtils.getPackagePrefix();
			CommunityUtils.isModerateChatterAndModerateNetworkFeeds();
			CommunityUtils.isModerateChatter();
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
			
			Community_Group_Control__c cgc =  new Community_Group_Control__c(Name='ts',Discoverable__c=true,Type__c='Public',Network__c='Internal');
			insert cgc;
			List<Community_Group_Control__c> availibleGroupsControll = [SELECT Chatter_Group_ID__c, Id
					 FROM Community_Group_Control__c
					 WHERE Id =:cgc.Id];
			List<String> groupIds = new List<String>();
			for (Community_Group_Control__c aGroup : availibleGroupsControll){
				groupIds.add(aGroup.Chatter_Group_ID__c); 
			}		
			CommunityUtils.getNamesOfAvailableGroups(groupIds);
			System.assert(CommunityUtils.getNamesOfAvailableGroups(groupIds).size()>0);
			
			
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
			
			insert new Community_News__c(Title__c='t',Teaser__c='t',Entry_Date__c=Datetime.now(),Expiration_Date__c=Datetime.now().addDays(1));

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

			String inURL = CommunityUtils.checkURLforPref('motivisSKL/profilephoto/0F9/F');
			List<String> availGroupIds = CommunityUtils.getIdsOfAvailableGroups(new List<String>{cg.Id});
			Boolean bool = CommunityUtils.checkAPIEnable();

			Map<String, Boolean> crud = CommunityUtils.checkCRUDforObject('Topic');
			System.assertEquals(false, crud.isEmpty());

			Boolean bool1 = CommunityUtils.isFeedTrakingEnabled('Topic', new Map<String, String>{'Name' => 'string'});
			System.assert(bool1 != null);
		}	
	}
	
	static testMethod void test_CommunityUtils2() {
		CommunityTest3.testDataFactory df = new CommunityTest3.testDataFactory(
			new Set<String> {
			'internalUser',
			'secondInternalUser',
			'communitySuperUser',
			'addRoleToContact'
			}
		);

		System.runAs(df.communityUser) {
			CollaborationGroup cg = new CollaborationGroup(
				Name = 'testName',
				CollaborationType = 'Public',
				OwnerId = df.secondCommunityUser.Id
			);
			insert cg;
			CollaborationGroupMember cgmem = new CollaborationGroupMember(
				CollaborationGroupId = cg.id,
				CollaborationRole = 'Admin',
				MemberId = df.communityUser.Id,
				NotificationFrequency = 'P'
			);
			insert cgmem;
			Test.startTest();
			CommunityUtils.changeManagerRoleToStandard(new Set<Id>{cgmem.Id});
			Test.stopTest();
			CollaborationGroupMember cgm = [SELECT Id, CollaborationRole FROM CollaborationGroupMember WHERE Id = :cgmem.Id];
			System.assert(cgm.CollaborationRole == 'Standard');
		}
	}

	static testMethod void test_UnityAdminController() {
		UnityAdminController ua = new UnityAdminController();
		ua.getFieldsCR();
		ua.editCR();
		ua.saveCR();
		ua.cancelCR();
		ua.getFieldsCS();
		System.assert(ua.getFieldsCS().size()>0);
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
		ua.getColorSchemeItems();
	}

	static testMethod void test_AddLabelToPackage() {
		String ll = Label.LBL_Page_Title;
		String RegGenInfo = Label.LBL_RegGenInfo_Title;
		String RegInterests = Label.LBL_RegInterests_Title;
		String RegProfilePicture = Label.LBL_RegProfilePicture_Title;
		String RegTerms = Label.LBL_RegTerms_Title;
		String leaveLabel = Label.LBL_LeavePage_Message;
		System.assert(true);
	}

	static testMethod void test_AboutGroupComponentController() {
		System.assert(true);
		//deprecated
	}

	static testMethod void test_CommunityAccessException() {
		Contact nc = new Contact();
		CommunityAccessException exc = new CommunityAccessException(
			CommunityAccess.AccessViolationException,
			CommunityAccessException.ExceptionType.OBJECT_ACCESS_VIOLATION,
			CommunityAccessException.ExceptionReason.NO_DELETE,
			nc.getSObjectType().getDescribe().getName(),
			''
		);
		exc.getExceptionType();
		exc.getExceptionReason();
		exc.getExceptionObject();
		exc.getExceptionField();
		exc.getText();
		System.assert(exc.ExceptionMessage != null);
	}

	@IsTest(SeeAllData=true)
	static void test_CommunityObjectController() {
		CommunityTest3.testDataFactory df = new CommunityTest3.testDataFactory(
			new Set<String> {
				'internalUser',
				'communitySuperUser',
				'createGroupControl',
				'makeApprovedGroup'
			}
		);
		System.runAs(df.communityUser) {
		ApexPages.currentPage().getParameters().put('fieldSetName','EditGroup');
			ApexPages.currentPage().getParameters().put('objectId',df.groupControl.Id);
		ApexPages.currentPage().getParameters().put('objectName','Community_Group_Control__c');
			CommunityObjectController coc3 = new CommunityObjectController();
			System.assert(coc3 != NULL);
		}
		CommunityTest3.testDataFactory df2 = new CommunityTest3.testDataFactory(
			new Set<String> {
				'communityUser',
				'communitySuperUser',
				'addRoleToContact'
			}
		);
		System.runAs(df2.communityUser) {
			Community_Profile__c cp = [SELECT Id FROM Community_Profile__c WHERE Contact__c = :df2.communityUser.ContactId LIMIT 1];
		ApexPages.currentPage().getParameters().put('fieldSetName',CommunityUtils.getPackagePrefix()+'Student_About_Me_1');
		ApexPages.currentPage().getParameters().put('objectId',cp.Id);
		ApexPages.currentPage().getParameters().put('objectName',CommunityUtils.getPackagePrefix()+'Community_Profile__c');
		ApexPages.currentPage().getParameters().put('tn','wrong');
		ApexPages.currentPage().getParameters().put('tfn','wrong');
			CommunityObjectController coc2 = new CommunityObjectController();
			System.assert(coc2 != NULL);
			coc2.saveAction();
		}
	}
}
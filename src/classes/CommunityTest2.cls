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

@IsTest(SeeAllData=true)
private class CommunityTest2 {
/*Component Controllers Tests*/

	@IsTest(SeeAllData=true)
	static void test_CommunityFeedNavigationController() {
		CommunityTest3.testDataFactory df = new CommunityTest3.testDataFactory(
			new Set<String> {
				'internalUser',
				'communitySuperUser',
				'addRoleToContact'
			}
		);

		System.runAs(df.communityUser) {
			CollaborationGroup cg = new CollaborationGroup(Name = 'testGroup', CollaborationType = 'Public');
			insert cg;
			Community_Group_Control__c cgc = new Community_Group_Control__c(Chatter_Group_ID__c = cg.Id, Name='name');
			insert cgc;
			Community_Group_Manager__c cgm = new Community_Group_Manager__c(Group_Control__c = cgc.Id, Group_Manager_User__c = df.communityUser.Id);
			insert cgm;

			ApexPages.currentPage().getParameters().put('gc', cgc.Id);
			CommunityFeedNavigationController cfnc = new CommunityFeedNavigationController();
			cfnc.MessageUnreadCount = 1;
			Boolean sMessage = cfnc.showMessages;
			System.assertEquals(true, sMessage);

			cfnc.chatterGroupId = cg.Id;
			cfnc.getBannerTextLabel();
			Boolean showGM = cfnc.getShowGroupManager();
			System.assertEquals(true, showGM);
			System.assert(cfnc.modalTitle != null);
			System.assert(cfnc.actionPhotoLabel != null);
			System.assert(cfnc.permitions != null);

			cfnc.groupRole = 'testGroupRole';
			System.assertNotEquals('testString', cfnc.controllerPhotoUrl);
			cfnc.groupRole = null;
			System.assertNotEquals('testString', cfnc.controllerPhotoUrl);
			cfnc.controllerPhotoUrl = 'testPhotoURL';
			System.assertNotEquals('testString', cfnc.controllerPhotoUrl);
			System.assertNotEquals('testString', cfnc.getPhotoUrl());
			
			//ApexPages.currentPage().getParameters().put('gc', cgc.Id);
			System.assertNotEquals(null, cfnc.actionPhotoLabel);

			cfnc.blobImageData = 'testString';
			cfnc.cropSize = '30';
			cfnc.cropX = '10';
			cfnc.cropY = '20';
			cfnc.photoName = 'testName';
			cfnc.photoContentType = 'testString';
			//cfnc.photoaction();

			ApexPages.currentPage().getParameters().put('gc', null);
			cfnc = new CommunityFeedNavigationController();
			/*System.assertNotEquals(null, cfnc.actionPhotoLabel);
			
			cfnc.blobImageData = 'testString';
			cfnc.cropSize = '30';
			cfnc.cropX = '10';
			cfnc.cropY = '20';
			cfnc.photoName = 'testName';
			cfnc.photoContentType = 'testString';
			cfnc.photoaction();*/

			/*String photoURL = cfnc.getPhotoUrl();
			cfnc.photoaction();
			PageReference ref = new PageReference('/apex/CommunityFeedNavigation'); 
			Test.setCurrentPage(ref);*/
			cfnc.currentUser = false;

		}
	}

	@IsTest(SeeAllData=true)
	static void test_CommunityFollowController() {
		CommunityTest3.testDataFactory df = new CommunityTest3.testDataFactory(
			new Set<String> {
				'internalUser',
				'secondInternalUser',
				'communitySuperUser',
				'addRoleToContact'
			}
		);
		System.runAs(df.communityUser) {
			CommunityFollowController cfc = new CommunityFollowController();
			cfc.subscriptionParentId = df.secondCommunityUser.Id;
			cfc.follow();
			Boolean follow = cfc.followed;
			System.assertEquals(true, follow);
			cfc.follow();
		}
	}

	@IsTest(SeeAllData=true)
	static void test_CommunityFeedController() {
		CommunityTest3.testDataFactory df = new CommunityTest3.testDataFactory(
			new Set<String> {
				'internalUser',
				'communitySuperUser',
				'addRoleToContact'
			}
		);
		ConnectApi.FeedItem feedItemRep;
		ConnectApi.FeedItem feedItemTop;
		String parentId;
		Topic topicTest;
		System.runAs(df.communityUser) {
			CollaborationGroup cg = new CollaborationGroup(Name='t', CollaborationType = 'Public');
			insert cg;
			CommunityFeedController cfc = new CommunityFeedController();

			Boolean gr = cfc.grID;
			Boolean isTopicCreateable = cfc.isTopicCreateable;
			Boolean isTopicAssignmentCreateable = cfc.isTopicAssignmentCreateable;
			String packagePrefix = cfc.packagePrefix;
			parentId = cfc.parentId;
			String feedType = cfc.feedType;
			Boolean fullMode = cfc.fullMode;
			String parentIdForAtt = cfc.parentIdForAtt;
			String netw = cfc.NetworkId;
			String communityPrefix = cfc.communityPrefix;
			String currentUserPhoto = cfc.currentUserPhoto;
			String postF = CommunityFeedController.postFeed(parentId, 'test feed');
			System.assertEquals(true, postF.length() > 0);

			topicTest = new Topic(Name = 'topic test');
			insert topicTest;
			Map<String, String> params = new Map<String, String>();
			params.put('parentId', parentId);
			params.put('inText', 'test feed');
			params.put('topicId', topicTest.Id);
			String postFParams = CommunityFeedController.postFeeds(params);
			System.assertEquals(true, postF.length() > 0);

			// feed item for test data
			ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
			messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

			ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
			textSegment.text = 'test text #[topic test] and second #[test]';
			messageInput.messageSegments.add(textSegment);

			ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
			mentionSegment.id = df.communityUser.Id;
			messageInput.messageSegments.add(mentionSegment);

			ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
			input.body = messageInput;
			ConnectApi.CommentInput cInput = new ConnectApi.CommentInput();
			cInput.body = messageInput;
			ConnectApi.FeedElementCapabilitiesInput fecInput = new ConnectApi.FeedElementCapabilitiesInput();
			input.capabilities = fecInput;
			String textComment = 'test text comment #[topic test]';
			feedItemRep = ConnectApi.ChatterFeeds.postFeedItem(Network.getNetworkId(), ConnectApi.FeedType.News, parentId, input, null);
			feedItemTop = ConnectApi.ChatterFeeds.postFeedItem(Network.getNetworkId(), ConnectApi.FeedType.News, parentId, input, null);
			ConnectApi.Comment commentRep = ConnectApi.ChatterFeeds.postComment(Network.getNetworkId(), feedItemRep.Id, cInput, null);
		}

		CommunityTest3.testDataFactory df2 = new CommunityTest3.testDataFactory(
			new Set<String> {
				'internalUser',
				'communitySuperUser',
				'addRoleToContact'
			}
		);

		System.runAs(df2.communityUser) {
			ConnectApi.FeedElementPage testPage = new ConnectApi.FeedElementPage();
			List<ConnectApi.FeedItem> testItemList = new List<ConnectApi.FeedItem>();
			testItemList.add(feedItemRep);
			testPage.elements = testItemList;
			ConnectApi.ChatterFeeds.setTestGetFeedElementsFromFeed(
				Network.getNetworkId(), 
				ConnectApi.FeedType.News, 
				parentId, 
				3, 
				ConnectApi.FeedDensity.FewerUpdates, 
				null, 
				1, 
				ConnectApi.FeedSortOrder.LastModifiedDateDesc,
				testPage
			);
			String feed = CommunityFeedController.feeds(parentId, '1', null);
			ConnectApi.FeedElementPage testPage1 = new ConnectApi.FeedElementPage();
			List<ConnectApi.FeedItem> testItemList1 = new List<ConnectApi.FeedItem>();
			testItemList1.add(feedItemTop);
			testPage1.elements = testItemList1;
			ConnectApi.ChatterFeeds.setTestGetFeedElementsFromFeed(
				Network.getNetworkId(),
				ConnectApi.FeedType.News,
				topicTest.Id,
				3,
				ConnectApi.FeedDensity.FewerUpdates,
				null, 
				1, 
				ConnectApi.FeedSortOrder.LastModifiedDateDesc,
				testPage1);
			Map<String, String> params1 = new Map<String, String>();
			params1.put('parentId', parentId);
			params1.put('inFeedType', '1');
			params1.put('inpt', null);
			params1.put('topicId', topicTest.Id);
			String feedForTopic = CommunityFeedController.feedsForTopics(params1);
		}

		System.runAs(df.communityUser) {
			String pComm = CommunityFeedController.postComment(feedItemRep.Id, '@[USER] inCommentText #[topic test]');
			System.assertEquals(true, pComm.length() > 0);

			String gComm = CommunityFeedController.getComments(feedItemRep.Id, '');
			System.assertEquals(true, gComm.length() > 0);
			try {
				CommunityFeedController.inlineAction(feedItemRep.Id, 'fa-flag','test');
			}
			catch (Exception e){
				System.debug('Exception = '+e.getMessage());
			}
			try {
				CommunityFeedController.inlineAction(feedItemRep.Id, 'fa-thumbs-up','test');
			}
			catch (Exception e){
				System.debug('Exception = '+e.getMessage());
			}
			try {
				CommunityFeedController.inlineAction(feedItemRep.Id, 'fa-bookmark','test');
			}
			catch (Exception e){
				System.debug('Exception = '+e.getMessage());
			}
			try {
				CommunityFeedController.inlineAction(feedItemRep.Id, 'fa-times','test');
			}
			catch (Exception e){
				System.debug('Exception = '+e.getMessage());
			}

			Map<String, List<String>> parentTypeParentId = new Map<String, List<String>>();
			Community_Group_Control__c cgc1 = new Community_Group_Control__c();
			cgc1.Name = 'Test group';
			cgc1.Type__c = 'Public';
			cgc1.Discoverable__c = true;
			insert cgc1;
			Community_News__c cn = new Community_News__c();
			cn.Title__c = 'test news';
			insert cn;
			Community_Events__c ce = new Community_Events__c();
			ce.Name__c = 'test event';
			ce.Public__c = true;
			insert ce;
			parentTypeParentId.put('CollaborationGroup', new List<String>{cgc1.Chatter_Group_ID__c});
			parentTypeParentId.put('Community_Group_Control', new List<String>{cgc1.Id});
			parentTypeParentId.put('Community_News', new List<String>{cn.Id});
			parentTypeParentId.put('Community_Events', new List<String>{ce.Id});
			CommunityFeedController.getParentsNames(parentTypeParentId);

			Map<String, String> params2 = new Map<String, String>();
			params2.put('parentId', parentId);

			CommunityFeedController cfc = new CommunityFeedController();
			CommunityFeedController.ChatterActionItem cai = new CommunityFeedController.ChatterActionItem('test', 'test1', 'test2');
			List<CommunityFeedController.ChatterActionItem> lCai = cfc.getAvailableActions();
			String layoutText = CommunityFeedController.actionLayout('FeedItem.TextPost');
			params2.put('jsontext', layoutText);
			CommunityFeedController.postActions(params2);
			String layoutLink = CommunityFeedController.actionLayout('FeedItem.LinkPost');
			params2.put('jsontext', layoutLink);
			CommunityFeedController.postAction(parentId, layoutLink, null, null, null);
			CommunityFeedController.postActions(params2);
			String layoutPoll = CommunityFeedController.actionLayout('FeedItem.PollPost');
			params2.put('jsontext', layoutPoll);
			//CommunityFeedController.postActions(params2);
			Blob blobBody = Blob.valueOf('testingB');
			Attachment att = new Attachment(Name = 'test', ParentId = cgc1.Id, Body = blobBody, ContentType = 'file');
			insert att;
			String iAtt = CommunityFeedController.insertAttacmentIntoFeed(parentId, att.Id, null);
			System.assertEquals(true, iAtt.length() > 0);
			String gUsers = CommunityFeedController.getUsers('lastname');
			System.assertEquals(true, gUsers.length() > 0);
			CommunityFeedController.Content content = new CommunityFeedController.Content();
			content.contentUrl = 'test';
			content.description = 'test';
			content.downloadUrl = 'test';
			content.fileExtension = 'test';
			content.fileSize = 'test';
			content.id = 'test';
			content.renditionUrl = 'test';
			content.title = 'test';
			CommunityFeedController.Link link = new CommunityFeedController.Link();
			link.id = 'test';
			link.url = 'test';
			link.urlName = 'test';
			CommunityFeedController.InlineActionResult ilar = new CommunityFeedController.InlineActionResult('test', 'test1', 'test2');
			CommunityFeedController.Record record = new CommunityFeedController.Record();
			record.id = 'id';
			CommunityFeedController.MessageSegments ms = new CommunityFeedController.MessageSegments();
			ms.name = 'name';
			ms.record = record;
			ms.text = 'text';
			ms.type = 'text';
			CommunityFeedController.Body body = new CommunityFeedController.Body();
			body.text = 'text';
			body.messageSegments = new List<CommunityFeedController.MessageSegments>{ms};
			CommunityFeedController.PollChoice choice = new CommunityFeedController.PollChoice();
			choice.id = 'choice';
			choice.position = 1;
			choice.text = 'choice';
			choice.voteCount = 1;
			choice.voteCountRatio = 1;
			CommunityFeedController.Poll poll = new CommunityFeedController.Poll();
			poll.choices = new List<CommunityFeedController.PollChoice>{choice};
			poll.myChoiceId = 'id';
			poll.totalVoteCount = 2;
			Community_Group_Control__c cgc = new Community_Group_Control__c();
			Community_Group_Control__c cgc2 = new Community_Group_Control__c();
			List<CommunityFeedController.MentionUser> mu = new List<CommunityFeedController.MentionUser>{new CommunityFeedController.MentionUser(cgc, 'photo'), new CommunityFeedController.MentionUser(cgc2, 'photo')};
			mu.sort();

			String resultGetTopics = CommunityFeedController.getTopics('test');
			System.assertEquals(true, resultGetTopics.length() > 0);

			String layoutEvent = CommunityFeedController.actionLayoutSForce(JSON.serialize('Create_Event,Community_Events__c,Name:true,Start:true,End:true,Teaser:false,Website:false,Description:false,Street Address:false'));
			params2.put('jsontext', layoutEvent);
			CommunityFeedController.postActions(params2);

			ConnectApi.FeedElementPage testPage1 = new ConnectApi.FeedElementPage();
			List<ConnectApi.FeedItem> testItemList1 = new List<ConnectApi.FeedItem>();
			testItemList1.add(new ConnectApi.FeedItem());
			testItemList1.add(new ConnectApi.FeedItem());
			testPage1.elements = testItemList1;

			CommunityFeedController.FeedElementPage fep1 = new CommunityFeedController.FeedElementPage();

			List<CommunityFeedController.FeedElement> fel1 = new List<CommunityFeedController.FeedElement>();
			fep1.elements = fel1;
			CommunityFeedController.initialParentId(fep1);
			Test.setCurrentPage(Page.CommunityFeed_MyFeed);
			CommunityFeedController.actionLayoutSForce(null);
		}
	}

	static testMethod void test_CommunityTagDisplayController() {
		CommunityTest3.testDataFactory df = new CommunityTest3.testDataFactory(
			new Set<String> {
				'communityUser',
				'communitySuperUser'
			}
		);

		System.runAs(df.communityUser) {
			Community_News__c cnews = new Community_News__c(Title__c='t',Feature_on_Home_Page_Slot__c = '11',Make_Entry_Sticky__c=true,Status__c = 'Appoowed',Teaser__c='t',Entry_Date__c=Datetime.now(),Expiration_Date__c=Datetime.now().addDays(1));
			insert cnews;
			Community_Theme__c cth = new Community_Theme__c(Name='t',Theme_Type__c='Interest');
			insert cth;
			Community_Tag__c ct = new Community_Tag__c(Name='t',Community_Theme__c=cth.Id);
			insert ct;
			insert new Community_News_Tag__c(Community_News__c=cnews.Id,Community_Tag__c=ct.Id);

			CommunityTagDisplayController ctdc = new CommunityTagDisplayController();
			ctdc.filterName = 'Community_News__c';
			ctdc.objectId = cnews.Id;
			ctdc.objectType = 'Community_News_Tag__c';
			Test.setCurrentPage(Page.CommunityNews);
			List<CommunityTagDisplayController.Tag> tags = ctdc.getTags();
			System.Assert((tags.size()>0),true);
			ctdc.objectType = 'Community_Event_Tag__c';
			ctdc.getMode();
		}
	}

	static testMethod void test_CommunityTagSelectorController() {
		CommunityTest3.testDataFactory df = new CommunityTest3.testDataFactory(
			new Set<String> {
				'communityUser',
				'communitySuperUser'
			}
		);

		System.runAs(df.communityUser) {
			Community_News__c cnews = new Community_News__c(Title__c='t',Feature_on_Home_Page_Slot__c = '12',Make_Entry_Sticky__c=true,Status__c = 'Approved',Teaser__c='t',Entry_Date__c=Datetime.now(),Expiration_Date__c=Datetime.now().addDays(1));
			insert cnews;
			Community_Theme__c cth = new Community_Theme__c(Name='t',Theme_Type__c='Interest');
			insert cth;
			Community_Tag__c ct = new Community_Tag__c(Name='t',Community_Theme__c=cth.Id);
			insert ct;
			insert new Community_News_Tag__c(Community_News__c=cnews.Id,Community_Tag__c=ct.Id);
			CommunityTagSelectorController ctsc = new CommunityTagSelectorController();
			List<CommunityTagSelectorController.ThemeWrapper> tagsList = ctsc.getAvailableTags();
			String tagsString = CommunityTagSelectorController.getTags(NULL,'Interest');
			String tagsString1 = CommunityTagSelectorController.getTags('t','Interest');
			System.Assert(!String.isEmpty(tagsString));
			ctsc.filterName = 'Community_News__c';
			ctsc.objectId = cnews.Id;
			ctsc.objectType = 'Community_News_Tag__c';
			ctsc.tagLimit = 5;
			ctsc.tagRequired = false;
			ctsc.saveTags(tagsString);
			CommunityTagSelectorController.getExistingTags(cnews.Id,'Community_News_Tag__c','Community_News__c');
		}
	}

	static testMethod void test_CommunityMenuController() {
		CommunityTest3.testDataFactory df = new CommunityTest3.testDataFactory(
			new Set<String> {
				'communityUser',
				'communitySuperUser'
			}
		);

		System.runAs(df.communityUser) {
			Test.setCurrentPage(Page.CommunityHome);
			Community_Resource__c crc = new Community_Resource__c(Name = 'testMenuName', Link__c = 'testLinkName', Sort__c = 1, Quick_Link__c = true, Status__c = 'Active');
			insert crc;
			List<CommunityMenuController.LinkItem> testList = CommunityMenuController.LinkItems;
			CommunityMenuController.getIsRegTermsPage();
			CommunityMenuController.getRegistration();
			CommunityMenuController.getShowHideMenu();
			CommunityMenuController.getColorScheme();
			CommunityMenuController.getIsDefaultBackground();
			CommunityMenuController.getBackgroundImageId();

			CommunityMenuController cmc = new CommunityMenuController();
			cmc.getAlert();
			cmc.getHelpLink();
			CommunityMenuController.LinkItem li = new CommunityMenuController.LinkItem('testN','testL');
			System.assertEquals(String.valueOf('testN'),String.valueOf(li.Name));
		}
	}

	static testMethod void test_CommunityHomeComponentController() {
		CommunityTest3.testDataFactory df = new CommunityTest3.testDataFactory(
			new Set<String> {
				'communityUser',
				'communitySuperUser'
			}
		);

		System.runAs(df.communityUser) {
			Community_News__c cnews = new Community_News__c(Title__c='t',Feature_on_Home_Page_Slot__c = '19',Make_Entry_Sticky__c=true,Status__c = 'Appoowed',Teaser__c='t',Entry_Date__c=Datetime.now(),Expiration_Date__c=Datetime.now().addDays(1));
			insert cnews;
			Community_Theme__c cth = new Community_Theme__c(Name='t',Theme_Type__c='Interest');
			insert cth;
			Community_Tag__c ct = new Community_Tag__c(Name='t',Community_Theme__c=cth.Id);
			insert ct;
			insert new Community_News_Tag__c(Community_News__c=cnews.Id,Community_Tag__c=ct.Id);

			insert new Community_News__c(Title__c='t',Make_Entry_Sticky__c=true,Status__c = 'Appoowed',Teaser__c='t',Entry_Date__c=Datetime.now(),Expiration_Date__c=Datetime.now().addDays(1));
			CommunityHomeComponentController chc = new CommunityHomeComponentController();
			chc.getCampusNews();
			System.assert(chc.getCampusNews().size()>0);
			chc.getMyNews();
			CommunityHomeComponentController.News news1 = new CommunityHomeComponentController.News(cnews);
			news1.getImagePath();
		}
	}

	static testMethod void test_CommunityShareController() {
		CommunityTest3.testDataFactory df = new CommunityTest3.testDataFactory(
			new Set<String> {
				'internalUser',
				'communitySuperUser'
			}
		);

		System.runAs(df.communityUser) {
			Community_Theme__c cth = new Community_Theme__c(Name='t',Theme_Type__c='Interest');
			insert cth;
			Community_Tag__c ct = new Community_Tag__c(Name='t',Community_Theme__c=cth.Id);
			insert ct;

			CommunityShareController cscNews = new CommunityShareController();
			CommunityShareController cscEvents = new CommunityShareController();
			Community_News__c cnews = new Community_News__c(Title__c='t',Feature_on_Home_Page_Slot__c = '16',Make_Entry_Sticky__c=true,Status__c = 'Appoowed',Teaser__c='t',Entry_Date__c=Datetime.now(),Expiration_Date__c=Datetime.now().addDays(1));
			insert cnews;
			Community_Events__c cevent = new Community_Events__c(Name__c = 'Event Test',Start__c = system.now(),End__c = system.now().addDays(2),Description__c = 'Description',Public__c = true);
			insert cevent;
			Boolean var1 = cscEvents.availGroups;
			CollaborationGroup cg = new CollaborationGroup();
			cg.Name = 'newgroup';
			cg.CollaborationType = 'Public' ;
			insert cg;

			Community_Group_Control__c group1 = new Community_Group_Control__c(Name='1212t',Discoverable__c=true,Type__c='Public',Network__c='Internal', Chatter_Group_ID__c=cg.Id);
			insert group1;

			Community_Group_Control_Tag__c groupTag = new Community_Group_Control_Tag__c(Group_Control__c=group1.Id,Community_Tag__c=ct.Id);
			insert groupTag;

			Test.setCurrentPage(Page.CommunityGroupDetailPage);	
			ApexPages.currentPage().getParameters().put('gr',group1.Id);
			cscNews.sobj = cnews;
			String idsGroups = group1.Chatter_Group_ID__c;

			CommunityShareController.shareForGroups(idsGroups,'shareComment','sdsdsdsd',cnews.Id,true);
			cscNews.availableGroupsProcess();

			cscEvents.sobj = cevent;
			CommunityShareController.shareForGroups(idsGroups,'shareComment','sdsdsdsd',cevent.Id,true);
			cscEvents.availableGroupsProcess();
			Boolean var2 = cscEvents.availGroups;
			CommunityShareController.getGroupsSelector(null);
			CommunityShareController.getGroups(null);
			System.assert(CommunityShareController.getGroups(null).length()>0);

			cscEvents.shareComment = 'shareComment';
			cscEvents.shareGroup = 'shareGroup';
			cscEvents.message = 'message';
			List<Community_Group_Control__c> li1 = cscEvents.AvailableGroupsControls;
			Boolean var4 = cscEvents.hasMessage;
		}
	}

	static testMethod void test_CommunityTopCategoriesController() {
		CommunityTest3.testDataFactory df = new CommunityTest3.testDataFactory(
			new Set<String> {
				'communityUser',
				'communitySuperUser'
			}
		);

		System.runAs(df.communityUser) {
			Community_News__c cnews = new Community_News__c(Title__c='t121223',Feature_on_Home_Page_Slot__c = '15',Make_Entry_Sticky__c=true,Status__c = 'Appoowed',Teaser__c='t',Entry_Date__c=Datetime.now(),Expiration_Date__c=Datetime.now().addDays(1));
			insert cnews;
			Community_Theme__c cth = new Community_Theme__c(Name='t',Theme_Type__c='Interest');
			insert cth;
			Community_Tag__c ct = new Community_Tag__c(Name='t',Community_Theme__c=cth.Id);
			insert ct;
			insert new Community_News_Tag__c(Community_News__c=cnews.Id,Community_Tag__c=ct.Id);
			CommunityTopCategoriesController ctcc = new CommunityTopCategoriesController();
			ctcc.resourceOnly = false;
			ctcc.setColumns();
			System.assert(ctcc.getWrappedThemes().size()>0);
		}
	}

	@IsTest(SeeAllData=true)
	static void test_CommunityHomeNotificationsController() {
		CommunityTest3.testDataFactory df = new CommunityTest3.testDataFactory(
			new Set<String> {
				'internalUser',
				'secondInternalUser',
				'communitySuperUser',
				'addRoleToContact'
			}
		);

		System.runAs(df.communityUser) {
			CollaborationGroup cg = new CollaborationGroup(Name='t', CollaborationType = 'Public', OwnerId = df.secondCommunityUser.Id);
			insert cg;
			CollaborationGroupMember cgmem = new CollaborationGroupMember(CollaborationGroupId=cg.id, MemberId = df.communityUser.Id,NotificationFrequency='P');
			insert cgmem;
			Community_Group_Control__c cgc = new Community_Group_Control__c(Chatter_Group_ID__c = cg.Id, Name='111111111');
			insert cgc;
			FeedItem testFeedItem = new FeedItem(
				Visibility = 'AllUsers',
				ParentId = cgc.Id,
				Body = 'testBody'
			);
			insert testFeedItem;
			Community_Group_Manager__c cgm = new Community_Group_Manager__c(Group_Control__c = cgc.Id, Group_Manager_User__c = df.communityUser.Id);
			insert cgm;
			CommunityHomeNotificationsController chnc = new CommunityHomeNotificationsController();
			String result = CommunityHomeNotificationsController.notifications();
			String message = 'test message';
			ConnectApi.ChatterMessage cm = ConnectApi.ChatterMessages.sendMessage(Network.getNetworkId(), message, df.secondCommunityUser.Id);
		}

		System.runAs(df.secondCommunityUser) {
			String result1 = CommunityHomeNotificationsController.notifications();
			System.Assert(result1.length()>0);
			
		}
	}
}

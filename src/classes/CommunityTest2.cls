@IsTest(SeeAllData=true)
private class CommunityTest2 {
/*Component Controllers Tests*/
	
	@IsTest(SeeAllData=true)
	static void test_CommunityFeedNavigationController() {
		Account acc = new Account(Name='testAccount');
		insert acc;
		Contact con = new Contact(LastName='TCLN', MailingPostalCode='99013', email='testc@testdomain.com', AccountId=acc.Id, Primary_Role__c='Student');
		insert con;
		Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User u = new User(alias='alias', email='email@email.com', emailencodingkey='UTF-8', lastname='lastname', firstname = 'firstName', languagelocalekey='en_US',
			localesidkey='en_US', profileid = profile.Id, timezonesidkey='America/Los_Angeles', username='ttsde.tedf2@testmail.com',
			FederationIdentifier='TestContactName.TestContactLastname2', Community_Contact_ID__c=con.Id);
		insert u;
		
		CollaborationGroup cg = new CollaborationGroup(Name = 'testGroup', CollaborationType = 'Public');
		insert cg;
		Community_Group_Control__c cgc = new Community_Group_Control__c(Chatter_Group_ID__c = cg.Id);
		insert cgc;
		Community_Group_Manager__c cgm = new Community_Group_Manager__c(Group_Control__c = cgc.Id, Group_Manager_User__c = u.Id);
		insert cgm;
		
		CommunityFeedNavigationController cfnc = new CommunityFeedNavigationController();
		cfnc.MessageUnreadCount = 1;
		Boolean sMessage = cfnc.showMessages;
		System.debug(sMessage);
		System.assertEquals(true, sMessage);		

		cfnc.chatterGroupId = cg.Id;
		Boolean showGM = cfnc.getShowGroupManager();
		System.assertEquals(true, showGM);

		cfnc.photoBody = Blob.valueOf('body');
		cfnc.cropSize = 4;
		cfnc.cropX = 2;
		cfnc.cropY = 2;
		cfnc.photoName = 'test Name';
		cfnc.photoContentType = 'image/jpg';
		Boolean uploadM = cfnc.uploadMode;
		System.assertEquals(false, uploadM);

		cfnc.uploadmode();
		System.assertEquals(true, cfnc.uploadMode);

		String photoURL = cfnc.getUserPhotoUrl();

		PageReference ref = new PageReference('/apex/CommunityFeedNavigation'); 
    	Test.setCurrentPage(ref); 
		PageReference pr = cfnc.photoaction();
		System.assertEquals(true, pr != null);
		
	}
	
	@IsTest(SeeAllData=true)
	static void test_CommunityFollowController() {
		Account acc = new Account(Name='testAccount');
		insert acc;
		Contact con = new Contact(LastName='TCLN', MailingPostalCode='99013', email='testc@testdomain.com', AccountId=acc.Id, Primary_Role__c='Student');
		insert con;
		Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User u = new User(alias='alias', email='email@email.com', emailencodingkey='UTF-8', lastname='lastname', firstname = 'firstName', languagelocalekey='en_US',
			localesidkey='en_US', profileid = profile.Id, timezonesidkey='America/Los_Angeles', username='ttsde.tedf2@testmail.com',
			FederationIdentifier='TestContactName.TestContactLastname2', Community_Contact_ID__c=con.Id);
		insert u;
		User u1 = new User(alias='alias1', email='email1@email.com', emailencodingkey='UTF-8', lastname='lastname1', firstname = 'firstName1', languagelocalekey='en_US',
			localesidkey='en_US', profileid = profile.Id, timezonesidkey='America/Los_Angeles', username='ttsde.tedf21@testmail.com',
			FederationIdentifier='TestContactName.TestContactLastname21', Community_Contact_ID__c=con.Id);
		insert u1;
		
		System.runAs(u){
			
			CommunityFollowController cfc = new CommunityFollowController();
			cfc.subscriptionParentId = u1.Id;
			cfc.follow();
			Boolean follow = cfc.followed;
			System.assertEquals(true, follow);
			cfc.follow();
		}
	}

	@IsTest(SeeAllData=true)
	static void test_CommunityFeedController() {
		Account acc = new Account(Name='testAccount');
		insert acc;
		Contact con = new Contact(LastName='TCLN', MailingPostalCode='99013', email='testc@testdomain.com', AccountId=acc.Id, Primary_Role__c='Student');
		insert con;
		Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User u = new User(alias='alias', email='email@email.com', emailencodingkey='UTF-8', lastname='lastname', firstname = 'firstName', languagelocalekey='en_US',
			localesidkey='en_US', profileid = profile.Id, timezonesidkey='America/Los_Angeles', username='ttsde.tedf2@testmail.com',
			FederationIdentifier='TestContactName.TestContactLastname2', Community_Contact_ID__c=con.Id);
		insert u;	

		CommunityFeedController cfc = new CommunityFeedController();
		String parentId = cfc.parentId;
		String feedType = cfc.feedType;
		Boolean fullMode = cfc.fullMode;
		String parentIdForAtt = cfc.parentIdForAtt;
		String netw = cfc.NetworkId;
		String communityPrefix = cfc.communityPrefix;
		String currentUserPhoto = cfc.currentUserPhoto;
		String postF = CommunityFeedController.postFeed(parentId, 'test feed');
		
		System.assertEquals(true, postF.length() > 0);
		
		ConnectApi.FeedElementPage testPage = new ConnectApi.FeedElementPage();
        List<ConnectApi.FeedItem> testItemList = new List<ConnectApi.FeedItem>();
        testItemList.add(new ConnectApi.FeedItem());
        testItemList.add(new ConnectApi.FeedItem());
        testPage.elements = testItemList;
        
        ConnectApi.ChatterFeeds.setTestGetFeedElementsFromFeed(
        	Network.getNetworkId(), 
        	ConnectApi.FeedType.News, 
        	parentId, 
        	3, 
        	ConnectApi.FeedDensity.FewerUpdates, 
        	'', 
        	8, 
        	ConnectApi.FeedSortOrder.CreatedDateDesc,
        	testPage);

       //  String feed = CommunityFeedController.feeds(parentId, '1', '');
       // System.assertEquals(true, feed.length() > 0);

        String pComm = CommunityFeedController.postComment('fake Id', 'inCommentText');
        System.assertEquals(true, pComm.length() > 0);

        String gComm = CommunityFeedController.getComments('fake id', '');
        System.assertEquals(true, gComm.length() > 0);

        try{
        	CommunityFeedController.inlineAction('fake id', 'fa-flag','');
			CommunityFeedController.inlineAction('fake id', 'fa-thumbs-up','');
			CommunityFeedController.inlineAction('fake id', 'fa-bookmark','');
			CommunityFeedController.inlineAction('fake id', 'fa-times','');
		}catch (Exception e){
			System.debug('Exception = '+e.getMessage());
		}
        CommunityFeedController.ChatterActionItem cai = new CommunityFeedController.ChatterActionItem('test', 'test1', 'test2');
        List<CommunityFeedController.ChatterActionItem> lCai = cfc.getAvailableActions();

		String layoutText = CommunityFeedController.actionLayout('FeedItem.TextPost');
		CommunityFeedController.postAction(parentId, layoutText, null, null, null);
		String layoutLink = CommunityFeedController.actionLayout('FeedItem.LinkPost');
		CommunityFeedController.postAction(parentId, layoutLink, null, null, null);
		String layoutPoll = CommunityFeedController.actionLayout('FeedItem.PollPost');
		CommunityFeedController.postAction(parentId, layoutPoll, null, null, null);
		String layoutEvent = CommunityFeedController.actionLayout('Create_Event');
		CommunityFeedController.postAction(parentId, layoutEvent, null, null, null);
		
		Blob blobBody = Blob.valueOf('testingB');
		Attachment att = new Attachment(Name = 'test', ParentId = parentIdForAtt, Body = blobBody, ContentType = 'file');
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
		List<CommunityFeedController.MentionUser> mu = new List<CommunityFeedController.MentionUser>{new CommunityFeedController.MentionUser(cgc, 'photo')};
		mu.sort();	
	}		

	static testMethod void test_CommunityTagDisplayController() {
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
		List<CommunityTagDisplayController.Tag> tags = ctdc.getTags(Page.CommunityNews.getUrl());
		List<CommunityTagDisplayController.Tag> tags2 = ctdc.tags;
		ctdc.objectType = 'Community_Event_Tag__c';
		tags2 = ctdc.tags;
	}

	static testMethod void test_CommunityTagSelectorController() {
		Community_News__c cnews = new Community_News__c(Title__c='t',Feature_on_Home_Page_Slot__c = '12',Make_Entry_Sticky__c=true,Status__c = 'Appoowed',Teaser__c='t',Entry_Date__c=Datetime.now(),Expiration_Date__c=Datetime.now().addDays(1));
		insert cnews;
		Community_Theme__c cth = new Community_Theme__c(Name='t',Theme_Type__c='Interest');
		insert cth;
		Community_Tag__c ct = new Community_Tag__c(Name='t',Community_Theme__c=cth.Id);
		insert ct;
		insert new Community_News_Tag__c(Community_News__c=cnews.Id,Community_Tag__c=ct.Id);
		CommunityTagSelectorController ctsc = new CommunityTagSelectorController();
		List<CommunityTagSelectorController.ThemeWrapper> tagsList = ctsc.getAvailableTags();
		String tagsString = CommunityTagSelectorController.getTags(NULL,'Interest');
		ctsc.filterName = 'Community_News__c';
		ctsc.objectId = cnews.Id;
		ctsc.objectType = 'Community_News_Tag__c';
		ctsc.saveTags(tagsString);
		CommunityTagSelectorController.getExistingTags(cnews.Id,'Community_News_Tag__c','Community_News__c');
	}

	static testMethod void test_CommunityMenuController() {
		//add user and account
		Account acc = new Account(Name='testAccount');
		insert acc;
		Contact con = new Contact(LastName='TCLN', MailingPostalCode='99013', email='testc@testdomain.com', AccountId=acc.Id, Primary_Role__c='Student');
		insert con;
		Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User u = new User(alias='alias', email='email@email.com', emailencodingkey='UTF-8', lastname='lastname', firstname = 'firstName', languagelocalekey='en_US',
			localesidkey='en_US', profileid = profile.Id, timezonesidkey='America/Los_Angeles', username='ttsde.tedf2@testmail.com',
			FederationIdentifier='TestContactName.TestContactLastname2', Community_Contact_ID__c=con.Id);
		insert u;
		
		Test.setCurrentPage(Page.CommunityHome);			
		
		Community_Resource__c crc = new Community_Resource__c();
		crc.Name = 'testMenuName';
		crc.Link__c = 'testLinkName';
		crc.Sort__c = 1;
		crc.Quick_Link__c = TRUE;
		crc.Status__c = 'Active';
		insert crc;
		
		List<CommunityMenuController.LinkItem> testList = CommunityMenuController.LinkItems;
		//System.assertEquals('testMenuName',testList[0].Name);11111111
		//System.assertEquals('testLinkName',testList[0].Link);11111111		
		
		CommunityMenuController.getIsRegTermsPage();
		CommunityMenuController.getRegistration();
				
		CommunityMenuController cmc = new CommunityMenuController();
		cmc.getAlert();
		cmc.getHelpLink();
		
		CommunityMenuController.LinkItem li = new CommunityMenuController.LinkItem('testN','testL');
		//System.assertEquals('testN',li.Name);
		//System.assertEquals('testL',li.Link);
	}

	static testMethod void test_CommunityHomeComponentController() {
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
		chc.getMyNews();
		CommunityHomeComponentController.News news1 = new CommunityHomeComponentController.News(cnews);
		news1.getImagePath();
	}
	
	
	static testMethod void test_CommunityShareController() {
		Account acc = new Account(Name='testAccount');
		insert acc;
		Contact con = new Contact(LastName='TCLN', MailingPostalCode='99013', email='testc@testdomain.com', AccountId=acc.Id, Primary_Role__c='Student');
		insert con;
		Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User u = new User(alias='alias', email='email@email.com', emailencodingkey='UTF-8', lastname='lastname', firstname = 'firstName', languagelocalekey='en_US',
			localesidkey='en_US', profileid = profile.Id, timezonesidkey='America/Los_Angeles', username='ttsde.tedf2@testmail.com',
			FederationIdentifier='TestContactName.TestContactLastname2', Community_Contact_ID__c=con.Id);
		insert u;
		Community_Theme__c cth = new Community_Theme__c(Name='t',Theme_Type__c='Interest');
		insert cth;
		Community_Tag__c ct = new Community_Tag__c(Name='t',Community_Theme__c=cth.Id);
		insert ct;
		
		System.runAs(u) {
			
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
			insert 	group1;
			
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
			Boolean var3 = cscEvents.showShareButton;
			
			CommunityShareController.getGroupsSelector(null);
			CommunityShareController.getGroups(null);
			
			
			cscEvents.shareComment = 'shareComment';
			cscEvents.shareGroup = 'shareGroup';
			cscEvents.message = 'message';
			Boolean var4 = cscEvents.hasMessage;			
			
		}
	}

	static testMethod void test_CommunityTopCategoriesController() {
		Community_News__c cnews = new Community_News__c(Title__c='t121223',Feature_on_Home_Page_Slot__c = '15',Make_Entry_Sticky__c=true,Status__c = 'Appoowed',Teaser__c='t',Entry_Date__c=Datetime.now(),Expiration_Date__c=Datetime.now().addDays(1));
		insert cnews;
		Community_Theme__c cth = new Community_Theme__c(Name='t',Theme_Type__c='Interest');
		insert cth;
		Community_Tag__c ct = new Community_Tag__c(Name='t',Community_Theme__c=cth.Id);
		insert ct;
		insert new Community_News_Tag__c(Community_News__c=cnews.Id,Community_Tag__c=ct.Id);
		CommunityTopCategoriesController ctcc = new CommunityTopCategoriesController();
		ctcc.resourceOnly = false;
		ctcc.getWrappedThemes();
	}
	
}
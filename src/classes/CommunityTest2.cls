@isTest
private class CommunityTest2 {
/*Component Controllers Tests*/

	static testMethod void test_CommunityFeedNavigationController() {
		CommunityFeedNavigationController.test1();
	}

	static testMethod void test_CommunityFollowController() {
		CommunityFollowController.test1();
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

        String feed = CommunityFeedController.feeds(parentId, '1', '');
        System.assertEquals(true, feed.length() > 0);

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
		CommunityTagDisplayController.test1();
	}

	static testMethod void test_CommunityTagSelectorController() {
		CommunityTagSelectorController.test1();
	}

	static testMethod void test_CommunityMenuController() {
		CommunityMenuController.test1();
	}

	static testMethod void test_CommunityHomeComponentController() {
		CommunityHomeComponentController.test1();
	}

	static testMethod void test_CommunityShareController() {
		CommunityShareController.test1();
	}

	static testMethod void test_CommunityTopCategoriesController() {
		CommunityTopCategoriesController.test1();
	}
	
}
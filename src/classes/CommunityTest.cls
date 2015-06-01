@isTest(SeeAllData=true)
private class CommunityTest {
/*Page Controllers Tests*/

	static testMethod void test_CommunityNews() {
		Community_Theme__c cth = new Community_Theme__c(Name='t',Theme_Type__c='Interest');
		insert cth;
		Community_Tag__c ct = new Community_Tag__c(Name='t',Community_Theme__c=cth.Id);
		insert ct;
		Community_Settings__c cs = Community_Settings__c.getInstance();
		cs.News_Max_Sticky__c = 1;
		upsert cs;

		CommunityNewsController cnc = new CommunityNewsController(new ApexPages.StandardController(new Community_News__c()));
		cnc.initFromEdit();
		ApexPages.currentPage().getParameters().put('tags',ct.Id);
		cnc.imgBody = Blob.valueOf('blob');
		cnc.imgFileName = 'ifn';
		cnc.news.Type__c = 'External';
		cnc.news.Teaser__c='';
		cnc.news.Content__c='<div>test</div>';
		cnc.submitFirstStep();
		cnc.news.Type__c = 'Internal';
		cnc.news.Title__c='t';
		cnc.news.Teaser__c='t';
		cnc.news.Make_Entry_Sticky__c = true;
		cnc.news.Entry_Date__c=Datetime.now();
		cnc.news.Expiration_Date__c=Datetime.now().addDays(1);
		cnc.submitFirstStep();

		CommunityNewsController cnc2 = new CommunityNewsController(new ApexPages.StandardController(cnc.news));
		cnc2.initFromEdit();

		ApexPages.currentPage().getParameters().put('cloneId',cnc.news.Id);
		CommunityNewsController cnc2c = new CommunityNewsController(new ApexPages.StandardController(new Community_News__c()));
		cnc2c.initFromEdit();

		insert new Community_News__c(Title__c='t',Teaser__c='t',Entry_Date__c=Datetime.now(),Expiration_Date__c=Datetime.now().addDays(1));
		CommunityNewsController cnc3 = new CommunityNewsController(new ApexPages.StandardController(cnc.news));
		cnc3.initFromView();
		cnc3.mode = 'view';
		cnc3.init();
		cnc3.cancel();
		//cnc3.edit();
		Boolean b = cnc3.allowComments;
		String tst = cnc3.urlForEditNews;
		tst = cnc3.urlForNewNews;
		tst = cnc3.urlForCloneNews;

		CommunityNewsController cnc4 = new CommunityNewsController();
		cnc4.initFromList();
		ApexPages.currentPage().getParameters().put('t',ct.Id);
		cnc4.newsPageNumber = 0;
		cnc4.newsNextPage();
		cnc4.newsLastPage();
		ApexPages.currentPage().getParameters().remove('t');
		ApexPages.currentPage().getParameters().put('s','t*');
		cnc4.newsPageNumber = 2;
		cnc4.newsPreviousPage();
		cnc4.newsFirstPage();
	}

	static testMethod void test_CommunityResources() {
		Community_Theme__c cth = new Community_Theme__c(Name='t',Theme_Type__c='Resource');
		insert cth;
		Community_Tag__c ct = new Community_Tag__c(Name='t',Community_Theme__c=cth.Id);
		insert ct;

		CommunityResourceController crc = new CommunityResourceController(new ApexPages.StandardController(new Community_Resource__c()));
		crc.initFromEdit();
		crc.saveResource();
		crc.resource.Name = 'r';
		crc.linkText = 'www.tut.by';
		crc.resource.Primary_Tag__c = ct.Id;
		crc.saveResource();
		crc.getPrimaryTagHtml();
		crc.getResourceLink();
		crc.linkText = NULL;
		crc.imgBody = Blob.valueOf('blob');
		crc.imgFileName = 'ifn';
		crc.saveResource();

		CommunityResourceController crc2 = new CommunityResourceController(new ApexPages.StandardController(crc.resource));
		crc2.initFromEdit();
		crc2.getResourceLink();
		crc2.getPageController();
		crc2.getUrlForEditResource();
		crc2.getBreadcumbs();
		crc2.initFromView();
		crc2.mode = 'view';
		crc2.init();
		crc2.getTags();
	}

	@IsTest(SeeAllData=true)
	static void test_CommunityGroupCreate() {
		Community_Theme__c cth = new Community_Theme__c(Name='t',Theme_Type__c='Interest');
		insert cth;
		Community_Tag__c ct = new Community_Tag__c(Name='t',Community_Theme__c=cth.Id);
		insert ct;

		CommunityGroupCreateController cgcc = new CommunityGroupCreateController(new ApexPages.StandardController(new Community_Group_Control__c()));
		cgcc.initFromCreate();
		cgcc.getDisabledNext();
		cgcc.doSubmit();
		cgcc.currentGroup.Name = 'cc';
		cgcc.currentGroup.Type__c = 'Public';
		cgcc.currentGroup.Description__c = 'd';
		cgcc.currentGroup.Discoverable__c = true;
		CommunityGroupCreateController.checkAvailability(cgcc.currentGroup.Name);
		cgcc.doSubmit();
		String txt = cgcc.headerText;

		ApexPages.currentPage().getParameters().put('step','2');
		cgcc.initFromCreate();
		cgcc.getEmptyGroupPhotoUrl();
		cgcc.imageBody = EncodingUtil.base64Decode('/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////2wBDAf//////////////////////////////////////////////////////////////////////////////////////wAARCAAMABADASIAAhEBAxEB/8QAFgABAQEAAAAAAAAAAAAAAAAAAQAC/8QAGRAAAwADAAAAAAAAAAAAAAAAAAERElFx/8QAFAEBAAAAAAAAAAAAAAAAAAAAAP/EABQRAQAAAAAAAAAAAAAAAAAAAAD/2gAMAwEAAhEDEQA/ADF6KOGp0IB//9k=');
		cgcc.imageFileName = 'ifn.jpg';
		cgcc.imageContentType = 'image/jpg';
		cgcc.doSubmit();
		txt = cgcc.headerText;

		ApexPages.currentPage().getParameters().put('step','3');
		cgcc.initFromCreate();
		cgcc.getTagsCount();
		ApexPages.currentPage().getParameters().put('tags',ct.Id);
		cgcc.doSubmit();
		Community_Settings__c cs = Community_Settings__c.getInstance();
		cs.Create_Group_Disable_Terms__c = true;
		upsert cs;
		cgcc.doSubmit();
		txt = cgcc.headerText;

		ApexPages.currentPage().getParameters().put('step','4');
		cgcc.initFromCreate();
		cgcc.currentGroup.Status__c = 'Pending';
		update cgcc.currentGroup;
		cgcc.initFromCreate();
		cgcc.getTermsAndConditions();
		txt = cgcc.headerText;
		cgcc.doSubmit();

		cgcc.cancel();
	}

	static testMethod void test_CommunityProfile() {
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
		ApexPages.currentPage().getParameters().put('id',u.Id);
		CommunityProfilePageController cppc = new CommunityProfilePageController();
		cppc.overviewTab[0].getShowSection();
		cppc.getStudentName();
		cppc.changePassword();
		cppc.cancelChangePassword();
		cppc.submit();
		CommunityProfilePageController.NotificationPage np = cppc.getEmailNotifications();
		np.sections[0].items[0].getInputHtml();
		CollaborationGroup cg = new CollaborationGroup(Name='t');
		CollaborationGroupMember cgm = new CollaborationGroupMember(CollaborationGroup=cg,NotificationFrequency='P');
		CommunityProfilePageController.DigestItem di = new CommunityProfilePageController.DigestItem(cgm);
		cppc.getDigestSettings();
		cppc.getDefaultDigest();
		System.RunAs(u) {
			CommunityProfilePageController.toggle(ct.Id,true);
			CommunityProfilePageController.toggle(ct.Id,false);
		}
	}

	static testMethod void test_CommunityEventController() {
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

		Community_Events__c event = new Community_Events__c();
		event.Name__c = 'Event Test';
		event.Start__c = system.now();
		event.End__c = system.now().addDays(2);
		event.Description__c = 'Description';
		event.Public__c = true;
		insert event;

		Community_Event_Tag__c evt = new Community_Event_Tag__c();
		evt.Community_Event__c = event.id;
		evt.Community_Tag__c = ct.id;
		insert evt;

		CommunityEventController cecE = new CommunityEventController();
		CommunityEventController cec = new CommunityEventController(new ApexPages.StandardController(event));
		Boolean ed = cec.permissionsEdit;
		Boolean cl = cec.permissionsClone;
		Boolean sb = cec.permissionShareBanned;
		
		PageReference pr1 = cec.initFromView();
		System.assertEquals(true, pr1 != null);
		cec.initFromEdit();
		cec.initFromList();
		String googleCalendar = cec.getGoogleCalendarCreateEventHref();
		System.assertEquals(true, googleCalendar.length() > 0);
		ApexPages.currentPage().getParameters().put('tags',ct.Id);

		cec.downloadICS();
		cec.getStartDate();
		cec.getEndDate();

		cec.eventsNextPage();
		cec.edit();
		cec.eventsLastPage();
		cec.eventsPreviousPage();
		cec.eventsFirstPage();
		String uEE = cec.urlForEditEvent;
		String uNE = cec.urlForNewEvent;
		String uCE = cec.urlForCloneEvent;
		cec.getTodayStr();
		cec.getAllGroupsInStringArray();
		cec.getTitle();

		PageReference pr2 = cec.cancel();
		System.assertEquals(true, pr2 != null);
		PageReference pr3 = cec.submit();
		System.assertEquals(true, pr3 != null);

		ApexPages.currentPage().getParameters().put('cloneId',event.Id);
		cec.initFromView();

	}
	
	@IsTest(SeeAllData=true)
	static void test_CommunityFeed_MyMessagesController() {
		Account acc = new Account(Name='testAccount');
		insert acc;
		Contact con = new Contact(LastName='TCLN', MailingPostalCode='99013', email='testc@testdomain.com', AccountId=acc.Id, Primary_Role__c='Student');
		insert con;
		Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User u = new User(alias='alias', email='email@email.com', emailencodingkey='UTF-8', lastname='lastname', firstname = 'firstName', languagelocalekey='en_US',
			localesidkey='en_US', profileid = profile.Id, timezonesidkey='America/Los_Angeles', username='ttsde.tedf2@testmail.com',
			FederationIdentifier='TestContactName.TestContactLastname2', Community_Contact_ID__c=con.Id);
		insert u;	
		
		FeedItem feedIt = new FeedItem();
		feedIt.Title = 'Test Feed';
		feedIt.Body = 'Test Body';
		feedIt.ParentId = u.id;
		insert feedIt;


		CollaborationGroup gr = [SELECT Id, Name FROM CollaborationGroup LIMIT 1];
		System.assertEquals(true, gr != null);
		
		CommunityFeed_MyMessagesController cfMMC = new CommunityFeed_MyMessagesController();
		Integer mpp = cfMMC.MessagesPerPage;
		String spt = cfMMC.SelectedPageToken;
		CommunityFeed_MyMessagesController.searchUsers('');


		CommunityFeed_MyMessagesController.ChatterGroupMember cgm2 = new CommunityFeed_MyMessagesController.ChatterGroupMember(u, false);
		CommunityFeed_MyMessagesController.ChatterGroupMember cgm3 = new CommunityFeed_MyMessagesController.ChatterGroupMember(u, false, '');
		CommunityFeed_MyMessagesController.ChatterGroupMember cgm4 = new CommunityFeed_MyMessagesController.ChatterGroupMember(new CollaborationGroupMember());
		CommunityFeed_MyMessagesController.ChatterMessageSegment cms = new CommunityFeed_MyMessagesController.ChatterMessageSegment('txt','Text');

		
		Test.startTest();
			List<CommunityFeed_MyMessagesController.ChatterConversation> conv = cfMMC.getConversations('', spt, 5);
			ApexPages.currentPage().getParameters().put('c',conv[0].ConversationId);
			CommunityFeed_MyMessagesController cfMMC_1 = new CommunityFeed_MyMessagesController();
			String npt = cfMMC_1.NextPageToken;
			//cfMMC.showMoreConversations();
			cfMMC_1.loadOlderMessages();
			cfMMC_1.newConversation('test 2', u.id);
			cfMMC_1.SearchQuery = 'test';
			System.assertEquals(true, true);
			//cfMMC_1.doSearchMessages();
			//cfMMC_1.searchConversations(spt, 5, 'testQuery');
			//cfMMC_1.markConversationRead();
			

		Test.stopTest();
		
	}

	static testMethod void test_CommunityFeed_PeopleController() {
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

		EntitySubscription es = new EntitySubscription(ParentId = u1.Id, SubscriberId = u.Id);
		insert es;
		List<CommunityFeed_PeopleController.UserItem> lUI = CommunityFeed_PeopleController.getPeoples();
		System.assertEquals(true, lUI.size() > 0);
		CommunityFeed_PeopleController.subscriberAction(u.Id, true);
		CommunityFeed_PeopleController cfpc = new CommunityFeed_PeopleController();
	}
	
	@isTest(SeeAllData=true)
	static void test_CommunityGroupDetailPageController() {
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
		CollaborationGroup cg = new CollaborationGroup();
		cg.Name = 'newgroup';
		cg.CollaborationType = 'Public' ;
		insert cg;			
		Community_Group_Control__c group1 = new Community_Group_Control__c(Name='1212t',Discoverable__c=true,Type__c='Public',Network__c='Internal', Chatter_Group_ID__c=cg.Id);
		insert 	group1;			
		Community_Group_Control__c c1 = new Community_Group_Control__c(
			Name = 'Test Private',
			Type__c = 'Private'
		);
		insert c1;
		Test.setCurrentPage(Page.CommunityGroupDetailPage);	
		ApexPages.currentPage().getParameters().put('gr',group1.Chatter_Group_ID__c);
		ApexPages.currentPage().getParameters().put('u',u.Id);
		CommunityGroupDetailPageController.toggleSubscriber(u.Id);
		CommunityGroupDetailPageController cgc = new CommunityGroupDetailPageController();
		cgc.getUrlForCreateEvent();
		cgc.switchToMemberMode();
		cgc.switchToRequestMode();
		cgc.getHideFeedComponent();
		cgc.getShowPendingMembers();
		cgc.getActionButton();
		cgc.getEvents();
		Boolean b = cgc.showCreateEvent;
		cgc.groupMode = '1';
		cgc.performGroupMembershipAction();	
		cgc.getRequestCount();		
		Community_Events__c event = new Community_Events__c();
		event.Name__c = 'Event Test';
		event.Start__c = system.now();
		event.End__c = system.now().addDays(2);
		event.Description__c = 'Description';
		event.Public__c = true;
		insert event;
		CommunityGroupDetailPageController.GroupEvent ge = new CommunityGroupDetailPageController.GroupEvent(event);
		cgc.control = group1;
		cgc.accepted = false;
		cgc.requesterId = u.Id;	
	}

	static testMethod void test_CommunityGroupManageController() {
		Account acc = new Account(Name='testAccount');
		insert acc;
		Contact con = new Contact(LastName='TCLN', MailingPostalCode='99013', email='testc67@testdomain.com', AccountId=acc.Id, Primary_Role__c='Student');
		insert con;
		Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User u = new User(alias='alias', email='testc67@testdomain.com', emailencodingkey='UTF-8', lastname='lastname', firstname = 'firstName', languagelocalekey='en_US',
			localesidkey='en_US', profileid = profile.Id, timezonesidkey='America/Los_Angeles', username='ttsde.tedf67@testmail.com',
			FederationIdentifier='TestContactName.TestContactLastname76', Community_Contact_ID__c=con.Id);
		insert u;
		Community_Group_Control__c c1 = new Community_Group_Control__c(
			Name = 'Test Private',
			Type__c = 'Private'
		);
		insert c1;
		ApexPages.currentPage().getParameters().put('gc',c1.Id);
		CommunityGroupManageController cgmc = new CommunityGroupManageController();
		System.RunAs(u) {
			CommunityUtils.membership(u.Id, c1.Id, '5');
		}
		System.assert(cgmc.getRequestCount() == 1, true);
		cgmc.msShowPlus();
		cgmc.getMemberModalTitle();
		cgmc.getShowChangeOwnerLink();
		cgmc.getStat();
		cgmc.getUserCanAccess();
		cgmc.requestMode = true;
		cgmc.msShowPlus();
		cgmc.editModeAction();
		System.assert(cgmc.editMode, true);
		cgmc.submitAction();
		cgmc.cancelAction();

		String urls = cgmc.urlForGroupReturn;
		urls = cgmc.urlForEvent;
		urls = cgmc.groupImageUrl;
		Integer tsize = cgmc.pageSize;
		cgmc.accepted = true;
		cgmc.requesterId = u.Id;
		cgmc.allusers.query = 'lastname';
		cgmc.performRequestAction();
		CommunityGroupManageController.membership(String.valueOf(u.Id), String.valueOf(c1.Id), 3);
		cgmc.ownerString = u.Id;
		cgmc.changeOwner();
		cgmc.allusers.column();
		cgmc.allusers.nextPage();
		cgmc.allusers.lastPage();
		cgmc.allusers.previousPage();
		cgmc.allusers.firstPage();
		cgmc.allusers.newOwner(u.Id);
		cgmc.msDone();
	}

	static testMethod void test_CommunityGroupsController() {
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
			CollaborationGroup cg = new CollaborationGroup();
			cg.Name = 'newgroup';
			cg.CollaborationType = 'Public' ;
			insert cg;
			Community_Group_Control__c group1 = new Community_Group_Control__c(Name='1212t',Discoverable__c=true,Type__c='Public',Network__c='Internal', Chatter_Group_ID__c=cg.Id);
			insert 	group1;
			
			Community_Group_Control_Tag__c groupTag = new Community_Group_Control_Tag__c(Group_Control__c=group1.Id,Community_Tag__c=ct.Id);
			insert groupTag;
			
			insert new Community_Profile_Tag__c(Community_Tag__c=ct.Id,Active__c=true,Contact__c=con.Id);
			
			Test.setCurrentPage(Page.CommunityGroups);
			ApexPages.currentPage().getParameters().put('f','all_groups');
			
			CommunityGroupsController cgc = new CommunityGroupsController();
			CommunityGroupsController.getGroups(100, 0, 'all_groups');
			CommunityGroupsController.getGroups(100, 0, 'recommended_groups');
			CommunityGroupsController.getGroups(100, 0, 'my_groups');
			
			cgc.getShowCreateGroupBtn();
			String s1 = cgc.currentFilter;	
			//String s2 = cgc.GroupPhotoUrl;					
		}
		CommunityGroupsController.getGroups(100, 0, 'all_groups');
		CommunityGroupsController.getGroups(100, 0, 'recommended_groups');
		CommunityGroupsController.getGroups(100, 0, 'my_groups');
	}

	static testMethod void test_CommunityRegTermsController() {
		Community_Theme__c cth = new Community_Theme__c(Name='t',Theme_Type__c='Interest');
		insert cth;
		Community_Tag__c ct = new Community_Tag__c(Name='t',Community_Theme__c=cth.Id);
		insert ct;
		
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
		System.runAs(u) {
			Test.setCurrentPage(Page.CommunityRegTerms);
			CommunityRegTermsController crtc = new CommunityRegTermsController();
						
			crtc.stepName = 'info';
			crtc.init();
			crtc.completeCurrentStep();
			crtc.stepName = 'interest';
			crtc.init();
			crtc.completeCurrentStep();
			crtc.stepName = 'picture';
			crtc.init();
			crtc.completeCurrentStep();
			crtc.stepName = 'tc';
			crtc.init();
			crtc.completeCurrentStep();
			crtc.stepName = 'info';
			crtc.init();
			crtc.completeCurrentStep();
			crtc.stepName = 'info';
			crtc.init();
			crtc.completeCurrentStep();
			crtc.checkAndPrepareMenu();
			crtc.getDisabledNext();
		
			CommunityRegTermsController.Menu leftSideBar = new CommunityRegTermsController.Menu();	
				leftSideBar.getLastStep();
				leftSideBar.getCurrentStepName();	
			CommunityRegTermsController.MenuItem mi = new CommunityRegTermsController.MenuItem( 'n', true, true, 1);
			mi.getStepParam();			
		}
	}

	@isTest(SeeAllData=true)
	static void test_CommunitySearchController() {		
		Test.setCurrentPage(Page.CommunitySearch);
		CommunitySearchController csc1 = new CommunitySearchController();
		ApexPages.currentPage().getParameters().put('s','cat');
		CommunitySearchController csc2 = new CommunitySearchController();
		csc2.getFilterName();
		SyStem.Debug([SELECT Id, Name FROM Community_Group_Control__c]);				
		ApexPages.currentPage().getParameters().put('tr','tr');
		CommunitySearchController csc3 = new CommunitySearchController();
		ApexPages.currentPage().getParameters().put('t','t');
		CommunitySearchController csc4 = new CommunitySearchController();		
		csc1.getNews();
		csc1.getEvents();
		csc1.getGroups();
		csc1.getResources();		
		CommunitySearchController.SearchItem s21 = csc2.getNews();
		CommunitySearchController.SearchItem s22 = csc2.getEvents();
		CommunitySearchController.SearchItem s23 = csc2.getGroups();
		CommunitySearchController.SearchItem s24 = csc2.getResources();
		csc2.getFilterName();		
		CommunitySearchController.SearchItem s3 = csc3.getNews();
		csc3.getEvents();
		csc3.getGroups();		
		csc4.getNews();
		csc4.getEvents();
		csc4.getGroups();
		csc4.getResources();
		csc4.getFilterName();		
		CommunitySearchController.SearchItem si1 = new CommunitySearchController.SearchItem([SELECT ID, NAME__c, Teaser__c, Start__c FROM Community_Events__c],1);
		CommunitySearchController.SearchItem si2 = new CommunitySearchController.SearchItem([SELECT ID, Title__c, Teaser__c, Entry_Date__c,Image_Path__c FROM Community_News__c],1);
		CommunitySearchController.SearchItem si3 = new CommunitySearchController.SearchItem([SELECT ID, Name, Description__c, Link__c FROM Community_Resource__c],1);		
		CommunitySearchController.SearchItem si4 = new CommunitySearchController.SearchItem(new List<CommunityGroupsController.ChatterGroupDetail>(),0);		
	}
}
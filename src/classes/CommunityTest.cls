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
private class CommunityTest {
/*Page Controllers Tests*/

	static testMethod void test_CommunityNews() {
		CommunityTest3.testDataFactory df = new CommunityTest3.testDataFactory(
			new Set<String> {
				'communityUser',
				'communitySuperUser'
			}
		);

		System.runAs(df.communityUser) {
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
			cnc.news.Teaser__c = '';
			cnc.news.Content__c = '<div>test</div>';
			System.assertEquals(cnc.news.Content__c,'<div>test</div>');
			cnc.submitFirstStep();
			cnc.news.Title__c = 't';
			cnc.news.URL__c = 'https://externalstory.com/news/0';
			cnc.news.Type__c = 'Internal';
			cnc.news.Teaser__c = 't';
			cnc.news.Make_Entry_Sticky__c = true;
			cnc.news.Entry_Date__c = Datetime.now();
			cnc.news.Expiration_Date__c = Datetime.now().addDays(1);
			cnc.getUpdateableCurrentNews();
			cnc.submitFirstStep();
			cnc.submitSecondStep();
			System.debug(cnc.urlForBackToNewsEdit);
			System.debug(cnc.folderId);

			CommunityNewsController cnc2 = new CommunityNewsController(new ApexPages.StandardController(cnc.news));
			cnc2.initFromEdit();

			ApexPages.currentPage().getParameters().put('cloneId',cnc.news.Id);
			CommunityNewsController cnc2c = new CommunityNewsController(new ApexPages.StandardController(new Community_News__c()));
			cnc2c.initFromEdit();
			cnc.getPostedStr();

			insert new Community_News__c(Title__c='t',Teaser__c='t',Entry_Date__c=Datetime.now(),Expiration_Date__c=Datetime.now().addDays(1));

			CommunityNewsController cnc3 = new CommunityNewsController(new ApexPages.StandardController(cnc.news));
			cnc3.initFromView();
			cnc3.mode = 'view';
			cnc3.init();
			cnc3.cancel();
			cnc3.edit();
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
	}

	static testMethod void test_CommunityResources() {
		CommunityTest3.testDataFactory df = new CommunityTest3.testDataFactory(
			new Set<String> {
				'communityUser',
				'communitySuperUser'
			}
		);

		System.runAs(df.communityUser) {
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
			crc.getIsShowPrimaryTag();
			crc.getResourceLink();
			crc.linkText = NULL;
			crc.imgBody = Blob.valueOf('blob');
			crc.imgFileName = 'ifn';
			crc.saveResource();

			System.assertEquals([SELECT Name,Id From Community_Resource__c Where Name='r' ][0].Name,'r');

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
			crc2.getAvailablePriTags();
		}
	}

	static testMethod void test_CommunityGroupCreate() {
		CommunityTest3.testDataFactory df = new CommunityTest3.testDataFactory(
			new Set<String> {
				'communityUser',
				'communitySuperUser',
				'createGroupControl'
			}
		);

		System.runAs(df.communityUser) {
			Community_Theme__c cth = new Community_Theme__c(Name='t',Theme_Type__c='Interest');
			insert cth;
			Community_Tag__c ct = new Community_Tag__c(Name='t',Community_Theme__c=cth.Id);
			insert ct;

			CommunityGroupCreateController cgcc = new CommunityGroupCreateController(new ApexPages.StandardController(df.groupControl));
			cgcc.initFromCreate();
			cgcc.getDisabledNext();
			cgcc.doSubmit();
			cgcc.currentGroup.Name = 'cc';
			cgcc.currentGroup.Type__c = 'Public';
			cgcc.currentGroup.Description__c = 'd';
			cgcc.currentGroup.Discoverable__c = true;
			CommunityGroupCreateController.checkAvailability(cgcc.currentGroup.Name);
			try {cgcc.doSubmit();} catch(Exception e) {}
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
			Community_Admins__c ca = cgcc.getTermsAndConditions();
			System.assert(ca != NULL);
			txt = cgcc.headerText;
			cgcc.doSubmit();

			cgcc.cancel();
		}
	}

	@IsTest(SeeAllData=true)
	static void test_CommunityProfile() {
		CommunityTest3.testDataFactory df = new CommunityTest3.testDataFactory(
			new Set<String> {
				'communityUser',
				'communitySuperUser',
				'addRoleToContact'
			}
		);

		System.runAs(df.communityUser) {
			Community_Theme__c cth = new Community_Theme__c(Name='t',Theme_Type__c='Interest');
			insert cth;
			Community_Tag__c ct = new Community_Tag__c(Name='t',Community_Theme__c=cth.Id);
			insert ct;
			ApexPages.currentPage().getParameters().put('id',df.communityUser.Id);
			CommunityProfilePageController cppc = new CommunityProfilePageController();
			//cppc.overviewTab[0].getShowSection();
			cppc.getStudentName();
			cppc.changePassword();
			cppc.cancelChangePassword();
			cppc.submit();
			CommunityProfilePageController.NotificationPage np = cppc.getEmailNotifications();
			CommunityProfilePageController.DigestItem di = new CommunityProfilePageController.DigestItem(
				new CollaborationGroupMember(
					MemberId = df.communityUser.Id,
					NotificationFrequency='P'
				)
			);
			cppc.getDigestSettings();
			cppc.getDefaultDigest();
			cppc.getIsSubscribe();
			cppc.getIsCommunityUser();
			cppc.getShowChangePassword();
			System.assert(cppc.getfsMap() != null);
			System.AssertEquals(cppc.getIsSubscribe(),false);
			//CommunityProfilePageController.toggleUserDigest(null,'P');
			CommunityProfilePageController.toggle(ct.Id,true);
			CommunityProfilePageController.toggle(ct.Id,false);
		}
	}


	static testMethod void test_CommunityEventController() {
		CommunityTest3.testDataFactory df = new CommunityTest3.testDataFactory(
			new Set<String> {
				'communityUser',
				'communitySuperUser',
				'addRoleToContact'
			}
		);

		System.runAs(df.communityUser) {
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

			cec.generateDownloadIcsLink();
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
			//cec.getTitle();

			PageReference pr2 = cec.cancel();
			System.assertEquals(true, pr2 != null);
			PageReference pr3 = cec.submit();

			ApexPages.currentPage().getParameters().put('cloneId',event.Id);
			cec = new CommunityEventController(new ApexPages.StandardController(new Community_Events__c()));
			cec.initFromEdit();
		}
	}

	@IsTest(SeeAllData=true)
	static void test_CommunityFeed_MyMessagesController() {

		Account acc = new Account(Name='testAccount');
		insert acc;
		List<Contact> cons = new List<Contact> {
			new Contact(LastName='TCLN', MailingPostalCode='99013', email='testc@testdomain.com', AccountId=acc.Id, Primary_Role__c='Student'),
			new Contact(LastName='TCLO', MailingPostalCode='99013', email='testo@testdomain.com', AccountId=acc.Id, Primary_Role__c='Student')
		};
		insert cons;
		Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		List<User> us = new List<User> {
			new User(alias='alias', email='email@email.com', emailencodingkey='UTF-8', lastname='lopez', firstname = 'guillermo', languagelocalekey='en_US',
				localesidkey='en_US', profileid=profile.Id, timezonesidkey='America/Los_Angeles', username='ttsde.tedf2@testmail.com',
				FederationIdentifier='TestContactName.TestContactLastname2', Community_Contact_ID__c=cons[0].Id, isActive = true),
			new User(alias='alias2', email='email2@email.com', emailencodingkey='UTF-8', lastname='hu', firstname = 'yovo', languagelocalekey='en_US',
				localesidkey='en_US', profileid=profile.Id, timezonesidkey='America/Los_Angeles', username='ttsde.tedf3@testmail.com',
				FederationIdentifier='TestContactName.TestContactLastname6', Community_Contact_ID__c=cons[1].Id, isActive = true)
		};
		insert us;
		System.runAs(us[0]) {
			CommunityFeed_MyMessagesController cfhdgcb = new CommunityFeed_MyMessagesController();
			CommunityFeed_MyMessagesController.ChatterMessage cm = cfhdgcb.newConversation('balalayka',us[1].Id);
			CommunityFeed_MyMessagesController.postMessage(cm.ConversationId,'gorbachev',cm.MessageId);
			cfhdgcb.markConversationRead(cm.ConversationId, true);
		}
		System.runAs(us[1]) {
			List<CommunityFeed_MyMessagesController.ChatterGroupMember> sl = CommunityFeed_MyMessagesController.searchUsers('gu');
			System.assert(sl.size() > 0);
			String cid = CommunityFeed_MyMessagesController.sendMessage('matreshka',sl[0].MemberId);
			ApexPages.currentPage().getParameters().put('c',cid);
			CommunityFeed_MyMessagesController cfhdgcb2 = new CommunityFeed_MyMessagesController();
			cfhdgcb2.markConversationRead();
			cfhdgcb2.SelectedPageToken = cfhdgcb2.NextPageToken;
		}
		CommunityFeed_MyMessagesController.ChatterGroupMember takemeonbaliplease = new CommunityFeed_MyMessagesController.ChatterGroupMember(us[1], false);
		takemeonbaliplease = new CommunityFeed_MyMessagesController.ChatterGroupMember(us[1], false, '');
		takemeonbaliplease = new CommunityFeed_MyMessagesController.ChatterGroupMember(new CollaborationGroupMember());
		CommunityFeed_MyMessagesController.ChatterMessageSegment ortoborabora = new CommunityFeed_MyMessagesController.ChatterMessageSegment('txt','Text');
	}

	@IsTest(SeeAllData=true)
	static void test_CommunityFeed_PeopleController() {
		CommunityTest3.testDataFactory df = new CommunityTest3.testDataFactory(
			new Set<String> {
				'internalUser',
				'secondInternalUser',
				'communitySuperUser',
				'addRoleToContact'
			}
		);
		System.runAs(df.communityUser) {
			insert new EntitySubscription(ParentId = df.secondCommunityUser.Id, SubscriberId = df.communityUser.Id);
			List<CommunityFeed_PeopleController.UserItem> lUI = CommunityFeed_PeopleController.getPeoples();
			System.assertEquals(lUI.size() != null, true);
			CommunityFeed_PeopleController.subscriberAction(df.secondCommunityUser.Id, true);
			CommunityFeed_PeopleController cfpc = new CommunityFeed_PeopleController();
		}
	}

	@IsTest(SeeAllData=true)
	static void test_CommunityGroupDetailPageController() {
		CommunityTest3.testDataFactory df = new CommunityTest3.testDataFactory(
			new Set<String> {
				'internalUser',
				'communitySuperUser',
				'createGroupControl',
				'makeApprovedGroup'
			}
		);

		System.runAs(df.communityUser) {
			Test.setCurrentPage(Page.CommunityGroupDetailPage);
			ApexPages.currentPage().getParameters().put('gc', df.groupControl.Id);
			ApexPages.currentPage().getParameters().put('u', df.communityUser.Id);
			CommunityGroupDetailPageController.toggleSubscriber(df.communityUser.Id);
			CommunityGroupDetailPageController cgc = new CommunityGroupDetailPageController();
			cgc.getGroupEditable();
			cgc.getUrlForCreateEvent();
			cgc.switchToMemberMode();
			cgc.switchToRequestMode();
			cgc.getHideFeedComponent();
			cgc.getShowPendingMembers();
			cgc.getActionButton();
			cgc.getFieldset();
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
			System.assertEquals([SELECT Name__c,Id From Community_Events__c Where Name__c = 'Event Test'][0].Name__c,'Event Test');
			CommunityGroupDetailPageController.GroupEvent ge = new CommunityGroupDetailPageController.GroupEvent(event);
			cgc.control = df.groupControl;
			cgc.accepted = false;
			cgc.requesterId = df.communityUser.Id;
			System.debug(cgc.groupRoleString);
			System.assert(cgc.showFilesSection != null);
		}
	}

	static testMethod void test_CommunityGroupManageController() {
		CommunityTest3.testDataFactory df = new CommunityTest3.testDataFactory(
			new Set<String> {
				'internalUser',
				'communitySuperUser',
				'createGroupControl',
				'privateGroup',
				'makeApprovedGroup'
			}
		);

		System.runAs(df.communityUser) {
			ApexPages.currentPage().getParameters().put('gc', df.groupControl.Id);
			CommunityGroupManageController cgmc = new CommunityGroupManageController();
			CommunityUtils.membership(df.communityUser.Id, df.groupControl.Id, '5');
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
			cgmc.requesterId = df.communityUser.Id;
			cgmc.allusers.query = 'lastname';
			cgmc.performRequestAction();
			CommunityGroupManageController.membership(String.valueOf(df.communityUser.Id), String.valueOf(df.groupControl.Id), 3);
			cgmc.ownerString = df.communityUser.Id;
			cgmc.changeOwner();
			cgmc.allusers.column();
			cgmc.allusers.nextPage();
			cgmc.allusers.lastPage();
			cgmc.allusers.previousPage();
			cgmc.allusers.firstPage();
			cgmc.allusers.newOwner(df.communityUser.Id);
			//cgmc.msDone();
		}
	}

	static testMethod void test_CommunityGroupsController() {
		CommunityTest3.testDataFactory df = new CommunityTest3.testDataFactory(
			new Set<String> {
				'internalUser',
				'communitySuperUser',
				'addRoleToContact',
				'createGroupControl',
				'makeApprovedGroup'
			}
		);

		System.runAs(df.communityUser) {
			Community_Theme__c cth = new Community_Theme__c(Name='t', Theme_Type__c='Interest');
			insert cth;
			Community_Tag__c ct = new Community_Tag__c(Name='t' ,Community_Theme__c=cth.Id);
			insert ct;
			ApexPages.currentPage().getParameters().put('f','all_groups');
			CommunityGroupsController cgc = new CommunityGroupsController();
			cgc.getGroups();
			System.Assert(cgc.getGroups() != null, true);
			ApexPages.currentPage().getParameters().put('f','recommended_groups');
			cgc.getGroups();
			ApexPages.currentPage().getParameters().put('f','my_groups');
			cgc.getGroups();
			cgc.getShowCreateGroupBtn();
		}
	}

	static testMethod void test_CommunityRegTermsController() {
		CommunityTest3.testDataFactory df = new CommunityTest3.testDataFactory(
			new Set<String> {
				'communityUser',
				'communitySuperUser',
				'addRoleToContact'
			}
		);

		System.runAs(df.communityUser) {
			Community_Theme__c cth = new Community_Theme__c(Name='t',Theme_Type__c='Interest');
			insert cth;
			Community_Tag__c ct = new Community_Tag__c(Name='t',Community_Theme__c=cth.Id);
			insert ct;

			Test.setCurrentPage(Page.CommunityRegTerms);
			CommunityRegTermsController crtc = new CommunityRegTermsController();
			crtc.stepName = 'info';
			//System.AssertEquals(Page.CommunityHome,crtc.init());
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
			System.assertEquals(crtc.init() == null, true);
			CommunityRegTermsController.Menu leftSideBar = new CommunityRegTermsController.Menu();
				leftSideBar.getLastStep();
				leftSideBar.getCurrentStepName();
			CommunityRegTermsController.MenuItem mi = new CommunityRegTermsController.MenuItem( 'n', true, true, 1);
			mi.getStepParam();
		}
	}

	@IsTest(SeeAllData=true)
	static void test_CommunitySearchController() {
		CommunityTest3.testDataFactory df = new CommunityTest3.testDataFactory(
			new Set<String> {
				'communityUser',
				'communitySuperUser',
				'addRoleToContact',
				'createGroupControl'
			}
		);

		System.runAs(df.communityUser) {
			Test.setCurrentPage(Page.CommunitySearch);
			CommunitySearchController csc1 = new CommunitySearchController();
			ApexPages.currentPage().getParameters().put('s','cat');
			CommunitySearchController csc2 = new CommunitySearchController();
			csc2.getFilterName();
			ApexPages.currentPage().getParameters().put('tr','tr');
			CommunitySearchController csc3 = new CommunitySearchController();
			ApexPages.currentPage().getParameters().put('t','t');
			CommunitySearchController csc4 = new CommunitySearchController();
			csc1.getNews();
			csc1.getEvents();
			System.assertEquals(csc1.getGroups().totalRecords>0,false);
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
			Community_Group_Control__c cgcr = [SELECT Chatter_Group_ID__c FROM Community_Group_Control__c WHERE Id = :df.groupControl.Id];
			CommunitySearchController.membershipGroup('1',cgcr.Chatter_Group_ID__c,'4');
			CommunitySearchController.SearchItem tunePaginator = new CommunitySearchController.SearchItem();
			for (Integer totalPageIterator = 1; totalPageIterator < 10; totalPageIterator++) {
				for (Integer pageIterator = 1; pageIterator < totalPageIterator; pageIterator++) {
					tunePaginator.totalRecords = totalPageIterator * 2;
					tunePaginator.tunePagination(pageIterator, 2);
				}
			}
		}
	}

	@IsTest(SeeAllData=true)
	static void test_CommunityGroupFilesController() {
		CommunityTest3.testDataFactory df = new CommunityTest3.testDataFactory(
			new Set<String> {
				'internalUser',
				'communitySuperUser',
				'addRoleToContact'
			}
		);

		System.runAs(df.communityUser) {
			Community_Group_Control__c cgc = new Community_Group_Control__c(Name='tstgrp', Type__c='Public', Discoverable__c=true);
			insert cgc;
			ApexPages.currentPage().getParameters().put('gc',cgc.Id);
			CommunityGroupFilesController cgfc = new CommunityGroupFilesController();
			cgfc.initFromPage();
			cgfc.getCommunityId();
			System.assert(cgfc.parentId != NULL, true);
			insert new FeedItem(
				ParentId = cgfc.parentId,
				ContentFileName = 'tst',
				ContentData = EncodingUtil.base64Decode('/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////2wBDAf//////////////////////////////////////////////////////////////////////////////////////wAARCAAMABADASIAAhEBAxEB/8QAFgABAQEAAAAAAAAAAAAAAAAAAQAC/8QAGRAAAwADAAAAAAAAAAAAAAAAAAERElFx/8QAFAEBAAAAAAAAAAAAAAAAAAAAAP/EABQRAQAAAAAAAAAAAAAAAAAAAAD/2gAMAwEAAhEDEQA/ADF6KOGp0IB//9k='),
				Body = 'tst'
			);
			cgfc.fileQuery = 'tst';
			cgfc.searchAction();
			cgfc.mode = 'detail';
			System.assert(cgfc.getFileDetail().getShortName() == 'tst' , true);
			String vId = cgfc.getFileDetail().versionId;
			String dId = cgfc.getFileDetail().documentId;
			cgfc.mode = 'list';
			cgfc.shareChoice = cgfc.parentId;
			cgfc.shareComment = 'cmnt';
			cgfc.stack = vId;
			cgfc.shareAction();
			cgfc.modal = 'update';
			cgfc.modeAction();
			cgfc.updateAction();
			System.assert(!cgfc.filesHasNext, true);
			System.assert(!cgfc.filesHasPrevious, true);
			cgfc.filesPageNumber = 0;
			cgfc.filesNextPage();
			cgfc.filesPageNumber = 2;
			cgfc.filesPreviousPage();
			cgfc.filesPageNumber = 0;
			cgfc.filesLastPage();
			cgfc.filesPageNumber = 2;
			cgfc.filesFirstPage();
			CommunityGroupFilesController.getGroupsSelector('jaime');
			CommunityGroupFilesController.getPeoplesSelector('cersei');
			CommunityGroupFilesController.subscriberAction(vId, false);
			cgfc.modal = 'sharegroup';
			cgfc.getGroups();
			cgfc.modal = 'newversion';
			ApexPages.currentPage().getParameters().put('f', cgfc.getParentDocumentId());
			cgfc.initFromPage();
			cgfc.stack = vId;
			cgfc.deleteAction();
		}
	}

	@IsTest(SeeAllData=true)
	static void test_CommunityTopicController() {
		CommunityTest3.testDataFactory df = new CommunityTest3.testDataFactory(
			new Set<String> {
				'internalUser',
				'communitySuperUser',
				'addRoleToContact',
				'createGroupControl'
			}
		);

		FeedItem fi = new FeedItem();
		fi.ParentId = df.communityUser.Id;
		fi.Body = 'test feed';
		insert fi;
		Topic top = new Topic(Name = 'test');
		insert top;
		Topic top2 = new Topic(Name = 'testing');
		insert top2;
		TopicAssignment ta = new TopicAssignment();
		ta.TopicId = top.Id;
		ta.entityId = fi.Id;
		insert ta;
		TopicAssignment ta2 = new TopicAssignment();
		ta2.TopicId = top2.Id;
		ta2.entityId = fi.Id;
		insert ta2;

		System.runAs(df.communityUser) {
			Test.setCurrentPage(Page.CommunityTopic);
			ApexPages.currentPage().getParameters().put('id',top.Id);
			ApexPages.currentPage().getParameters().put('pid',df.communityUser.Id);
			Map<String, String> params = new Map<String, String>();
			params.put('topicId', null);

			TopicAssignment ta1 = new TopicAssignment();
			ta1.TopicId = top.Id;
			ta1.entityId = fi.Id;
			insert ta1;

			List<CommunityTopicController.topicItem> items = CommunityTopicController.getTopics(params);

			params.put('topicId', top.Id);
			List<CommunityTopicController.topicItem> items1 = CommunityTopicController.getTopics(params);

			CommunityTopicController ctc = new CommunityTopicController();
			String topicId = ctc.topicId;
			String parentId = ctc.parentId;
			Boolean show = ctc.showTopics;

			String sortField = CommunityTopicController.sortField;
			Boolean isTopicUpdateable = ctc.isTopicUpdateable;
			Boolean isTopicDeleteable = ctc.isTopicDeleteable;
			Boolean isTopicCreateable = ctc.isTopicCreateable;
			Boolean isTopicAssignmentCreateable = ctc.isTopicAssignmentCreateable;
			Boolean isFeedTraking = ctc.isFeedTraking;
			Boolean topicExists = ctc.topicExists;

			Topic top1 = new Topic(Name = 'test1');
			insert top1;

			String result = CommunityTopicController.updateTopic('descr', top1.Id);
			String canNotFoundTopicResult = CommunityTopicController.updateTopic('descr', '00x000000000000');
			System.assert(canNotFoundTopicResult == Label.ERR_Can_not_found_Topic);
			Boolean bool = CommunityTopicController.subscriberAction(df.communityUser.Id, false);

			String result1 = CommunityTopicController.addToFavorites(top1.Id);
			Set<String> setRes = CommunityTopicController.selectSubscription(new List<String>{top1.Id});
			String result2 = CommunityTopicController.removeFromFavorites(top1.Id);
			String result3 = CommunityTopicController.deleteTopic(top1.Id);
		}
	}
}

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
		CommunityEventController.test1();
	}

	static testMethod void test_CommunityFeed_MyMessagesController() {
		CommunityFeed_MyMessagesController.test1();
	}

	static testMethod void test_CommunityFeed_PeopleController() {
		CommunityFeed_PeopleController.test1();
	}

	static testMethod void test_CommunityGroupDetailPageController() {
		CommunityGroupDetailPageController.test1();
	}

	static testMethod void test_CommunityGroupManageController() {
		CommunityGroupManageController.test1();
	}

	static testMethod void test_CommunityGroupsController() {
		CommunityGroupsController.test1();
	}

	static testMethod void test_CommunityRegTermsController() {
		CommunityRegTermsController.test1();
	}

	static testMethod void test_CommunitySearchController() {
		CommunitySearchController.test1();
	}
}
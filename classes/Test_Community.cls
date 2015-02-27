@isTest(SeeAllData=true)
private class Test_Community {
/*
	static testMethod void Test_CommunityEventController() {
		Profile profile = [SELECT Id, Name FROM profile WHERE name='System Administrator'];
		User user = new User(
			alias = 'tt01', email='testtest01@test.com', emailencodingkey='UTF-8',
			lastname='testtest01', languagelocalekey='en_US', localesidkey='en_US',
			profileid = profile.Id, timezonesidkey='America/Los_Angeles', username='testtest01111@test.com'
		);
		insert user;

		List<Community_Events__c> communityEventsList = new List<Community_Events__c>();
		Community_Events__c event1 = new Community_Events__c(Name__c='test_event_1', Description__c = 'test description', Teaser__c = '', Start__c = system.TODAY().addDays(1), End__c = system.today().addDays(2));
		communityEventsList.add(event1);
		insert communityEventsList;
		
		List <Community_Theme__c> themeList = new list<Community_Theme__c>();
		Community_Theme__c theme = new Community_Theme__c();
		theme.Enable_in_Wizard__c = true;
		theme.Name = 'TEST Theme';
		themeList.add(theme);
		insert themeList;
		
		List<Community_Tag__c> CommunityTagList = new list<Community_Tag__c>();
		Community_Tag__c tag = new Community_Tag__c();
		tag.Name = 'TEST TAG';
		tag.Display_in_Wizard__c = true;
		tag.Community_Theme__c = themeList[0].id;
		CommunityTagList.add(tag);
		insert CommunityTagList;
		
		List<Community_Event_Tag__c> CommunityEventTagList = new list <Community_Event_Tag__c>();
		Community_Event_Tag__c event_tag = new Community_Event_Tag__c();
		event_tag.Community_Tag__c = CommunityTagList[0].id;
		event_tag.Community_Event__c = communityEventsList[0].id;
		CommunityEventTagList.add(event_tag);
		insert CommunityEventTagList;
		
		List<Community_Group_Control__c> CommunityGroupControlList = new list <Community_Group_Control__c>();
		Community_Group_Control__c newtestgroup = new Community_Group_Control__c();
		newtestgroup.name = 'newtestgroup';
		newtestgroup.active__c = true;
		newtestgroup.automatic_Archive__c = true;
		newtestgroup.discoverable__c = true;
		newtestgroup.Type__c = 'Public';
		newtestgroup.Network__c = 'Internal';
		CommunityGroupControlList.add(newtestgroup);
		insert CommunityGroupControlList;
		CommunityGroupControlList[0].Chatter_Group_ID__c = 'TestGroupChatterId';
		update CommunityGroupControlList;


		System.RunAs(user) {

			test.startTest();
			ApexPages.StandardController standartController = new ApexPages.StandardController(communityEventsList[0]);

			PageReference pr = new PageReference(Page.CommunityEventDetail.getUrl() + '?cloneid='+communityEventsList[0].id + '&g=' + newtestgroup.Chatter_Group_ID__c+'&t='+CommunityTagList[0].id);
			Test.setCurrentPage(pr);

			CommunityEventController controller = new CommunityEventController();
			controller.initFromEdit();
			controller.initFromView();
			controller.initFromList();
			controller.cancel();
			controller.event = event1;
			controller.submit();
			controller.gotoCreate();
			controller.CurrentFilter = Label.LBL_New_Group_Events;
			controller.initFromList();
			controller.CurrentFilter = Label.LBL_My_Group_Events;
			controller.initFromList();
			controller.CurrentFilter = Label.LBL_My_Events;
			controller.initFromList();
			controller.nextPage();
			controller.lastPage();
			controller.previousPage();
			controller.firstPage();
			controller.pageNumber = 2;
			controller.setPageNumber();

			test.stopTest();
		}

	}
	*/
	static testMethod void Test_CommunityNewsController() {
		Profile profile = [SELECT Id, Name FROM profile WHERE name='System Administrator'];
		User user = new User(
			alias = 'tt01', email='testtest01@test.com', emailencodingkey='UTF-8',
			lastname='testtest01', languagelocalekey='en_US', localesidkey='en_US',
			profileid = profile.Id, timezonesidkey='America/Los_Angeles', username='testtest01111@test.com'
		);
		insert user;

		List<Community_Events__c> communityEventsList = new List<Community_Events__c>();
		Community_Events__c event1 = new Community_Events__c(Name__c='test_event_1', Description__c = 'test description', Teaser__c = '', Start__c = system.TODAY().addDays(1), End__c = system.today().addDays(2));
		communityEventsList.add(event1);
		insert communityEventsList;
		
		List <Community_Theme__c> themeList = new list<Community_Theme__c>();
		Community_Theme__c theme = new Community_Theme__c();
		theme.Enable_in_Wizard__c = true;
		theme.Name = 'TEST Theme';
		themeList.add(theme);
		insert themeList;
		
		List<Community_Tag__c> CommunityTagList = new list<Community_Tag__c>();
		Community_Tag__c tag = new Community_Tag__c();
		tag.Name = 'TEST TAG';
		tag.Display_in_Wizard__c = true;
		tag.Community_Theme__c = themeList[0].id;
		CommunityTagList.add(tag);
		insert CommunityTagList;
		
		List<Community_News__c> communityNewsList = new List<Community_News__c>();
			Community_News__c newsitem = new Community_News__c(Title__c='test_title', Entry_Date__c = Datetime.now(), Expiration_Date__c = Datetime.now().adddays(9), Allow_Comments__c = true, Make_Entry_Sticky__c = true, Type__c = 'External');
			communityNewsList.add(newsitem);
			insert communityNewsList;

			List<Community_News_Tag__c> communityNewsTagList = new List<Community_News_Tag__c>();
			Community_News_Tag__c NewsTag = new Community_News_Tag__c(Community_News__c=communityNewsList[0].id, Community_Tag__c = CommunityTagList[0].id);
			communityNewsTagList.add(NewsTag);
			insert communityNewsTagList;

			ApexPages.StandardController newstandartController =
			new ApexPages.StandardController(communityNewsList[0]);
			PageReference npr = new PageReference(Page.CommunityNewsEdit.getUrl() + '?&t='+CommunityTagList[0].id);
			Test.setCurrentPage(npr);
		
		System.RunAs(user) {
			test.startTest();
			
			CommunityNewsController newscontroller = new CommunityNewsController(newstandartController);
			newscontroller.initFromEdit();
			newscontroller.initFromView();
			newscontroller.initFromList();
			newscontroller.cancel();
			newscontroller.edit();
			newscontroller.imgBody = blob.valueof('testblbob');
			newscontroller.imgFileName = 'TestFileName';
			newscontroller.gotoCreate();
			newscontroller.submit();
			system.debug(newscontroller.allowComments);
			newscontroller.newsNextPage();
			newscontroller.newsLastPage();
			newscontroller.newsPreviousPage();
			newscontroller.newsFirstPage();

			test.stopTest();
		}
		
	}
	

	/*
	static testMethod void CommunityGroupsController() {
		Profile profile = [SELECT Id, Name FROM profile WHERE name='System Administrator'];
		User user = new User(
			alias = 'tt01', email='testtest01@test.com', emailencodingkey='UTF-8',
			lastname='testtest01', languagelocalekey='en_US', localesidkey='en_US',
			profileid = profile.Id, timezonesidkey='America/Los_Angeles', username='testtest01111@test.com'
		);
		insert user;
		
		List<Community_Group_Control__c> CommunityGroupControlList = new list <Community_Group_Control__c>();
		Community_Group_Control__c newtestgroup = new Community_Group_Control__c();
		newtestgroup.name = 'newtestgroup';
		newtestgroup.active__c = true;
		newtestgroup.automatic_Archive__c = true;
		newtestgroup.discoverable__c = true;
		newtestgroup.Type__c = 'Public';
		newtestgroup.Network__c = 'Internal';
		CommunityGroupControlList.add(newtestgroup);
		insert CommunityGroupControlList;
		CommunityGroupControlList[0].Chatter_Group_ID__c = 'TestGroupChatterId';
		update CommunityGroupControlList;
		
		List<Community_Group_Control__c> FollowGroupList = new list <Community_Group_Control__c>();
		Community_Group_Control__c followtestgroup = new Community_Group_Control__c();
		followtestgroup.name = 'followtestgroup';
		followtestgroup.active__c = true;
		followtestgroup.automatic_Archive__c = true;
		followtestgroup.discoverable__c = true;
		followtestgroup.Type__c = 'Public';
		followtestgroup.Network__c = 'Internal';
		FollowGroupList.add(followtestgroup);
		insert FollowGroupList;
		FollowGroupList[0].Chatter_Group_ID__c = 'TestFollChatterId';
		update FollowGroupList;
		
		List<entitySubscription> entitySubscriptionList = new list<entitySubscription>();
		entitySubscription subscript = new entitySubscription();
		subscript.SubscriberId = user.id;
		subscript.ParentId = CommunityGroupControlList[0].id;
		entitySubscriptionList.add(subscript);
		insert entitySubscriptionList;
		
		List<entitySubscription> entityFollowList = new list<entitySubscription>();
		entitySubscription Followsubscript = new entitySubscription();
		Followsubscript.SubscriberId = user.id;
		Followsubscript.ParentId = FollowGroupList[0].id;
		entityFollowList.add(Followsubscript);
		insert entityFollowList;
		
		CollaborationGroup CollGroup = new CollaborationGroup();
		CollGroup.Name = 'CollGroup';
		CollGroup.Description = 'TestDescription';
		CollGroup.InformationTitle = 'test';
		CollGroup.InformationBody = 'testtrst';
		CollGroup.CollaborationType = 'Public';
		CollGroup.NetworkId = CommunityGroupsBase.getCurrentCommunityId();
		insert CollGroup;
		
		
		
		
		
		
		
		CollaborationGroupMember CollGroupMember = new CollaborationGroupMember();
		CollGroupMember.NotificationFrequency = 'p';
		CollGroupMember.CollaborationGroupId = CollGroup.id;
		CollGroupMember.MemberId = user.id;		
		insert CollGroupMember;
		
		System.RunAs(user) {
			test.startTest();
			
			
			PageReference pr = new PageReference(Page.CommunityGroups.getUrl()+'?f=all_groups');
			Test.setCurrentPage(pr);
			CommunityGroupsController controller = new CommunityGroupsController();
			controller.initFromList();
			
			pr = new PageReference(Page.CommunityGroups.getUrl()+'?f=my_groups');
			Test.setCurrentPage(pr);
			controller = new CommunityGroupsController();
			controller.initFromList();
		
			pr = new PageReference(Page.CommunityGroups.getUrl()+'?f=recommended_groups');
			Test.setCurrentPage(pr);
			controller = new CommunityGroupsController();
			controller.initFromList();
		
			pr = new PageReference(Page.CommunityGroups.getUrl()+'?f=recommended_grou');
			Test.setCurrentPage(pr);
			controller = new CommunityGroupsController();
			controller.initFromList();

			controller.searchFromName();
			controller.goToCreateGroup();

			controller.currentFilter = 'TEST';
			controller.choiceFilter();

			controller.filterGroups();
			
			controller.currentFilter = 'All Groups';
			controller.filterGroups();
			
			controller.currentFilter = 'My Groups';
			controller.filterGroups();
			
			controller.currentFilter = 'Recommended Groups';
			controller.filterGroups();
			
			controller.followSobjectId = FollowGroupList[0].id;
			controller.follow();
			
			test.stopTest();
		}
		
	}


	static testMethod void CommunityGroupDetailPageController() {
		Profile profile = [SELECT Id, Name FROM profile WHERE name='System Administrator'];
		User user = new User(
			alias = 'tt01', email='testtest01@test.com', emailencodingkey='UTF-8',
			lastname='testtest01', languagelocalekey='en_US', localesidkey='en_US',
			profileid = profile.Id, timezonesidkey='America/Los_Angeles', username='testtest01111@test.com'
		);
		insert user;
		
		CollaborationGroup CollGroup = new CollaborationGroup();
		CollGroup.Name = 'CollGroup';
		CollGroup.Description = 'TestDescription';
		CollGroup.InformationTitle = 'test';
		CollGroup.InformationBody = 'testtrst';
		CollGroup.CollaborationType = 'Public';
		
		CollGroup.NetworkId = CommunityGroupsBase.getCurrentCommunityId();
		insert CollGroup;
		
		List<Community_Group_Control__c> CommunityGroupControlList = new list <Community_Group_Control__c>();
		Community_Group_Control__c newtestgroup = new Community_Group_Control__c();
		newtestgroup.name = 'newtestgroup';
		newtestgroup.active__c = true;
		newtestgroup.automatic_Archive__c = true;
		newtestgroup.discoverable__c = true;
		newtestgroup.Type__c = 'Public';
		newtestgroup.Network__c = 'Internal';
		CommunityGroupControlList.add(newtestgroup);
		insert CommunityGroupControlList;
		CommunityGroupControlList[0].Chatter_Group_ID__c = CollGroup.id;
		update CommunityGroupControlList;
		
		List<entitySubscription> entitySubscriptionList = new list<entitySubscription>();
		entitySubscription subscript = new entitySubscription();
		subscript.SubscriberId = user.id;
		subscript.ParentId = CommunityGroupControlList[0].id;
		entitySubscriptionList.add(subscript);
		insert entitySubscriptionList;
		


		CollaborationGroupMember CollGroupMember = new CollaborationGroupMember();
		CollGroupMember.NotificationFrequency = 'p';
		CollGroupMember.CollaborationGroupId = CollGroup.id;
		CollGroupMember.MemberId = user.id;		
		insert CollGroupMember;
		
		//communityGroupBase CGB = new communityGroupBase(CollGroup);
		//CGB.ChatterGroupDetail(CollGroup);
		//CommunityGroupsBase BaseController = new CommunityGroupsBase();
		//BaseController.ChatterGroupDetail CGD = new BaseController.ChatterGroupDetail(CollGroup);
		//insert CGD;
		
		
		
		//BaseController.ChatterGroupDetail CGD = new BaseController.ChatterGroupDetail(CollGroup);
		//insert CGD;
		
		
		System.RunAs(user) {
			test.startTest();
				
			PageReference pr = new PageReference(Page.CommunityGroupDetailPage.getUrl()+'?g='+CollGroup.id);
			Test.setCurrentPage(pr);
			CommunityGroupDetailPageController controller = new CommunityGroupDetailPageController();
			PageReference pr2 = new PageReference(Page.CommunityGroupDetailPage.getUrl()+'?gc='+CommunityGroupControlList[0].id);
			Test.setCurrentPage(pr2);
			CommunityGroupDetailPageController controller2 = new CommunityGroupDetailPageController();
			controller2.refresh();
			controller2.goToCreateEvent();
			
			test.stopTest();
		}
		
	}
	*/
	
	
	
}
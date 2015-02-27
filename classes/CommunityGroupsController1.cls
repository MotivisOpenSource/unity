public without sharing class CommunityGroupsController1 extends CommunityGroupsBase {

	public String currentFilter { 
		get {
			return ApexPages.currentPage().getParameters().get('f');
		}
		private set;
	}
	private final String CurrentCommunityId = getCurrentCommunityId();

	public CommunityGroupsController1() {

	}
	@RemoteAction
	public static Boolean subscriberAction(Id recordId, Boolean isSubscribe) {
		if (!isSubscribe) {
			List<EntitySubscription> followings = [
				Select SubscriberId, ParentId, IsDeleted, Id, CreatedDate, CreatedById
				From EntitySubscription
				WHERE SubscriberId =:Userinfo.getUserId()
				AND ParentId = :recordId
				LIMIT 1
			];
			if (!followings.isEmpty()) {
				//ConnectApi.Chatter.deleteSubscription(CommunityGroupsBase.getCurrentCommunityId(), followings[0].Id);
			}
		} else if (isSubscribe) {
			//ConnectApi.ChatterUsers.follow(CommunityGroupsBase.getCurrentCommunityId(), 'me', memberId);
		}
		return true;
	}
	@RemoteAction
	public static List<ChatterGroupDetail> getGroups(Integer limitSize, Integer startFrom, String currentTab) {
		String currentCommunityId = CommunityGroupsBase.getCurrentCommunityId();

		List<ChatterGroupDetail> result = new List<ChatterGroupDetail>();

		List<CollaborationGroupMember> collaborationGroupMemberList = [
			SELECT MemberId, Id, CollaborationRole,
				CollaborationGroupId,
				CollaborationGroup.Id, CollaborationGroup.Name, CollaborationGroup.Description,
				CollaborationGroup.InformationTitle, CollaborationGroup.InformationBody,
				CollaborationGroup.SmallPhotoUrl, CollaborationGroup.FullPhotoUrl, CollaborationGroup.MemberCount,
				CollaborationGroup.LastFeedModifiedDate,
				CollaborationGroup.OwnerId, CollaborationGroup.NetworkId, CollaborationGroup.IsArchived,
				CollaborationGroup.CollaborationType, CollaborationGroup.CanHaveGuests,
				CollaborationGroup.Owner.Name, CollaborationGroup.Owner.FirstName,
				CollaborationGroup.Owner.LastName, CollaborationGroup.Owner.SmallPhotoUrl
			FROM CollaborationGroupMember
			WHERE CollaborationGroup.NetworkId =: currentCommunityId
			AND MemberId =: UserInfo.getUserId()
			ORDER BY CollaborationGroup.Name
		];
		Map<Id, CollaborationGroupMember> CollaborationGroupMemberMap = new Map<Id, CollaborationGroupMember>();
		for (CollaborationGroupMember item : collaborationGroupMemberList) {
			CollaborationGroupMemberMap.put(item.CollaborationGroup.Id, item);
		}

		List<Community_Group_Control__c> communityGroupControllList = new List<Community_Group_Control__c>();
		if (currentTab == 'all_groups') { //all 
			communityGroupControllList = [
				SELECT Id, Chatter_Group_ID__c, Discoverable__c
				FROM Community_Group_Control__c
				WHERE Chatter_Group_ID__c != NULL
				AND Discoverable__c = true
				LIMIT 1000
			];
		} else if (currentTab == 'my_groups') {
			Set<Id> memberOfGroupsIds = new Set<Id>(CollaborationGroupMemberMap.keySet());
			communityGroupControllList = [
				SELECT Id, Chatter_Group_ID__c, Discoverable__c
				FROM Community_Group_Control__c
				WHERE Chatter_Group_ID__c IN: memberOfGroupsIds
				AND Discoverable__c = true
				LIMIT 1000
			];

			Set<Id> followIds = new Set<Id>();
			List<EntitySubscription> entitySubscriptionList = [
				SELECT SubscriberId, ParentId, NetworkId, Id
				FROM EntitySubscription
				WHERE SubscriberId =: UserInfo.getUserId()
				AND NetworkId =: currentCommunityId
				LIMIT 900
			];
			for (EntitySubscription follow : entitySubscriptionList) {
				followIds.add(follow.ParentId);
			}
			List<Community_Group_Control__c> groupControls = [
				SELECT Id, Name, Active__c, Auto_Follow__c, Automatic_Archive__c, Chatter_Group_ID__c, Description__c, Discoverable__c,
					Group_Control_SF_ID__c, Manager_Group_Required__c, Purpose__c, Type__c,
					Owner.Id, Owner.Name, CreatedDate, Image_Path__c
				FROM Community_Group_Control__c
				WHERE Id IN: followIds
				AND Discoverable__c = true
				LIMIT 1000
			];
			for (Community_Group_Control__c item : groupControls) {
				ChatterGroupDetail groupDetail = new ChatterGroupDetail(item);
				if (CollaborationGroupMemberMap.get(item.Id) == NULL) {
					groupDetail.CurrentMemberRole = 'NotAMember';
				}
				else {
					groupDetail.CurrentMemberRole = CollaborationGroupMemberMap.get(item.Id).CollaborationRole;
				}
				result.add(groupDetail);
			}
		} else if (currentTab == 'recommended_groups') {
			User currentUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()];
			if (currentUser.ContactId != NULL) {
				List<Community_Profile_Tag__c> profileTagList = [
					SELECT Id, Name, Community_Tag__r.Id
					FROM Community_Profile_Tag__c
					WHERE Contact__r.Id =: currentUser.ContactId
					LIMIT 1000
				];
				Set<Id> profileTagsIds = new Set<Id>();
				for (Community_Profile_Tag__c item : profileTagList) {
					profileTagsIds.add(item.Community_Tag__r.Id);
				}
				List<Community_Group_Control_Tag__c> groupControllTagList = [
					SELECT Id, Group_Control__r.Id
					FROM Community_Group_Control_Tag__c
					WHERE Community_Tag__r.Id IN: profileTagsIds
					LIMIT 1000
				];
				Set<Id> groupControllsIds = new Set<Id>();
				for (Community_Group_Control_Tag__c item : groupControllTagList) {
					groupControllsIds.add(item.Group_Control__r.Id);
				}
				communityGroupControllList = [
					SELECT Id, Chatter_Group_ID__c, Discoverable__c
					FROM Community_Group_Control__c
					WHERE Chatter_Group_ID__c != NULL
					AND Discoverable__c = true
					AND Id IN: groupControllsIds
					LIMIT 1000
				];
			}
		}

		Set<Id> availableGroupsIds = new Set<Id>();
		for (Community_Group_Control__c groupControl : communityGroupControllList) {
			availableGroupsIds.add(groupControl.Chatter_Group_ID__c);
		}

		List<CollaborationGroup> collaborationGroupList = new List<CollaborationGroup>();
		collaborationGroupList = [
			SELECT CollaborationGroup.Id, CollaborationGroup.Name, CollaborationGroup.Description,
				CollaborationGroup.InformationTitle, CollaborationGroup.InformationBody,
				CollaborationGroup.SmallPhotoUrl, CollaborationGroup.FullPhotoUrl,
				CollaborationGroup.MemberCount, CollaborationGroup.LastFeedModifiedDate,
				CollaborationGroup.OwnerId, CollaborationGroup.NetworkId, CollaborationGroup.IsArchived,
				CollaborationGroup.CollaborationType, CollaborationGroup.CanHaveGuests,
				CollaborationGroup.Owner.Name, CollaborationGroup.Owner.FirstName,
				CollaborationGroup.Owner.LastName, CollaborationGroup.Owner.SmallPhotoUrl, CollaborationGroup.Owner.Contact.Primary_role__c
			FROM CollaborationGroup
			WHERE Id IN: availableGroupsIds
			AND NetworkId =: currentCommunityId
			ORDER BY Name
			LIMIT :limitSize
			OFFSET :startFrom
		];
		for (CollaborationGroup item : collaborationGroupList) {
			ChatterGroupDetail groupDetail = new ChatterGroupDetail(item);
			if (CollaborationGroupMemberMap.get(item.Id) == NULL) {
				groupDetail.CurrentMemberRole = 'NotAMember';
			}
			else {
				groupDetail.CurrentMemberRole = CollaborationGroupMemberMap.get(item.Id).CollaborationRole;
			}
			result.add(groupDetail);
		}

		return result;
	}
}
/*public without sharing class CommunityGroupsController extends CommunityGroupsBase {

	// -- common variables --
	private final String CurrentCommunityId = getCurrentCommunityId();


	// CONSTRUCTOR
	public CommunityGroupsController() {

	}

	// INIT MAP SECTION
	public void initFromList() {
		initList();
	}

	// LIST SECTION

	// -- variables --
	public List<ChatterGroupDetail> Groups { get; set; }
	public List<SelectOption> filterByList { get; set; }
	public String currentFilter { get; set; }
	public String searchName { get; set; }
	public List<GroupControlItem> groupControlList { get; set; }
	public Boolean isGroupControlList { get; set; }
	public String followSobjectId { get; set; }

	private final String currentFilterGetMethod = ApexPages.currentPage().getParameters().get('tab');

	private final String allGroups = 'All Groups';
	private final String myGroups = 'My Groups';
	private final String recommendedGroups = 'Recommended Groups';

	// -- methods --

	// INIT METHOD
	private void initList() {

		this.filterByList = new List<SelectOption> {
			new SelectOption(allGroups, Label.BTN_All_Groups),
			new SelectOption(myGroups, Label.BTN_My_Groups),
			new SelectOption(recommendedGroups, Label.BTN_Recommended_Groups)
		};

		if (!String.isBlank(currentFilterGetMethod) && this.currentFilter == NULL) {
			if (currentFilterGetMethod == 'all_groups') {
				this.currentFilter = allGroups;
			}
			else if (currentFilterGetMethod == 'my_groups') {
				this.currentFilter = myGroups;
			}
			else if (currentFilterGetMethod == 'recommended_groups') {
				this.currentFilter = recommendedGroups;
			}
		}

		choiceFilter();

		return;
	}

	//PUBLIC METHODS

	// Choice Filter From List
	public void choiceFilter() {
		this.groupControlList = new List<GroupControlItem>();
		this.isGroupControlList = false;

		if (this.currentFilter == NULL || this.currentFilter == myGroups) {
			this.Groups = filterMyGroups();
			this.groupControlList = getGroupControls();
			this.currentFilter = myGroups;
		}
		else if (this.currentFilter != NULL && this.currentFilter == allGroups) {
			this.Groups = filterAllGroups();
		}
		else if (this.currentFilter != NULL && this.currentFilter == recommendedGroups) {
			this.Groups = filterRecommendedGroups();
		}
		else {
			this.Groups = filterMyGroups();
			this.groupControlList = getGroupControls();
			this.currentFilter = myGroups;
		}

		if (!this.groupControlList.isEmpty()) {
			this.isGroupControlList = true;
		}

		this.searchName = '';
	}

	// Search Chatter Group And Group_Control__c From Name
	public void searchFromName() {

		String newSearchName = this.searchName;
		choiceFilter();
		this.groups = searchGroupFromName(this.groups, newSearchName);
		this.searchName = newSearchName;
		this.isGroupControlList = false;
		if (!this.groupControlList.isEmpty()) {
			this.groupControlList = searchGroupControlFromName(groupControlList, searchName);
			this.isGroupControlList = true;
		}

		return;
	}

	public PageReference goToCreateGroup() {
//		PageReference pr = Page.CommunityGroupCreate;
		PageReference pr = new PageReference('/apex/CommunityGroupCreate?retURL=/apex/CommunityGroups');
		pr.setRedirect(true);
		return pr;
	}

	public PageReference filterGroups() {

		PageReference pr = Page.CommunityGroups;
		String filter = '';

		if (this.currentFilter == NULL || this.currentFilter == myGroups) {
			filter = '?f=my_groups';
		}
		else if (this.currentFilter != NULL && this.currentFilter == allGroups) {
			filter = '?f=all_groups';
		}
		else if (this.currentFilter != NULL && this.currentFilter == recommendedGroups) {
			filter = '?f=recommended_groups';
		}

		if (!String.isBlank(filter)) {
			pr = new PageReference('/apex/CommunityGroups' + filter);
		}

		pr.setRedirect(true);

		return pr;
	}

	public PageReference follow() {

		EntitySubscription subscription = new EntitySubscription();
		List<EntitySubscription> subscriptionForEventList = new List<EntitySubscription>();

		if (!String.isBlank(this.followSobjectId)) {
			subscriptionForEventList = [
				SELECT Id, ParentId
				FROM EntitySubscription
				WHERE ParentId = :followSobjectId
				AND SubscriberId = :UserInfo.getUserId()
				LIMIT 1
			];
		}

		if (!subscriptionForEventList.isEmpty()) {
			delete subscriptionForEventList[0];
			if (!groupControlList.isEmpty()) {
				for (GroupControlItem item : groupControlList) {
					if (item.groupId == subscriptionForEventList[0].ParentId) {
						item.follows = false;
					}
				}
			}
		}
		else {
			if (!String.isBlank(this.followSobjectId)) {
				subscription.ParentId = this.followSobjectId;
				subscription.SubscriberId = UserInfo.getUserId();
				if (Network.getNetworkId() != NULL) {
					subscription.put('NetworkId', Network.getNetworkId());
				}
				insert subscription;

				if (!groupControlList.isEmpty()) {
					for (GroupControlItem item : groupControlList) {
						if (item.groupId == this.followSobjectId) {
							item.follows = true;
						}
					}
				}
			}
		}

		return NULL;
	}

	//PRIVATE METHODS


	// Filter All Groups
	private static List<ChatterGroupDetail> filterAllGroups() {
		String currentCommunityId = CommunityGroupsBase.getCurrentCommunityId();
		List<ChatterGroupDetail> result = new List<ChatterGroupDetail>();
		List<CollaborationGroupMember> collaborationGroupMemberList = new List<CollaborationGroupMember>();
		List<Community_Group_Control__c> communityGroupControllList = new List<Community_Group_Control__c>();
		List<CollaborationGroup> collaborationGroupList = new List<CollaborationGroup>();
		Map<String, Community_Group_Control__c> groupControllMap = new Map<String, Community_Group_Control__c>();
		List<String> collaborationGroupIdList = new List<String>();
		Map<String, CollaborationGroupMember> CollaborationGroupMemberMap = new Map<String, CollaborationGroupMember>();

		communityGroupControllList = [
			SELECT Id, Chatter_Group_ID__c, Discoverable__c
			FROM Community_Group_Control__c
			WHERE Chatter_Group_ID__c != NULL
			AND Discoverable__c = true
		];

		if (!communityGroupControllList.isEmpty()) {
			for (Community_Group_Control__c item : communityGroupControllList) {
				collaborationGroupIdList.add(item.Chatter_Group_ID__c);
				groupControllMap.put(item.Chatter_Group_ID__c, item);
			}
		}

		collaborationGroupList = [
			SELECT CollaborationGroup.Id, CollaborationGroup.Name, CollaborationGroup.Description,
				CollaborationGroup.InformationTitle, CollaborationGroup.InformationBody,
				CollaborationGroup.SmallPhotoUrl, CollaborationGroup.FullPhotoUrl,
				CollaborationGroup.MemberCount, CollaborationGroup.LastFeedModifiedDate,
				CollaborationGroup.OwnerId, CollaborationGroup.NetworkId, CollaborationGroup.IsArchived,
				CollaborationGroup.CollaborationType, CollaborationGroup.CanHaveGuests,
				CollaborationGroup.Owner.Name, CollaborationGroup.Owner.FirstName,
				CollaborationGroup.Owner.LastName, CollaborationGroup.Owner.SmallPhotoUrl
			FROM CollaborationGroup
			//WHERE ((Id IN: collaborationGroupIdList AND CollaborationType = 'Private')
				//OR (CollaborationType = 'Public'))
			WHERE Id IN: collaborationGroupIdList
			AND NetworkId =: currentCommunityId
			ORDER BY Name
		];

		collaborationGroupMemberList = [
			SELECT MemberId, Id, CollaborationRole,
				CollaborationGroupId,
				CollaborationGroup.Id, CollaborationGroup.Name, CollaborationGroup.Description,
				CollaborationGroup.InformationTitle, CollaborationGroup.InformationBody,
				CollaborationGroup.SmallPhotoUrl, CollaborationGroup.FullPhotoUrl, CollaborationGroup.MemberCount,
				CollaborationGroup.LastFeedModifiedDate,
				CollaborationGroup.OwnerId, CollaborationGroup.NetworkId, CollaborationGroup.IsArchived,
				CollaborationGroup.CollaborationType, CollaborationGroup.CanHaveGuests,
				CollaborationGroup.Owner.Name, CollaborationGroup.Owner.FirstName,
				CollaborationGroup.Owner.LastName, CollaborationGroup.Owner.SmallPhotoUrl
			FROM CollaborationGroupMember
			WHERE CollaborationGroup.NetworkId =: currentCommunityId
			AND MemberId =: UserInfo.getUserId()
			ORDER BY CollaborationGroup.Name
		];

		if (!collaborationGroupMemberList.isEmpty()) {
			for (CollaborationGroupMember item : collaborationGroupMemberList) {
				if (item.CollaborationGroup != NULL) {
					CollaborationGroupMemberMap.put(item.CollaborationGroup.Id, item);
				}
			}
		}

		if (!collaborationGroupList.isEmpty()) {
			for (CollaborationGroup item : collaborationGroupList) {
				ChatterGroupDetail groupDetail = new ChatterGroupDetail(item);
				if (CollaborationGroupMemberMap.get(item.Id) == NULL) {
					groupDetail.CurrentMemberRole = 'NotAMember';
				}
				else {
					groupDetail.CurrentMemberRole = CollaborationGroupMemberMap.get(item.Id).CollaborationRole;
				}
				result.add(groupDetail);
			}
		}

		return result;
	}

	// Filter My Group
	private static List<ChatterGroupDetail> filterMyGroups() {

		String currentCommunityId = CommunityGroupsBase.getCurrentCommunityId();

		List<ChatterGroupDetail> result = new List<ChatterGroupDetail>();
		List<Community_Group_Control__c> communityGroupControllList = new List<Community_Group_Control__c>();
		List<CollaborationGroupMember> collaborationGroupMemberList = new List<CollaborationGroupMember>();
		Map<String, CollaborationGroupMember> CollaborationGroupMemberMap = new Map<String, CollaborationGroupMember>();

		collaborationGroupMemberList = [
			SELECT MemberId, Id, CollaborationRole,
				CollaborationGroupId,
				CollaborationGroup.Id, CollaborationGroup.Name, CollaborationGroup.Description,
				CollaborationGroup.InformationTitle, CollaborationGroup.InformationBody,
				CollaborationGroup.SmallPhotoUrl, CollaborationGroup.FullPhotoUrl, CollaborationGroup.MemberCount,
				CollaborationGroup.LastFeedModifiedDate,
				CollaborationGroup.OwnerId, CollaborationGroup.NetworkId, CollaborationGroup.IsArchived,
				CollaborationGroup.CollaborationType, CollaborationGroup.CanHaveGuests,
				CollaborationGroup.Owner.Name, CollaborationGroup.Owner.FirstName,
				CollaborationGroup.Owner.LastName, CollaborationGroup.Owner.SmallPhotoUrl
			FROM CollaborationGroupMember
			WHERE CollaborationGroup.NetworkId =: currentCommunityId
			AND MemberId =: UserInfo.getUserId()
			ORDER BY CollaborationGroup.Name
			LIMIT 1000
		];

		if (!collaborationGroupMemberList.isEmpty()) {
			for (CollaborationGroupMember item : collaborationGroupMemberList) {
				CollaborationGroupMemberMap.put(item.CollaborationGroup.Id, item);
			}
		}

		if (!CollaborationGroupMemberMap.isEmpty()) {
			communityGroupControllList = [
				SELECT Id, Chatter_Group_ID__c, Discoverable__c
				FROM Community_Group_Control__c
				WHERE Chatter_Group_ID__c IN: CollaborationGroupMemberMap.keySet()
				AND Discoverable__c = true
				LIMIT 1000
			];
		}

		if (!communityGroupControllList.isEmpty() && !CollaborationGroupMemberMap.isEmpty()) {
			for (Community_Group_Control__c item : communityGroupControllList) {
				if (CollaborationGroupMemberMap.get(item.Chatter_Group_ID__c) != NULL) {
					CollaborationGroupMember member = CollaborationGroupMemberMap.get(item.Chatter_Group_ID__c);
					ChatterGroupDetail groupDetail = new ChatterGroupDetail(member.CollaborationGroup);
					groupDetail.CurrentMemberRole = member.CollaborationRole;
					result.add(groupDetail);
				}
			}
		}

		return result;
	}

	// Filter My Recommended Group
	private static List<ChatterGroupDetail> filterRecommendedGroups() {

		String currentCommunityId = CommunityGroupsBase.getCurrentCommunityId();

		List<ChatterGroupDetail> result = new List<ChatterGroupDetail>();
		List<String> tagIdList = new List<String>();
		List<User> userList = new List<User>();
		List<Contact> contactList = new List<Contact>();
		List<Community_Profile_Tag__c> profileTagList = new List<Community_Profile_Tag__c>();
		List<CollaborationGroupMember> collaborationGroupMemberList = new List<CollaborationGroupMember>();
		List<Community_Group_Control_Tag__c> groupControllTagList = new List<Community_Group_Control_Tag__c>();
		List<String> groupControllIdList = new List<String>();
		List<String> collaborationGroupIdList = new List<String>();
		List<Community_Group_Control__c> communityGroupControllList = new List<Community_Group_Control__c>();
		List<CollaborationGroup> collaborationGroupList = new List<CollaborationGroup>();
		Map<String, CollaborationGroupMember> CollaborationGroupMemberMap = new Map<String, CollaborationGroupMember>();

		userList = [
			SELECT Id, ContactId
			FROM User
			Where Id =: UserInfo.getUserId()
			LIMIT 1
		];

		if (!userList.isEmpty()) {
			if (userList[0].ContactId != NULL) {
				contactList = [
					SELECT Id, Name
					FROM Contact
					WHERE Id =: userList[0].ContactId
					LIMIT 1
				];
			}
		}

		if (!contactList.isEmpty()) {
			profileTagList = [
				SELECT Id, Name, Community_Tag__r.Id
				FROM Community_Profile_Tag__c
				WHERE Contact__r.Id =: contactList[0].Id
				LIMIT 1000
			];
		}

		if (!profileTagList.isEmpty()) {
			for (Community_Profile_Tag__c item : profileTagList) {
				tagIdList.add(item.Community_Tag__r.Id);
			}
		}

		if (!tagIdList.isEmpty()) {
			groupControllTagList = [
				SELECT Id, Group_Control__r.Id
				FROM Community_Group_Control_Tag__c
				WHERE Community_Tag__r.Id IN: tagIdList
				LIMIT 1000
			];
		}

		if (!groupControllTagList.isEmpty()) {
			for (Community_Group_Control_Tag__c item : groupControllTagList) {
				groupControllIdList.add(item.Group_Control__r.Id);
			}
		}

		if (!groupControllIdList.isEmpty()) {
			communityGroupControllList = [
				SELECT Id, Chatter_Group_ID__c, Discoverable__c
				FROM Community_Group_Control__c
				WHERE Chatter_Group_ID__c != NULL
				AND Discoverable__c = true
				AND Id IN: groupControllIdList
				LIMIT 1000
			];
		}

		if (!communityGroupControllList.isEmpty()) {
			for (Community_Group_Control__c item : communityGroupControllList) {
				collaborationGroupIdList.add(item.Chatter_Group_ID__c);
			}
		}

		if (!collaborationGroupIdList.isEmpty()) {
			collaborationGroupMemberList = [
				SELECT MemberId, Id, CollaborationRole,
					CollaborationGroupId,
					CollaborationGroup.Id, CollaborationGroup.Name, CollaborationGroup.Description,
					CollaborationGroup.InformationTitle, CollaborationGroup.InformationBody,
					CollaborationGroup.SmallPhotoUrl, CollaborationGroup.FullPhotoUrl, CollaborationGroup.MemberCount,
					CollaborationGroup.LastFeedModifiedDate,
					CollaborationGroup.OwnerId, CollaborationGroup.NetworkId, CollaborationGroup.IsArchived,
					CollaborationGroup.CollaborationType, CollaborationGroup.CanHaveGuests,
					CollaborationGroup.Owner.Name, CollaborationGroup.Owner.FirstName,
					CollaborationGroup.Owner.LastName, CollaborationGroup.Owner.SmallPhotoUrl
				FROM CollaborationGroupMember
				WHERE CollaborationGroup.Id IN: collaborationGroupIdList
				AND MemberId =: UserInfo.getUserId()
				AND CollaborationGroup.NetworkId =: currentCommunityId
				ORDER BY CollaborationGroup.Name
				LIMIT 1000
			];

			collaborationGroupList = [
				SELECT CollaborationGroup.Id, CollaborationGroup.Name, CollaborationGroup.Description,
					CollaborationGroup.InformationTitle, CollaborationGroup.InformationBody,
					CollaborationGroup.SmallPhotoUrl, CollaborationGroup.FullPhotoUrl,
					CollaborationGroup.MemberCount, CollaborationGroup.LastFeedModifiedDate,
					CollaborationGroup.OwnerId, CollaborationGroup.NetworkId, CollaborationGroup.IsArchived,
					CollaborationGroup.CollaborationType, CollaborationGroup.CanHaveGuests,
					CollaborationGroup.Owner.Name, CollaborationGroup.Owner.FirstName,
					CollaborationGroup.Owner.LastName, CollaborationGroup.Owner.SmallPhotoUrl
				FROM CollaborationGroup
				WHERE Id IN: collaborationGroupIdList
				AND NetworkId =: currentCommunityId
				ORDER BY Name
				LIMIT 1000
			];
		}

		if (!collaborationGroupMemberList.isEmpty()) {
			for (CollaborationGroupMember item : collaborationGroupMemberList) {
				if (item.CollaborationGroup != NULL) {
					CollaborationGroupMemberMap.put(item.CollaborationGroup.Id, item);
				}
			}
		}

		if (!collaborationGroupList.isEmpty()) {
			for (CollaborationGroup item : collaborationGroupList) {
				ChatterGroupDetail groupDetail = new ChatterGroupDetail(item);
				if (CollaborationGroupMemberMap.get(item.Id) == NULL) {
					groupDetail.CurrentMemberRole = 'NotAMember';
				}
				else {
					groupDetail.CurrentMemberRole = CollaborationGroupMemberMap.get(item.Id).CollaborationRole;
				}
				result.add(groupDetail);
			}
		}

		return result;
	}

	// Get Group Controls Records to Filter "My Groups"
	private List<GroupControlItem> getGroupControls() {

		Set<Id> followGroupsIds = new Set<Id>();
		List<EntitySubscription> entitySubscriptionList = new List<EntitySubscription>();
		List<Community_Group_Control__c> groupControlList = new List<Community_Group_Control__c>();
		List<GroupControlItem> GroupControlItemList = new List<GroupControlItem>();
		List<GroupControlItem> result = new List<GroupControlItem>();

		entitySubscriptionList = [
			SELECT SubscriberId, ParentId, NetworkId, Id
			FROM EntitySubscription
			WHERE SubscriberId =: UserInfo.getUserId()
			AND NetworkId =: this.CurrentCommunityId
			LIMIT 900
		];

		if (!entitySubscriptionList.isEmpty()) {
			for (EntitySubscription member : entitySubscriptionList) {
				followGroupsIds.add(member.ParentId);
			}
		}

		if (!followGroupsIds.isEmpty()) {
			groupControlList = [
				SELECT Id, Name, Active__c, Auto_Follow__c, Automatic_Archive__c, Chatter_Group_ID__c, Description__c, Discoverable__c,
					Group_Control_SF_ID__c, Manager_Group_Required__c, Purpose__c, Type__c,
					Owner.Id, Owner.Name, CreatedDate, Image_Path__c
				FROM Community_Group_Control__c
				WHERE Id IN :followGroupsIds
				AND (Type__c = 'Public' OR (Type__c = 'Private' AND Discoverable__c = true))
			];
		}

		if (!groupControlList.isEmpty()) {
			for (Community_Group_Control__c item : groupControlList) {
				GroupControlItem record = new GroupControlItem();
				record.groupId = item.Id;
				record.name = item.Name;
				record.lastActivity = getLastActivityGroupControl(item.Id);
				record.lastActivity = record.lastActivity == NULL ? item.CreatedDate : record.lastActivity;
				record.membership = 'Following';
				record.photoUrl = item.Image_Path__c;
				if (String.isBlank(record.photoUrl)) {
					record.photoUrl = '/profilephoto/0F9/F';
				}
				record.groupObject = item;
				if (followGroupsIds.contains(record.groupId)) {
					record.follows = true;
				}
				else {
					record.follows = false;
				}
				result.add(record);
			}
		}

		return result;
	}


	// Search Group From Group Name
	private List<ChatterGroupDetail> searchGroupFromName(List<ChatterGroupDetail> groupList, String searchName) {

		List<ChatterGroupDetail> newResult = new List<ChatterGroupDetail>();

		if (!String.isBlank(searchName) && !groupList.isEmpty()) {
			for (ChatterGroupDetail Item : groupList) {
				if (Item.GroupName.toLowerCase().contains(searchName.toLowerCase())) {
					newResult.add(Item);
				}
			}
		}
		else {
			newResult.addAll(groupList);
		}

		return newResult;
	}

	// Search Group_Control__c From  Name
	private List<GroupControlItem> searchGroupControlFromName(List<GroupControlItem> groupList, String searchName) {

		List<GroupControlItem> newResult = new List<GroupControlItem>();

		if (!String.isBlank(searchName) && !groupList.isEmpty()) {
			for (GroupControlItem Item : groupList) {
				if (Item.name.toLowerCase().contains(searchName.toLowerCase())) {
					newResult.add(Item);
				}
			}
		}
		else {
			newResult.addAll(groupList);
		}

		return newResult;
	}

	// Get DateTime Last Activity to Group_Controll__c
	private DateTime getLastActivityGroupControl(Id sObjectId) {

		List<FeedItem> feedItemList = new List<FeedItem>();
		DateTime result;

		if (!String.isBlank(sObjectId)) {
			feedItemList = [
				SELECT ID, CreatedDate
				FROM FeedItem
				WHERE ParentId =: sObjectId
				ORDER BY CreatedDate DESC
				LIMIT 1
			];
		}

		if (!feedItemList.isEmpty()) {
			result = feedItemList[0].CreatedDate;
		}

		return result;
	}

	//CUSTOM CLASSES
	public class GroupControlItem {
		public String groupId { get; set; }
		public String name { get; set; }
		public Datetime lastActivity { get; set; }
		public String membership { get; set; }
		public String photoUrl { get; set; }
		public String groupType { get; set; }
		public sObject groupObject { get; set; }
		public Boolean follows { get; set; }
	}

}
*/
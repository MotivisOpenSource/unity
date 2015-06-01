public without sharing class CommunityGroupsController {

	public String currentFilter {
		get {
			return ApexPages.currentPage().getParameters().get('f');
		}
		private set;
	}
	private final String CurrentCommunityId = Network.getNetworkId();

	public CommunityGroupsController() {

	}

	public Boolean getShowCreateGroupBtn() {
		return CommunityUtils.canCreateGroup();
	}


	public static List<ChatterGroupDetail> getChatterGroupDetailList(List<Community_Group_Control__c> GroupControlList) {

		List<ChatterGroupDetail> Result = new List<ChatterGroupDetail>();
		Map<Id,CollaborationGroup> CollaborationGroupMap = new Map<Id,CollaborationGroup>();
		Map<Id,CollaborationGroupMember> CollaborationGroupMemberMap = new Map<Id,CollaborationGroupMember>();
		List<CollaborationGroupMember> CollaborationGroupMemberList = new List<CollaborationGroupMember>();
//		Map<Id, Community_Group_Manager__c> GroupControlMembershipMap = new Map<Id, Community_Group_Manager__c>();
//		List<Community_Group_Manager__c> GroupControlMembershipList = new List<Community_Group_Manager__c>();
		List<CollaborationGroupMemberRequest> GroupMemberRequestList = new List<CollaborationGroupMemberRequest>();
		Map<Id, CollaborationGroupMemberRequest> GroupMemberRequestMap = new Map<Id, CollaborationGroupMemberRequest>();
		Set<Id> ChatterGroupIdSet = new Set<Id>();
		Set<Id> GroupControlSet = new Set<Id>();
		Boolean ModifyAllData = CommunityUtils.isModifyAllData();
		Boolean ViewAllData = CommunityUtils.isViewAllData();

		for (Community_Group_Control__c Item : GroupControlList) {
			if (Item.Chatter_Group_ID__c != NULL) {
				ChatterGroupIdSet.add(Item.Chatter_Group_ID__c);
			}
//			GroupControlSet.add(Item.Id);
		}

		if (!ChatterGroupIdSet.isEmpty()) {
			collaborationGroupMap = new Map<Id,CollaborationGroup> ([
				SELECT CollaborationGroup.Id, CollaborationGroup.Name, CollaborationGroup.Description,
					CollaborationGroup.InformationTitle, CollaborationGroup.InformationBody,
					CollaborationGroup.SmallPhotoUrl, CollaborationGroup.FullPhotoUrl,
					CollaborationGroup.MemberCount, CollaborationGroup.LastFeedModifiedDate,
					CollaborationGroup.OwnerId, CollaborationGroup.NetworkId, CollaborationGroup.IsArchived,
					CollaborationGroup.CollaborationType, CollaborationGroup.CanHaveGuests,
					CollaborationGroup.Owner.Name, CollaborationGroup.Owner.FirstName,
					CollaborationGroup.Owner.LastName, CollaborationGroup.Owner.SmallPhotoUrl, CollaborationGroup.Owner.Contact.Primary_role__c
				FROM CollaborationGroup
				WHERE Id IN: ChatterGroupIdSet
				AND NetworkId =: Network.getNetworkId()
				ORDER BY Name
			]);
		}

		if (!collaborationGroupMap.isEmpty()) {
			CollaborationGroupMemberList = [
				SELECT MemberId, Id, CollaborationRole,CollaborationGroupId,
					CollaborationGroup.Id, CollaborationGroup.Name, CollaborationGroup.Description,
					CollaborationGroup.InformationTitle, CollaborationGroup.InformationBody,
					CollaborationGroup.SmallPhotoUrl, CollaborationGroup.FullPhotoUrl, CollaborationGroup.MemberCount,
					CollaborationGroup.LastFeedModifiedDate,
					CollaborationGroup.OwnerId, CollaborationGroup.NetworkId, CollaborationGroup.IsArchived,
					CollaborationGroup.CollaborationType, CollaborationGroup.CanHaveGuests,
					CollaborationGroup.Owner.Name, CollaborationGroup.Owner.FirstName, CollaborationGroup.Owner.Id,
					CollaborationGroup.Owner.LastName, CollaborationGroup.Owner.SmallPhotoUrl
				FROM CollaborationGroupMember
				WHERE CollaborationGroup.NetworkId =: Network.getNetworkId()
				AND MemberId =: UserInfo.getUserId()
				AND CollaborationGroup.id IN: collaborationGroupMap.keySet()
				ORDER BY CollaborationGroup.Name
			];

			GroupMemberRequestList = [
				SELECT Id, CollaborationGroupID, RequesterID, Status
				FROM CollaborationGroupMemberRequest
				WHERE CollaborationGroupID IN: collaborationGroupMap.keySet()
				AND RequesterID =: UserInfo.getUserId()
				AND Status = 'Pending'
			];
		}

		if (!CollaborationGroupMemberList.isEmpty()) {
			for (CollaborationGroupMember Item : CollaborationGroupMemberList) {
				CollaborationGroupMemberMap.put(Item.CollaborationGroup.id, Item);
			}
		}

		if (!GroupMemberRequestList.isEmpty()) {
			for (CollaborationGroupMemberRequest Item : GroupMemberRequestList) {
				GroupMemberRequestMap.put(Item.CollaborationGroupID, Item);
			}
		}
/*
		if (!GroupControlSet.isEmpty()) {
			GroupControlMembershipList = [
				SELECT Manager_Role__c, Group_Control__c
				FROM Community_Group_Manager__c
				WHERE Group_Control__c IN: GroupControlSet
				AND Group_Membership_SF_ID__c =: UserInfo.getUserId()
			];
		}

		if (!GroupControlMembershipList.isEmpty()) {
			for (Community_Group_Manager__c Item : GroupControlMembershipList) {
				if (Item.Manager_Role__c != NULL) {
					GroupControlMembershipMap.put(Item.Group_Control__c, Item);
				}
			}
		}
*/
		for (Community_Group_Control__c Item : GroupControlList) {

			if (collaborationGroupMap.get(Item.Chatter_Group_ID__c) != NULL) {

				ChatterGroupDetail groupDetail = new ChatterGroupDetail(Item);

				groupDetail.GroupMembersCount = collaborationGroupMap.get(Item.Chatter_Group_ID__c).MemberCount;
				groupDetail.GroupLastActivityDate = collaborationGroupMap.get(Item.Chatter_Group_ID__c).LastFeedModifiedDate;
				groupDetail.GroupId = Item.Chatter_Group_ID__c;
				if (collaborationGroupMap.get(Item.Chatter_Group_ID__c).FullPhotoUrl != NULL) {
					groupDetail.GroupPhotoUrl = collaborationGroupMap.get(Item.Chatter_Group_ID__c).FullPhotoUrl;
				}
				groupDetail.GroupLastActivityDate = collaborationGroupMap.get(Item.Chatter_Group_ID__c).LastFeedModifiedDate;
				groupDetail.GroupLastActivityDateFormatted = groupDetail.formatActivityDate();

				if (collaborationGroupMap.get(Item.Chatter_Group_ID__c).Owner.Id == UserInfo.getUserId()) {
					groupDetail.CurrentMemberRole = 'Owner';
				}
				else if (CollaborationGroupMemberMap.get(Item.Chatter_Group_ID__c) != NULL) {
					groupDetail.CurrentMemberRole = CollaborationGroupMemberMap.get(Item.Chatter_Group_ID__c).CollaborationRole;
				}
				else {
					groupDetail.CurrentMemberRole = 'NotAMember';

					Boolean statusJoin = (collaborationGroupMap.get(Item.Chatter_Group_ID__c).CollaborationType == 'Public')
						|| (collaborationGroupMap.get(Item.Chatter_Group_ID__c).CollaborationType == 'Private'
							&& ModifyAllData == true && ViewAllData == true);

					Boolean statusRequested = (collaborationGroupMap.get(Item.Chatter_Group_ID__c).CollaborationType == 'Private'
						&& item.Discoverable__c == true
						&& ModifyAllData == false
						&& GroupMemberRequestMap.get(Item.Chatter_Group_ID__c) != NULL);

					Boolean statusRequestToJoin = (collaborationGroupMap.get(Item.Chatter_Group_ID__c).CollaborationType == 'Private'
						&& item.Discoverable__c == true
						&& ModifyAllData == false
						&& ViewAllData == false
						&& GroupMemberRequestMap.get(Item.Chatter_Group_ID__c) == NULL);

					if (statusJoin) {
						groupDetail.NotAMemberStatus = 'Join';
					}
					else if (statusRequested) {
						groupDetail.NotAMemberStatus = 'Requested';
					}
					else if (statusRequestToJoin) {
						groupDetail.NotAMemberStatus = 'RequestToJoin';
					}
					else {
						groupDetail.NotAMemberStatus = '';
					}
				}

				Result.add(groupDetail);
			}

		}

		return Result;
	}

	public static DiscoverResultClass getDiscoverResultClassForGroups(Integer size, List<Community_Group_Control__c> GroupControlList) {

		List<ChatterGroupDetail> ChatterGroupDetailList = new List<ChatterGroupDetail>();
		DiscoverResultClass Result = new DiscoverResultClass();

		ChatterGroupDetailList = CommunityGroupsController.getChatterGroupDetailList(GroupControlList);
		if (!ChatterGroupDetailList.isEmpty()) {
			Result = new DiscoverResultClass(size, ChatterGroupDetailList);
		}

		return Result;
	}

	@RemoteAction
	public static Boolean subscriberAction(Id recordId, Boolean isSubscribe) {
		CommunityUtils.subscriberUser(recordId,!isSubscribe);
		return true;		
	}
	@RemoteAction
	public static DiscoverResultClass getGroups(Integer limitSize, Integer startFrom, String currentTab) {

		String gQuery = 'SELECT Id, Name, Chatter_Group_ID__c, Discoverable__c, Description__c, Type__c FROM Community_Group_Control__c';
		Boolean foundData = false;
		Set<String> filtredChatterGroups = new Set<String>();
		Set<String> alreadyJoinedGroups = new Set<String>();
		Set<String> matchedTagedGroups = new Set<String>();

		if (currentTab == 'all_groups' || currentTab == 'recommended_groups' || String.isBlank(currentTab)) {
			for (CollaborationGroup cgItem : [SELECT Id FROM CollaborationGroup WHERE NetworkId = :Network.getNetworkId()]) {
				filtredChatterGroups.add(cgItem.Id);
			}
			gQuery += ' WHERE Chatter_Group_ID__c IN :filtredChatterGroups AND Discoverable__c = true';
			foundData = filtredChatterGroups.size() > 0;
		}

		if (currentTab == 'recommended_groups' && foundData) {
			User currentUser = [SELECT ContactId, Community_Contact_ID__c FROM User WHERE Id = :UserInfo.getUserId()];
			String currentContactId = currentUser.ContactId == NULL ? currentUser.Community_Contact_ID__c : currentUser.ContactId;
			Set<Id> userTags = new Set<Id>();
			if (String.isNotBlank(currentContactId)) {
				for (Community_Profile_Tag__c cpt : [SELECT Community_Tag__c FROM Community_Profile_Tag__c WHERE Active__c = true AND Contact__c = :currentContactId]) {
					userTags.add(cpt.Community_Tag__c);
				}
			}
			if (userTags.size() > 0) {
				for (Community_Group_Control_Tag__c cgctItem : [
									SELECT Group_Control__r.Chatter_Group_ID__c FROM Community_Group_Control_Tag__c
									WHERE Community_Tag__c IN :userTags AND Group_Control__c != NULL AND Group_Control__r.Chatter_Group_ID__c != NULL]) {
					matchedTagedGroups.add(cgctItem.Group_Control__r.Chatter_Group_ID__c);
				}
			}
			for (CollaborationGroupMemberRequest cgmrItem : [SELECT CollaborationGroupId FROM CollaborationGroupMemberRequest WHERE RequesterId =:UserInfo.getUserId() AND Status = 'Pending']) {
				matchedTagedGroups.add(cgmrItem.CollaborationGroupId);
			}
			foundData = matchedTagedGroups.size() > 0;
			if (foundData) {
				gQuery += ' AND Chatter_Group_ID__c IN :matchedTagedGroups';
				for (CollaborationGroupMember cgmItem2 : [
						SELECT CollaborationGroupId FROM CollaborationGroupMember
						WHERE CollaborationGroup.NetworkId = :Network.getNetworkId() AND MemberId = :UserInfo.getUserId()
							]) {
					alreadyJoinedGroups.add(cgmItem2.CollaborationGroupId);
				}
				if (alreadyJoinedGroups.size() > 0) {
					gQuery += ' AND Chatter_Group_ID__c NOT IN :alreadyJoinedGroups';
				}
			}
		}

		if (currentTab == 'my_groups') {
			for (CollaborationGroupMember cgmItem : [
					SELECT CollaborationGroupId FROM CollaborationGroupMember
					WHERE CollaborationGroup.NetworkId = :Network.getNetworkId() AND MemberId = :UserInfo.getUserId()
						]) {
				filtredChatterGroups.add(cgmItem.CollaborationGroupId);
			}
			gQuery += ' WHERE Chatter_Group_ID__c IN :filtredChatterGroups';
			foundData = filtredChatterGroups.size() > 0;
		}

		DiscoverResultClass DiscoverResult;
		if (foundData) {
			gQuery += ' ORDER BY Name';
			List<Community_Group_Control__c> allFoundGroupsList = Database.query(gQuery);
			Integer allSize = allFoundGroupsList.size();
			Integer startCopyInterval = startFrom;
			Integer requestedEndInterval = startFrom + limitSize;
			Integer endCopyInterval = (allSize > 0 && allSize > startFrom) ? ((allSize > requestedEndInterval) ? requestedEndInterval : allSize) : startFrom;
			foundData = startCopyInterval < endCopyInterval;
			if (foundData) {
				List<Community_Group_Control__c> groupsPage = new List<Community_Group_Control__c>();
				for (Integer ii = startCopyInterval; ii < endCopyInterval; ii++) {
					groupsPage.add(allFoundGroupsList[ii]);
				}
				DiscoverResult = CommunityGroupsController.getDiscoverResultClassForGroups(allSize, groupsPage);
			}
		}

		if (!foundData){
			DiscoverResult = new DiscoverResultClass();
		}

		return DiscoverResult;
	}
	
	public static String CreateChatterGroupMember { get {return '1';} set;}
	public static String DeleteChatterGroupMember { get {return '2';} set;}
	public static String CreateGroupManager { get {return '3';} set;}
	public static String DeleteGroupManager { get {return '4';} set;}
	public static String CreateJoinPrivateGroupRequest { get {return '5';} set;}
	public static String DeleteJoinPrivateGroupRequest { get {return '6';} set;}
	public static String AcceptJoinPrivateGroupRequest { get {return '7';} set;}
	public static String DeclineJoinPrivateGroupRequest { get {return '8';} set;}

	@RemoteAction
	public static Boolean doGroupAction(String currentChatterGroupId, string doAction) {
		List<Community_Group_Control__c> communityGroupControllList = [
		SELECT Id, Chatter_Group_ID__c
		FROM Community_Group_Control__c
		WHERE Chatter_Group_ID__c =: currentChatterGroupId
		LIMIT 1
		];
		if (!communityGroupControllList.isEmpty()) {
			currentChatterGroupId = communityGroupControllList[0].Id;
		}
		CommunityUtils.membership(UserInfo.getUserId(), currentChatterGroupId, doAction);
		return true;
	}

	public class DiscoverResultClass {
		public Integer TotalRecords { get; set; }
		public List<ChatterGroupDetail> Groups  { get; set; }
		public Boolean HasMore { get; set; }

		public DiscoverResultClass(Integer total, List<ChatterGroupDetail> groupsList) {
			this.TotalRecords = total;
			this.Groups = groupsList;
		}

		public DiscoverResultClass() {
		}
	}

	public class ChatterGroupDetail {
		public Id GroupId { get; set; }
		public Id GroupControlId { get;set; }
		public String GroupName { get; set; }
		public String GroupDescription { get; set; }
		public String GroupPhotoUrl {
			get {
				if (String.isBlank(this.GroupPhotoUrl)) {
					this.GroupPhotoUrl = '/profilephoto/0F9/F';
				}
				this.GroupPhotoUrl = this.GroupPhotoUrl.replace(Site.getBaseUrl(), '');
				return this.GroupPhotoUrl;
			}
			set;
		}
		public String GroupVisibility { get; set; }
		public List<Community_Events__c> UpcomingEvents { get; set; }
		public String CurrentMemberRole { get; set; }
		public Integer GroupMembersCount {get;set;}
		public Datetime GroupLastActivityDate { get; set; }
		public String GroupLastActivityDateFormatted { get {
				if (String.isBlank(this.GroupLastActivityDateFormatted) && this.GroupLastActivityDate != NULL) {
					this.GroupLastActivityDateFormatted = formatActivityDate();
				}
				return this.GroupLastActivityDateFormatted;
			}
			set;
		}
		private String formatActivityDate() {
			return String.format('{0} at {1}',
				new List<String> {
					this.GroupLastActivityDate.format('MMMMM d, yyyy'),
					this.GroupLastActivityDate.format('HH:mm a')
				}
			);
		}
		public String NotAMemberStatus {get;set;}

		public ChatterGroupDetail(Community_Group_Control__c groupDetail) {
			this.GroupId = NULL;
			if (groupDetail.Chatter_Group_ID__c != NULL) {
				this.GroupId = groupDetail.Chatter_Group_ID__c;
			}
			this.GroupControlId = groupDetail.Id;
			this.GroupName = groupDetail.Name;
			this.GroupDescription = groupDetail.Description__c;
			this.GroupVisibility = groupDetail.Type__c;
		}
	}
}
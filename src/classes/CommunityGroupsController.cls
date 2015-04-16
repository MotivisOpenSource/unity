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

				system.debug(groupDetail.NotAMemberStatus);

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
		if (!isSubscribe) {
			List<EntitySubscription> followings = [
				Select SubscriberId, ParentId, IsDeleted, Id, CreatedDate, CreatedById
				From EntitySubscription
				WHERE SubscriberId =:Userinfo.getUserId()
				AND ParentId = :recordId
				LIMIT 1
			];
			if (!followings.isEmpty()) {
				//ConnectApi.Chatter.deleteSubscription(Network.getNetworkId(), followings[0].Id);
			}
		} else if (isSubscribe) {
			//ConnectApi.ChatterUsers.follow(Network.getNetworkId(), 'me', memberId);
		}
		return true;
	}
	@RemoteAction
	public static DiscoverResultClass getGroups(Integer limitSize, Integer startFrom, String currentTab) {

		String currentCommunityId = Network.getNetworkId();
		List<Community_Group_Control__c> communityGroupControllList = new List<Community_Group_Control__c>();
		List<Community_Group_Control__c> communityGroupControllSizeList = new List<Community_Group_Control__c>();
		Map<Id, CollaborationGroup> collaborationGroupMap = new Map<Id, CollaborationGroup>();

		collaborationGroupMap = new Map<Id,CollaborationGroup> ([
			SELECT CollaborationGroup.Id
			FROM CollaborationGroup
			WHERE NetworkId =: currentCommunityId
		]);

		if (currentTab == 'all_groups' || currentTab == '') { //all
			communityGroupControllList = [
				SELECT Id, Name, Chatter_Group_ID__c, Discoverable__c, Description__c, Type__c
				FROM Community_Group_Control__c
				WHERE Chatter_Group_ID__c != NULL
				AND Discoverable__c = true
				AND Chatter_Group_ID__c IN: collaborationGroupMap.keySet()
				ORDER BY Name
				LIMIT :limitSize
				OFFSET :startFrom
			];

			communityGroupControllSizeList = [
				SELECT Id
				FROM Community_Group_Control__c
				WHERE Chatter_Group_ID__c != NULL
				AND Discoverable__c = true
				AND Chatter_Group_ID__c IN: collaborationGroupMap.keySet()
			];

		} else if (currentTab == 'my_groups') {
			List<Community_Group_Manager__c> groupControlMembershipList = new List<Community_Group_Manager__c>();
			List<CollaborationGroupMember> collaborationGroupMemberList = new List<CollaborationGroupMember>();

			List<Id> collaborationGroupIdList = new List<Id>();
			List<Id> groupControlIdList = new List<Id>();

			collaborationGroupMemberList = [
				SELECT Id, CollaborationGroupId
				FROM CollaborationGroupMember
				WHERE CollaborationGroup.NetworkId =: currentCommunityId
				AND MemberId =: UserInfo.getUserId()
			];

			if (!collaborationGroupMemberList.isEmpty()) {
				for (CollaborationGroupMember item : collaborationGroupMemberList) {
					collaborationGroupIdList.add(item.CollaborationGroupId);
				}
			}

			groupControlMembershipList = [
				SELECT Group_Control__c
				FROM Community_Group_Manager__c
				WHERE Group_Manager_SF_ID__c =: UserInfo.getUserId()
			];

			if (!groupControlMembershipList.isEmpty()) {
				for (Community_Group_Manager__c item : groupControlMembershipList) {
					groupControlIdList.add(item.Group_Control__c);
				}
			}

			if (!groupControlIdList.isEmpty() || !collaborationGroupIdList.isEmpty()) {
				communityGroupControllList = [
					SELECT Id, Name, Chatter_Group_ID__c, Discoverable__c, Description__c, Type__c
					FROM Community_Group_Control__c
					WHERE (Id IN: groupControlIdList
					OR Chatter_Group_ID__c IN: collaborationGroupIdList)
					AND Discoverable__c = true
					ORDER BY Name
					LIMIT :limitSize
					OFFSET :startFrom
				];
			}
			if (!groupControlIdList.isEmpty() || !collaborationGroupIdList.isEmpty()) {
				communityGroupControllSizeList = [
					SELECT Id, Name, Chatter_Group_ID__c, Discoverable__c, Description__c, Type__c
					FROM Community_Group_Control__c
					WHERE (Id IN: groupControlIdList
					OR Chatter_Group_ID__c IN: collaborationGroupIdList)
					AND Discoverable__c = true
				];
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

				if (!groupControllsIds.isEmpty()) {
					communityGroupControllList = [
						SELECT Id, Name, Chatter_Group_ID__c, Discoverable__c, Description__c, Type__c
						FROM Community_Group_Control__c
						WHERE Chatter_Group_ID__c != NULL
						AND Discoverable__c = true
						AND Id IN: groupControllsIds
						AND Chatter_Group_ID__c IN: collaborationGroupMap.keySet()
						ORDER BY Name
						LIMIT :limitSize
						OFFSET :startFrom
					];
				}

				if (!groupControllsIds.isEmpty()) {
					communityGroupControllSizeList = [
						SELECT Id, Name, Chatter_Group_ID__c, Discoverable__c, Description__c, Type__c
						FROM Community_Group_Control__c
						WHERE Chatter_Group_ID__c != NULL
						AND Discoverable__c = true
						AND Id IN: groupControllsIds
						AND Chatter_Group_ID__c IN: collaborationGroupMap.keySet()
					];
				}

			}
		}

		DiscoverResultClass DiscoverResult = new DiscoverResultClass();
		if (!communityGroupControllSizeList.isEmpty() && !communityGroupControllList.isEmpty()) {
			DiscoverResult = CommunityGroupsController.getDiscoverResultClassForGroups(communityGroupControllSizeList.size(), communityGroupControllList);
		}

		return DiscoverResult;

	}

	@RemoteAction
	public static Boolean leaveGroup(String currentChatterGroupId) {

		List<Community_Group_Control__c> communityGroupControllList = [
			SELECT Id, Chatter_Group_ID__c
			FROM Community_Group_Control__c
			WHERE Chatter_Group_ID__c =: currentChatterGroupId
			LIMIT 1
		];
		if (!communityGroupControllList.isEmpty()) {
			currentChatterGroupId = communityGroupControllList[0].Id;
		}

		CommunityGroupManageController.membership(UserInfo.getUserId(), currentChatterGroupId, '2'); //remove member
		return true;
	}

	@RemoteAction
	public static Boolean jointToGroup(String currentChatterGroupId) {

		List<Community_Group_Control__c> communityGroupControllList = [
			SELECT Id, Chatter_Group_ID__c
			FROM Community_Group_Control__c
			WHERE Chatter_Group_ID__c =: currentChatterGroupId
			LIMIT 1
		];
		if (!communityGroupControllList.isEmpty()) {
			currentChatterGroupId = communityGroupControllList[0].Id;
		}

		CommunityGroupManageController.membership(UserInfo.getUserId(), currentChatterGroupId, '1'); //add member
		return true;
	}

	@RemoteAction
	public static Boolean requestToJoin(String currentChatterGroupId) {

		Boolean result = false;

		result = CommunityUtils.createGroupMemberRequest(currentChatterGroupId, UserInfo.getUserId());

		return result;
	}

	@RemoteAction
	public static Boolean calcelRequestToJoin(String currentChatterGroupId) {

		Boolean result = false;

		result = CommunityUtils.deleteGroupMemberRequest(currentChatterGroupId, UserInfo.getUserId());

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

	public static void test1() {
		Integer i = 0;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
	}

}
public without sharing class CommunityGroupsController extends CommunityGroupsBase {

	public String currentFilter { 
		get {
			return ApexPages.currentPage().getParameters().get('f');
		}
		private set;
	}
	private final String CurrentCommunityId = getCurrentCommunityId();

	public CommunityGroupsController() {

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
	public static DiscoverResultClass getGroups(Integer limitSize, Integer startFrom, String currentTab) {
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
				SELECT Id, Chatter_Group_ID__c, Discoverable__c, Image_Path__c
				FROM Community_Group_Control__c
				WHERE Chatter_Group_ID__c != NULL
				AND Discoverable__c = true
				LIMIT 1000
			];
		} else if (currentTab == 'my_groups') {
			Set<Id> memberOfGroupsIds = new Set<Id>(CollaborationGroupMemberMap.keySet());
			communityGroupControllList = [
				SELECT Id, Chatter_Group_ID__c, Discoverable__c, Image_Path__c
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
					SELECT Id, Chatter_Group_ID__c, Discoverable__c, Image_Path__c
					FROM Community_Group_Control__c
					WHERE Chatter_Group_ID__c != NULL
					AND Discoverable__c = true
					AND Id IN: groupControllsIds
					LIMIT 1000
				];
			}
		}
		Map<Id, String> groupControlsPhotos = new Map<Id, String>();
		Set<Id> availableGroupsIds = new Set<Id>();
		for (Community_Group_Control__c groupControl : communityGroupControllList) {
			availableGroupsIds.add(groupControl.Chatter_Group_ID__c);
			if (!String.isBlank(groupControl.Image_Path__c)) {
				groupControlsPhotos.put(groupControl.Chatter_Group_ID__c, groupControl.Image_Path__c);
			}
		}

		List<CollaborationGroup> allGroups = [
			SELECT Id
			FROM CollaborationGroup
			WHERE Id IN: availableGroupsIds
			AND NetworkId =: currentCommunityId
			ORDER BY Name
		];

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
			if (groupControlsPhotos.containsKey(item.Id)) {
				groupDetail.GroupPhotoUrl = String.format('{0}', new List<String> { groupControlsPhotos.get(item.Id) });
			}
			result.add(groupDetail);
		}
		DiscoverResultClass outputResult = new DiscoverResultClass(allGroups.size(), result);
		return outputResult;
	}
}
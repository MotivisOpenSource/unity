public with sharing class CommunityGroupDetailPageController extends CommunityGroupsBase {

	// -- common variables --
	public Community_Group_Control__c control { get;set; }
	public String description { get; set; }
	public String SitePrefix {
		get {
			if (this.SitePrefix == NULL) {
				this.SitePrefix = Site.getPathPrefix();
			}
			return this.SitePrefix;
		}
		private set;
	}
	public ChatterGroupDetail CurrentGroup { get; set; }
	
	public List<Community_Events__c> communityEventList { get;set; }
	public List<ContentDocumentLink> contentDocumentLinkList { get;set; }
	public Boolean isChatterGroup { get; set; }
	private final String CurrentCommunityId = getCurrentCommunityId();
	private final String CurrentGroupId = ApexPages.currentPage().getParameters().get('g');
	private final String CurrentGroupControlId = ApexPages.currentPage().getParameters().get('gc');
	
	public String CurrentUserId {
		get {
			return UserInfo.getUserId();
		}
		set;
	}

	public String subscriptionId {get; set;}
	public String followUserId {get; set;}

	// CONSTRUCTOR
	public CommunityGroupDetailPageController() {

		List<Community_Event_Tag__c> communityEventTagList = new List<Community_Event_Tag__c>();
		List<Community_Group_Control__c> communityGroupControllList = new List<Community_Group_Control__c>();
		List<String> communityEventTagIdList = new List<String>();
		List<String> communityGroupControlIdList = new List<String>();
		List<CollaborationGroup> collaborationGroupList = new List<CollaborationGroup>();
		List<CollaborationGroupMember> collaborationGroupMemberList = new List<CollaborationGroupMember>();
		List<EntitySubscription> subscriptionList = new List<EntitySubscription>();
		this.contentDocumentLinkList = new List<ContentDocumentLink>();
		this.communityEventList = new List<Community_Events__c>();
		this.isChatterGroup = false;

		if (CurrentGroupControlId != NULL) {
			communityGroupControllList = [
				SELECT Id, Name, Chatter_Group_ID__c, Description__c, Type__c, Image_Path__c, OwnerId
				FROM Community_Group_Control__c
				WHERE Id =: CurrentGroupControlId
				LIMIT 1
			];

			subscriptionList = [
				SELECT Id, ParentId
				FROM EntitySubscription
				WHERE ParentId = :CurrentGroupControlId
				AND SubscriberId = :UserInfo.getUserId()
				LIMIT 1
			];

		}

		if (!communityGroupControllList.isEmpty()) {
			if (communityGroupControllList[0].Chatter_Group_ID__c != NULL) {
				this.CurrentGroupId = communityGroupControllList[0].Chatter_Group_ID__c;
			}
			else {
				this.CurrentGroup = new ChatterGroupDetail(communityGroupControllList[0]);
				if (communityGroupControllList[0].OwnerId == UserInfo.getUserId()) {
					this.CurrentGroup.CurrentMemberRole = getMemberRole('Admin');
				}
				else if (!subscriptionList.isEmpty()) {
					this.CurrentGroup.CurrentMemberRole = getMemberRole('Standard');
				}
				else {
					this.CurrentGroup.CurrentMemberRole = getMemberRole('');
				}
//				this.CurrentGroup.Members = getMembersFromId(CurrentGroup.GroupId);
				this.contentDocumentLinkList = getContentDocumentLink(CurrentGroup.GroupId);
			}
		}

		if (this.CurrentGroupId != NULL) {
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
				WHERE Id =: this.CurrentGroupId
//				AND NetworkId =: this.CurrentCommunityId
				LIMIT 1
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
				WHERE CollaborationGroup.Id =: this.CurrentGroupId
				AND MemberId =: UserInfo.getUserId()
//				AND CollaborationGroup.NetworkId =: this.CurrentCommunityId
				LIMIT 1
			];

			communityGroupControllList = [
				SELECT Id, Chatter_Group_ID__c, Image_Path__c
				FROM Community_Group_Control__c
				WHERE Chatter_Group_ID__c =: CurrentGroupId
				LIMIT 1
			];
			this.contentDocumentLinkList = getContentDocumentLink(CurrentGroupId);
		}

		if (!collaborationGroupList.isEmpty()) {
			this.CurrentGroup = new ChatterGroupDetail(collaborationGroupList[0]);
			if (communityGroupControllList.size() > 0 && !String.isBlank(communityGroupControllList[0].Image_Path__c)) {
				this.CurrentGroup.GroupPhotoUrl = communityGroupControllList[0].Image_Path__c;
			}
			
			this.CurrentGroup.Members = getMembersFromId(CurrentGroup.GroupId);
			if (!collaborationGroupMemberList.isEmpty()) {
				this.CurrentGroup.CurrentMemberRole = getMemberRole(collaborationGroupMemberList[0].CollaborationRole);
			}
			else {
				this.CurrentGroup.CurrentMemberRole = getMemberRole('');
			}
			this.isChatterGroup = true;
		}

		if (!communityGroupControllList.isEmpty()) {
			for (Community_Group_Control__c Item : communityGroupControllList) {
				communityGroupControlIdList.add(Item.Id);
			}
			if (!communityGroupControlIdList.isEmpty()) {
				communityEventTagList = [
					SELECT Id, Community_Tag__c, Community_Event__c
					FROM Community_Event_Tag__c
					WHERE Community_Group_Control__c IN: communityGroupControlIdList
					ORDER BY CreatedDate DESC
				];
			}
		}

		if (!communityEventTagList.isEmpty()) {
			for (Community_Event_Tag__c communityEventItem : communityEventTagList) {
				communityEventTagIdList.add(communityEventItem.Community_Event__c);
			}
			if (!communityEventTagIdList.isEmpty()) {
				communityEventList = [
					SELECT Id, Name__c, Start__c
					FROM Community_Events__c
					WHERE Id IN: communityEventTagIdList
					AND Start__c > TODAY

				];
			}
		}

		if(control == null) {
			this.control = CommunityGroupManageController.pullGroupControlRecord(false);	
		}
		if(CurrentGroupControlId == null && control != null) {
			this.CurrentGroupControlId = (String)control.Id;
		}
		return;
	}

	//PUBLIC METHODS

	public PageReference refresh() {
		return NULL;
	}

	public void RefreshMembersInfo() {
		CurrentGroup.Members = getMembersFromId(CurrentGroup.GroupId);
	}
	
	public PageReference jointToGroup() {
		System.debug('CurrentGroupControlId:  ' + CurrentGroupControlId);
		System.debug('UserId: ' + UserInfo.getUserId());
		//ConnectApi.ChatterGroups.addMember(CurrentCommunityId, CurrentGroupId, UserInfo.getUserId());
		CommunityGroupManageController.membership(UserInfo.getUserId(), CurrentGroupControlId, '1'); //add member
		RefreshMembersInfo();
		//CurrentGroup.CurrentMemberRole = getMemberRole('Standard');
		return null;
	}

	public void leaveGroup() {
		System.debug('CurrentGroupControlId:  ' + CurrentGroupControlId);
		System.debug('UserId: ' + UserInfo.getUserId());
		//CollaborationGroupMember CurrentMember = [SELECT Id, MemberId, CollaborationGroupId FROM CollaborationGroupMember WHERE CollaborationGroupId =: CurrentGroupId AND MemberId =: UserInfo.getUserId()];
		//ConnectApi.ChatterGroups.deleteMember(CurrentCommunityId, CurrentMember.Id);
		//CurrentGroup.CurrentMemberRole = getMemberRole('');
		CommunityGroupManageController.membership(UserInfo.getUserId(), CurrentGroupControlId, '2'); //remove member
		RefreshMembersInfo();
	}

	public void follow() {
		ConnectApi.Subscription currentSubsc = ConnectApi.ChatterUsers.follow(CurrentCommunityId, UserInfo.getUserId(), followUserId);
		for(ChatterGroupMember currentMember : CurrentGroup.Members) {
			if(currentMember.MemberId == followUserId) {
				currentMember.SubscriptionId = currentSubsc.Id;
				currentMember.MemberIsFollowing = true;
				break;
			}
		}
	}
	public PageReference unfollow() {
		ConnectApi.Chatter.deleteSubscription(CurrentCommunityId, subscriptionId);
		for(ChatterGroupMember currentMember : CurrentGroup.Members) {
			if(currentMember.SubscriptionId == subscriptionId) {
				currentMember.SubscriptionId = null;
				currentMember.MemberIsFollowing = false;
				break;
			}
		}
		return null;
	}

	public PageReference goToCreateEvent() {

		PageReference pr;

		if (!String.isBlank(CurrentGroupId)) {
			pr = new PageReference('/apex/CommunityEventEdit?g=' + CurrentGroup.GroupId
				+'&retURL=/apex/CommunityGroupDetailPage?g=' + CurrentGroupId
			);
		}
		else if (!String.isBlank(CurrentGroupControlId)) {
			pr = new PageReference('/apex/CommunityEventEdit?g=' + CurrentGroup.GroupId
				+'&retURL=/apex/CommunityGroupDetailPage?gc=' + CurrentGroupControlId
			);
		}

		return pr;
	}

	//PRIVATE METHODS
	//Get Group Files
	private List<ContentDocumentLink> getContentDocumentLink(String linkedEntityId) {

		List<ContentDocumentLink> result = new List<ContentDocumentLink>();

		if (!String.isBlank(linkedEntityId)) {
			result = [
				SELECT ContentDocument.Title, ContentDocument.Id
				FROM ContentDocumentLink
				WHERE LinkedEntityId =: linkedEntityId
			];
		}

		return result;
	}

	// Get Members
	private List<ChatterGroupMember> getMembersFromId(String groupId) {

		List<CollaborationGroupMember> groupMemberList = new List<CollaborationGroupMember>();
		List<ChatterGroupMember> result = new List<ChatterGroupMember>();

		if (!String.isBlank(groupId)) {
			groupMemberList = [
				SELECT MemberId, Id, CollaborationRole,
					CollaborationGroupId,
					CollaborationGroup.Id, CollaborationGroup.Name, CollaborationGroup.Description,
					CollaborationGroup.InformationTitle, CollaborationGroup.InformationBody,
					CollaborationGroup.SmallPhotoUrl, CollaborationGroup.FullPhotoUrl, CollaborationGroup.MemberCount,
					CollaborationGroup.LastFeedModifiedDate,
					CollaborationGroup.OwnerId, CollaborationGroup.NetworkId, CollaborationGroup.IsArchived,
					CollaborationGroup.CollaborationType, CollaborationGroup.CanHaveGuests,
					CollaborationGroup.Owner.Name, CollaborationGroup.Owner.FirstName,
					CollaborationGroup.Owner.LastName, CollaborationGroup.Owner.SmallPhotoUrl,
					CollaborationGroupMember.Member.FirstName, CollaborationGroupMember.Member.LastName,
					CollaborationGroupMember.Member.SmallPhotoUrl
				FROM CollaborationGroupMember
				WHERE CollaborationGroup.Id =: groupId
//				AND CollaborationGroup.NetworkId =: this.CurrentCommunityId
			];
		}

		if (!groupMemberList.isEmpty()) {
			List<ConnectApi.Subscription> following = ConnectApi.ChatterUsers.getFollowings(CurrentCommunityId, UserInfo.getUserId()).following;
			System.debug(following);
			Map<String, String> SubscriptionMap = new Map<String, String>();
			for(ConnectApi.Subscription currentSubsc : following) {
				SubscriptionMap.put(currentSubsc.subject.id, currentSubsc.id);
			}

			for (CollaborationGroupMember item : groupMemberList) {
				ChatterGroupMember Member = new ChatterGroupMember(item);

				Boolean isFollowing = (item.MemberId != UserInfo.getUserId()) ? SubscriptionMap.containsKey(item.MemberId) : null;
				Member.MemberIsFollowing = isFollowing;

				String SubscriptionId = (SubscriptionMap.containsKey(item.MemberId)) ? SubscriptionMap.get(item.MemberId) : '';
				Member.SubscriptionId = SubscriptionId;
				
				result.add(Member);
			}
		}

		return result;
	}

}
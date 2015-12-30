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

public with sharing class CommunityGroupsController {

	public String currentFilter {
		get {
			return ApexPages.currentPage().getParameters().get('f');
		}
		private set;
	}

	private final String CurrentCommunityId = Network.getNetworkId();

	public CommunityGroupsController() {}

	public Boolean getShowCreateGroupBtn() {
		return CommunityUtils.canCreateGroup();
	}

	public static List<ChatterGroupDetail> getChatterGroupDetailList(List<Community_Group_Control__c> GroupControlList) {

		List<ChatterGroupDetail> Result = new List<ChatterGroupDetail>();
		Map<Id,CollaborationGroup> CollaborationGroupMap = new Map<Id,CollaborationGroup>();
		Map<Id,CollaborationGroupMember> CollaborationGroupMemberMap = new Map<Id,CollaborationGroupMember>();
		List<CollaborationGroupMember> CollaborationGroupMemberList = new List<CollaborationGroupMember>();
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
				SELECT MemberId, Id, CollaborationRole, CollaborationGroupId, Member.ContactId, Member.Community_Contact_ID__c,
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
					AND CollaborationGroup.Id IN: collaborationGroupMap.keySet()
					AND MemberId =: UserInfo.getUserId()
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

		for (CollaborationGroupMember Item : CollaborationGroupMemberList) {
			CollaborationGroupMemberMap.put(Item.CollaborationGroup.Id, Item);
		}

		for (CollaborationGroupMemberRequest Item : GroupMemberRequestList) {
			GroupMemberRequestMap.put(Item.CollaborationGroupID, Item);
		}

		for (Community_Group_Control__c Item : GroupControlList) {
			if (collaborationGroupMap.get(Item.Chatter_Group_ID__c) != NULL) {
				ChatterGroupDetail groupDetail = new ChatterGroupDetail(Item);
				groupDetail.GroupMembersCount = collaborationGroupMap.get(Item.Chatter_Group_ID__c).MemberCount;
				groupDetail.GroupLastActivityDate = collaborationGroupMap.get(Item.Chatter_Group_ID__c).LastFeedModifiedDate;
				groupDetail.GroupId = Item.Chatter_Group_ID__c;
				if (collaborationGroupMap.get(Item.Chatter_Group_ID__c).SmallPhotoUrl != NULL) {
					groupDetail.GroupPhotoUrl = collaborationGroupMap.get(Item.Chatter_Group_ID__c).SmallPhotoUrl;
				}
				groupDetail.GroupLastActivityDate = collaborationGroupMap.get(Item.Chatter_Group_ID__c).LastFeedModifiedDate;
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
							&& ModifyAllData == true);

					Boolean statusRequested = (collaborationGroupMap.get(Item.Chatter_Group_ID__c).CollaborationType == 'Private'
						&& item.Discoverable__c == true
						&& ModifyAllData == false
						&& GroupMemberRequestMap.get(Item.Chatter_Group_ID__c) != NULL);

					Boolean statusRequestToJoin = (collaborationGroupMap.get(Item.Chatter_Group_ID__c).CollaborationType == 'Private'
						&& item.Discoverable__c == true
						&& ModifyAllData == false
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

	private static Integer PAGE_SIZE = 6;
	public Integer startFrom { get { return startFrom == NULL ? 0 : startFrom; } set; }
	public Integer limitSize { get { return PAGE_SIZE; } }
	public String searchQuery { get; set; }

	public DiscoverResultClass getGroups() {
		String currentTab = currentFilter;
		if (!SObjectType.Community_Group_Control__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Group_Control__c);
		String gQuery = 'SELECT Id, Name, Chatter_Group_ID__c, Discoverable__c, Description__c, Type__c FROM Community_Group_Control__c';
		Boolean foundData = false;
		Set<String> filtredChatterGroupIds = new Set<String>();
		Set<String> alreadyJoinedGroups = new Set<String>();
		Set<String> matchedTagedGroups = new Set<String>();

		if (currentTab == 'all_groups' || currentTab == 'recommended_groups' || String.isBlank(currentTab)) {
			for (CollaborationGroup cgItem : [SELECT Id FROM CollaborationGroup WHERE NetworkId = :Network.getNetworkId()]) {
				filtredChatterGroupIds.add(cgItem.Id);
			}
			gQuery += ' WHERE Chatter_Group_ID__c IN :filtredChatterGroupIds';
			gQuery += CommunityUtils.isModifyAllData() ? '' : ' AND Discoverable__c = true';
			foundData = filtredChatterGroupIds.size() > 0;
		}

		if (currentTab == 'recommended_groups' && foundData) {
			if (!SObjectType.User.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.User);
			User currentUser = [SELECT ContactId, Community_Contact_ID__c FROM User WHERE Id = :UserInfo.getUserId()];
			String currentContactId = currentUser.ContactId == NULL ? currentUser.Community_Contact_ID__c : currentUser.ContactId;
			Set<Id> userTags = new Set<Id>();
			if (String.isNotBlank(currentContactId)) {
				String queryContactId = CommunityUtils.validateId(currentContactId);
				if (!SObjectType.Community_Profile_Tag__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Profile_Tag__c);
				for (Community_Profile_Tag__c cpt : [SELECT Community_Tag__c FROM Community_Profile_Tag__c WHERE Active__c = true AND Contact__c = :queryContactId]) {
					userTags.add(cpt.Community_Tag__c);
				}
			}
			if (userTags.size() > 0) {
				if (!SObjectType.Community_Group_Control_Tag__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Group_Control_Tag__c);
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
				filtredChatterGroupIds.add(cgmItem.CollaborationGroupId);
			}
			gQuery += ' WHERE Chatter_Group_ID__c IN :filtredChatterGroupIds';
			foundData = filtredChatterGroupIds.size() > 0;
		}

		DiscoverResultClass DiscoverResult;
		if (foundData) {
			if (String.isNotBlank(searchQuery)) {
				gQuery += ' AND Name LIKE \'%' + String.escapeSingleQuotes(searchQuery) + '%\'';
			}
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
				DiscoverResult.hasMore = allSize > endCopyInterval;
			}
		}

		if (!foundData){
			DiscoverResult = new DiscoverResultClass();
		}

		return DiscoverResult;
	}

	@RemoteAction
	public static CommunityUtils.GroupAction membershipGroup(String mc, String grId, String action) {
		return CommunitySearchController.membershipGroup(mc, grId, action);
	}

	public class DiscoverResultClass {
		public Integer totalRecords { get { return totalRecords == NULL ? 0 : totalRecords; } set; }
		public List<ChatterGroupDetail> Groups { get; set; }
		public Boolean hasMore { get { return hasMore == NULL ? false : hasMore; } set; }

		public DiscoverResultClass(Integer total, List<ChatterGroupDetail> groupsList) {
			totalRecords = total;
			Groups = groupsList;
		}

		public DiscoverResultClass() {}
	}

	public class ChatterGroupDetail {
		public Id GroupId { get; set; }
		public Id GroupControlId { get;set; }
		public String GroupName { get; set; }
		public String GroupDescription { get; set; }
		public String GroupPhotoUrl {
			get {
				return String.isBlank(GroupPhotoUrl) ? '/profilephoto/0F9/F' : GroupPhotoUrl.replace(Site.getBaseUrl(), '');
			}
			set;
		}
		public String CurrentMemberRole { get; set; }
		public Integer GroupMembersCount {get;set;}
		public Datetime GroupLastActivityDate { get; set; }
		public String GroupLastActivityDateFormatted {
			get {
				return GroupLastActivityDate == NULL ? '' : String.format('{0} at {1}',new List<String> {GroupLastActivityDate.format('MMMMM d, yyyy'),this.GroupLastActivityDate.format('HH:mm a')});
			}
		}
		public String NotAMemberStatus {get;set;}

		public ChatterGroupDetail(Community_Group_Control__c groupDetail) {
			this.GroupId = groupDetail.Chatter_Group_ID__c;
			this.GroupControlId = groupDetail.Id;
			this.GroupName = groupDetail.Name;
			this.GroupDescription = groupDetail.Description__c;
		}
	}
}
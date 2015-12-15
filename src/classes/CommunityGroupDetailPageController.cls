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

public with sharing class CommunityGroupDetailPageController {

	public Community_Group_Control__c control { get; set; }
	public CollaborationGroup chatterGroup { get; set; }

	public ConnectApi.GroupMembershipType groupRole { get; set; }
	private String initialRequestMember;

	public String groupRoleString {
		get {
			String groupRoleString = (groupRole != NULL) ? String.valueOf(groupRole).removeStart('Group') : '';
			System.Debug(groupRoleString);
			return groupRoleString;
		}
		set;
	}

	// CONSTRUCTOR
	public CommunityGroupDetailPageController() {
		control = CommunityGroupManageController.pullGroupControlRecord(true);
		if (control != NULL && control.Chatter_Group_ID__c != NULL) {
			if (!SObjectType.CollaborationGroup.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.CollaborationGroup);
			chatterGroup = [SELECT Id, FullPhotoUrl, CollaborationType FROM CollaborationGroup WHERE Id = :control.Chatter_Group_ID__c];
			groupRole = ConnectApi.ChatterGroups.getGroup(Network.getNetworkId(), chatterGroup.Id).MyRole;
		}
		initMembers();
		// check for single request
		try {
			String queryUserId = CommunityUtils.validateId(ApexPages.currentPage().getParameters().get('u'));
			if (String.isNotBlank(queryUserId)) {
				if (!SObjectType.User.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.User);
				initialRequestMember = [SELECT Name FROM User WHERE Id = :queryUserId].Name;
			}
		}
		catch (Exception e) {}
	}

	public Boolean getGroupEditable() {
		return groupRole == ConnectApi.GroupMembershipType.GroupOwner || groupRole == ConnectApi.GroupMembershipType.GroupManager || CommunityUtils.isShowGroupManagerUser(control.Chatter_Group_ID__c, true);
	}

	public Boolean memberMode { get { return memberMode == NULL ? false : memberMode; } set; }
	public Boolean requestMode { get { return requestMode == NULL ? false : requestMode; } set; }

	private void initMembers() {
		members = new CommunityGroupManageController.MemberPage((requestMode ? 'requests' : 'members'), (chatterGroup == NULL ? NULL : chatterGroup.Id), control);
	}

	public CommunityGroupManageController.MemberPage members { get; set; }

	public void switchToMemberMode() {
		memberMode = true;
		requestMode = NULL;
		initMembers();
	}

	public void switchToRequestMode() {
		memberMode = NULL;
		requestMode = true;
		initMembers();
		if (String.isNotBlank(initialRequestMember)) {
			members.query = initialRequestMember;
			initialRequestMember = NULL;
			members.init();
		}
	}

	public Boolean getHideFeedComponent() {
		return control.Type__c == 'Private' && (groupRole == ConnectApi.GroupMembershipType.NotAMember || groupRole == ConnectApi.GroupMembershipType.NotAMemberPrivateRequested) && 
				CommunityUtils.isViewAllData() == false && CommunityUtils.isModifyAllData() == false;
	}

	public String groupMode { get; set; }
	public PageReference performGroupMembershipAction() {
		PageReference pr;
		ConnectApi.GroupMembershipType oldGroupRole = groupRole;
		groupRole = CommunityUtils.membership(UserInfo.getUserId(), control.Id, groupMode);
		initMembers();
		if (groupRole != ConnectApi.GroupMembershipType.NotAMemberPrivateRequested) {
			pr = Page.CommunityGroupDetailPage;
			pr.getParameters().put('gr', chatterGroup.Id);
			pr.setRedirect(true);
		}
		return pr;
	}

	@RemoteAction
	public static String toggleSubscriber(String memberId) {
		String resultIcon = 'fa-check:' + Label.BTN_Following;
		if (!SObjectType.EntitySubscription.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.EntitySubscription);
		String queryMemberId = CommunityUtils.validateId(memberId);
		List<EntitySubscription> followings = [SELECT Id FROM EntitySubscription WHERE SubscriberId =:Userinfo.getUserId() AND ParentId = :queryMemberId LIMIT 1];
		if (!followings.isEmpty()) {
			ConnectApi.Chatter.deleteSubscription(Network.getNetworkId(), followings[0].Id);
			resultIcon = 'fa-plus-circle:' + Label.LBL_Follow;
		}
		else if (!Test.isRunningTest()) {
			ConnectApi.ChatterUsers.follow(Network.getNetworkId(),UserInfo.getUserId(), memberId);
		}
		//return resultIcon + ':' + memberId;
		return '';
	}

	public Boolean accepted { get; set; }
	public String requesterId { get; set; }
	public void performRequestAction() {
		CommunityUtils.membership(requesterId, String.valueOf(control.Id), (accepted == true ? '7' : '8'));
		accepted = NULL;
		requesterId = NULL;
		//initMembers();
		members.init();
	}

	public CommunityUtils.GroupAction getActionButton() {
		Boolean hasDirectJoinBtn = chatterGroup.CollaborationType == 'Public' || CommunityUtils.isModifyAllData();
		return CommunityUtils.getActionButton(groupRole, hasDirectJoinBtn);
	}

	public Schema.FieldSet getFieldset() {
		return SObjectType.Community_Group_Control__c.FieldSets.ViewGroup;
	}

	public List<GroupEvent> getEvents() {
		List<GroupEvent> resultList = new List<GroupEvent>();
		if (!SObjectType.Community_Event_Tag__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Event_Tag__c);
		for (Community_Event_Tag__c cet : [
						SELECT Community_Event__r.Id, Community_Event__r.Name__c, Community_Event__r.Start__c
						FROM Community_Event_Tag__c
						WHERE Community_Group_Control__c = :control.Id
						AND Community_Event__c != NULL
						AND Community_Event__r.Start__c >= TODAY
						ORDER BY Community_Event__r.Start__c ASC
							]) {
			resultList.add(new GroupEvent(cet.Community_Event__r));
		}
		/*for (Community_Events__c c : [Select Start__c, Name__c, Id From Community_Events__c LIMIT 10]) {
			resultList.add(new GroupEvent(c));
		}*/
		return resultList;
	}

	public Boolean showCreateEvent {
		get {
			return chatterGroup != NULL
					&& SObjectType.Community_Events__c.isCreateable()
						&& SObjectType.Community_Event_Tag__c.isCreateable()
						&& ((groupRole == ConnectApi.GroupMembershipType.GroupOwner || groupRole == ConnectApi.GroupMembershipType.GroupManager || groupRole == ConnectApi.GroupMembershipType.StandardMember)
							|| CommunityUtils.isModifyAllData());
		}
	}

	public String getUrlForCreateEvent() {
		return prepareUrl(Page.CommunityEventEdit.getUrl())
			+ '?gr=' + chatterGroup.Id + '&retURL='
			+ EncodingUtil.urlEncode(prepareUrl(Page.CommunityGroupDetailPage.getUrl()) + '?gr=' + chatterGroup.Id, 'UTF-8');
	}

	private String prepareUrl(String inUncouthUrl) {
		return String.isNotBlank(Site.getPathPrefix()) ? inUncouthUrl.replace('/apex/', Site.getPathPrefix() + '/') : inUncouthUrl;
	}

	public Integer getRequestCount() {
		return (groupRole == ConnectApi.GroupMembershipType.GroupOwner || groupRole == ConnectApi.GroupMembershipType.GroupManager)
				? CommunityUtils.getRequestJoinGroupCount(chatterGroup.Id) : 0;
	}

	public Boolean getShowPendingMembers() {
		return ApexPages.currentPage().getParameters().containsKey('pending');
	}

	public Boolean getRequiredTags() {
		Community_Settings__c cs = Community_Settings__c.getInstance();
		return cs != NULL && cs.Create_Group_Require_Tags__c == true;
	}

	public Integer getTagsCount() {
		Community_Settings__c cs = Community_Settings__c.getInstance();
		return (cs != NULL && cs.Create_Group_Max_Tags__c != NULL)
				? Integer.valueOf(cs.Create_Group_Max_Tags__c)
				: -1;
	}
	public Boolean showFilesSection {
		get {
			return Community_Settings__c.getInstance().Chatter_Action_Disable_Group_Files__c != true && (!(control.Type__c == 'Private' && 
				(groupRole == ConnectApi.GroupMembershipType.NotAMember || groupRole == ConnectApi.GroupMembershipType.NotAMemberPrivateRequested)) ||
				CommunityUtils.isModifyAllData() || CommunityUtils.isViewAllData());
		}
	}

	public CommunityGroupFilesController getFilesController() {
		CommunityGroupFilesController cgfc = new CommunityGroupFilesController();
		if (showFilesSection) {
			cgfc.parentId = chatterGroup.Id;
			cgfc.init();
		}
		return cgfc;
	}

	public class GroupEvent {
		public String id { get; set; }
		public String name { get; set; }
		public String ftime { get; set; }

		public GroupEvent(Community_Events__c ince) {
			id = ince.Id;
			name = ince.Name__c;
			ftime = ince.Start__c == NULL ? '' : ince.Start__c.format();
		}
	}
}

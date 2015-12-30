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

public with sharing class CommunityGroupManageController {

	public Community_Group_Control__c control { get;set; }
	public CollaborationGroup chatterGroup { get;set; }
	public Boolean tinyGroup { get;set; }
	public Boolean allOk { get;set; }

	public final static Integer PAGE_SIZE = 5;
	public Integer pageSize { get { return PAGE_SIZE; } }

	public Boolean editMode { get { return editMode == NULL ? false : editMode; } set; }

	public CommunityGroupManageController() {
		init();
	}

	private void init() {
		control = pullGroupControlRecord(true);
		allOk = control != NULL;
		if (allOk) {
			tinyGroup = control.Chatter_Group_ID__c == NULL;
			if (!tinyGroup) {
				if (!SObjectType.CollaborationGroup.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.CollaborationGroup);
				chatterGroup = [SELECT Id, FullPhotoUrl FROM CollaborationGroup WHERE Id = :control.Chatter_Group_ID__c];
				members = new MemberPage('members', chatterGroup.Id, control);
			}
			managers = new MemberPage('managersonly', (chatterGroup == NULL ? NULL : chatterGroup.Id), control);
		}
	}

	public static Community_Group_Control__c pullGroupControlRecord(Boolean useFieldSet) {
		Map<String, String> pageParams = ApexPages.currentPage().getParameters();
		String chatterGroupId = pageParams.containsKey('gr') ? pageParams.get('gr') : '';
		String groupControlId = pageParams.containsKey('gc') ? pageParams.get('gc') : '';
		return pullGroupControlRecord(useFieldSet, chatterGroupId, groupControlId);
	}

	public static Community_Group_Control__c pullGroupControlRecord(Boolean useFieldSet, String chatterGroupId, String groupControlId) {
		if (String.isNotBlank(chatterGroupId) || String.isNotBlank(groupControlId)) {
			Set<String> collectedFields = new Set<String> {'Id', 'Name', 'Chatter_Group_ID__c', 'Type__c', 'OwnerId', 'UserRecordAccess.HasEditAccess', 'UserRecordAccess.HasAllAccess'};
			if (useFieldSet) {
				String pp = CommunityUtils.getPackagePrefix();
				Boolean isPP = String.isNotBlank(pp);
				for (Schema.FieldSetMember f : SObjectType.Community_Group_Control__c.FieldSets.EditGroup.getFields()) {
					String tempFieldName = isPP ? f.getFieldPath().replace(pp,'') : f.getFieldPath();
					collectedFields.add(tempFieldName);
				}
				for (Schema.FieldSetMember f : SObjectType.Community_Group_Control__c.FieldSets.ViewGroup.getFields()) {
					String tempFieldName = isPP ? f.getFieldPath().replace(pp,'') : f.getFieldPath();
					collectedFields.add(tempFieldName);
				}
			}
			List<String> fieldList = new List<String>();
			fieldList.addAll(collectedFields);
			if (!SObjectType.Community_Group_Control__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Group_Control__c);
			String queryChatterGroupId = String.isNotBlank(chatterGroupId) ? String.escapeSingleQuotes(chatterGroupId) : '';
			String queryGroupControlId = String.isNotBlank(groupControlId) ? String.escapeSingleQuotes(groupControlId) : '';
			String mQuery = 'SELECT ' + String.join(fieldList, ', ') + ' FROM Community_Group_Control__c WHERE ';
			mQuery += String.isNotBlank(chatterGroupId) ? 'Chatter_Group_ID__c = :queryChatterGroupId' : 'Id = :queryGroupControlId';
			List<Community_Group_Control__c> cgcList = Database.query(mQuery);
			return cgcList.size() > 0 ? cgcList[0] : NULL;
		}
		return NULL;
	}

	public Schema.FieldSet getFieldset() {
		return SObjectType.Community_Group_Control__c.FieldSets.EditGroup;
	}

	public void editModeAction() {
		control = pullGroupControlRecord(true);
		editMode = true;
	}

	public void submitAction() {
		saveGroupTags();
		try {
			update control;
			control = pullGroupControlRecord(true);
			editMode = false;
		}
		catch (Exception e) {
			ApexPages.addMessages(e);
		}
	}

	public void cancelAction() {
		control = pullGroupControlRecord(true);
		editMode = false;
	}

	public Boolean renderCreateEvent {
		get {
			return tinyGroup == true && SObjectType.Community_Events__c.isCreateable() && SObjectType.Community_Event_Tag__c.isCreateable();
		}
	}

	public Statistic getStat() {
		Statistic sres = new Statistic();
		if (chatterGroup != NULL) {
			if (!SObjectType.CollaborationGroupMember.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.CollaborationGroupMember);
			sres.totalMembers = [SELECT COUNT() FROM CollaborationGroupMember WHERE CollaborationGroupId = :chatterGroup.Id];
			sres.newThisWeek = [SELECT COUNT() FROM CollaborationGroupMember WHERE CollaborationGroupId = :chatterGroup.Id AND CreatedDate = THIS_WEEK];
			sres.newLastMonth = [SELECT COUNT() FROM CollaborationGroupMember WHERE CollaborationGroupId = :chatterGroup.Id AND CreatedDate = LAST_MONTH];
			sres.overallActivity = CommunityHelperWithoutSharing.getOverallActivity(chatterGroup.Id);
			sres.postsThisWeek = CommunityHelperWithoutSharing.getPostsThisWeek(chatterGroup.Id);
			sres.postThisMonth = CommunityHelperWithoutSharing.getPostThisMonth(chatterGroup.Id);
		}
		return sres;
	}

	public Boolean getUserCanAccess() {
		return CommunityUtils.isShowGroupManagerUser(control.Chatter_Group_ID__c, true);
	}

	//ADD/REMOVE MEMBERS/MANAGERS

	public Boolean memberMode { get { return memberMode == NULL ? false : memberMode; } set; }
	public Boolean managerMode { get { return managerMode == NULL ? false : managerMode; } set; }
	public Boolean requestMode { get { return requestMode == NULL ? false : requestMode; } set; }
	public Boolean showOnlyMode { get { return showOnlyMode == NULL ? false : showOnlyMode; } set; }
	public Boolean changeOwnerMode { get { return changeOwnerMode == NULL ? false : changeOwnerMode; } set; }
	public MemberPage allusers { get;set; }

	public void msShow() {
		Id tempChGroup = chatterGroup == NULL ? NULL : chatterGroup.Id;
		String determineMode = managerMode ? (showOnlyMode ? 'managersonly' : 'managers') : (showOnlyMode ? 'members' : 'all');
		//String determineMode = managerMode ? (showOnlyMode ? 'managers' : 'members') : (showOnlyMode ? 'members' : 'all');
		determineMode = requestMode ? 'requests' : determineMode;
		allusers = new MemberPage(determineMode, tempChGroup, control);
	}

	public void msShowPlus() {
		changeOwnerMode = NULL;
		msShow();
	}

	public void msDone() {
		memberMode = NULL;
		managerMode = NULL;
		requestMode = NULL;
		allusers = NULL;
		changeOwnerMode = NULL;
		init();
	}

	public String ownerString { get; set; }
	public void changeOwner() {
		if (ownerString == 'start') {
			changeOwnerMode = true;
		}
		else if (ownerString == 'cancel') {
			changeOwnerMode = NULL;
		}
		else {
			changeOwnerMode = NULL;
			control.OwnerId = Id.valueOf(ownerString);
			CommunityAccess.UpdateWithoutSharing(
				control,
				'CommunityGroupManageController.cls [changeOwner]',
				new List<Schema.DescribeFieldResult> {
					Community_Group_Control__c.OwnerId.getDescribe()
				}
			);
			allusers.newOwner(control.OwnerId);
			msShow();
		}
		allusers.init();
	}

	private static Map<Integer, MembershipButton> NEW_BTN_MAP = new Map<Integer, MembershipButton> {
		1 => new MembershipButton('2', 'btn-u-blue', 'fa-check', Label.LBL_Member),
		2 => new MembershipButton('1', '', 'fa-plus-circle', Label.LBL_Add),
		3 => new MembershipButton('4', '', 'fa-star-half-o', Label.LBL_Manager),
		4 => new MembershipButton('3', 'btn-u-blue', 'fa-check', Label.LBL_Member)
	};

	@RemoteAction
	public static MembershipButton membership(String inUserId, String inGroupContolId, Integer inMode) {
		CommunityUtils.membership(inUserId, inGroupContolId, String.valueOf(inMode));
		MembershipButton btn = NEW_BTN_MAP.get(inMode);
		btn.userId = inUserId;
		return btn;
	}

	public String urlForGroupReturn {
		get {
			String chatterGroupId2 = CommunityUtils.validateId(ApexPages.currentPage().getParameters().get('gr'));
			String groupControlId2 = CommunityUtils.validateId(ApexPages.currentPage().getParameters().get('gc'));
			String resultUrl = prepareUrl(Page.CommunityGroupDetailPage.getUrl());
			if (String.isNotBlank(chatterGroupId2)) {
				resultUrl += '?gr=' + chatterGroupId2;
			}
			else if (String.isNotBlank(groupControlId2)) {
				resultUrl += '?gc=' + groupControlId2;
			}
			return resultUrl;
		}
	}

	public String urlForEvent {
		get {
			if (renderCreateEvent) {
				return prepareUrl(Page.CommunityEventEdit.getUrl())
						+ '?gr=' + chatterGroup.Id + '&retURL='
						+ EncodingUtil.urlEncode(prepareUrl(Page.CommunityGroupManager.getUrl()) + '?gr=' + chatterGroup.Id, 'UTF-8');
			}
			else {
				return '';
			}
		}
	}

	private String prepareUrl(String inUncouthUrl) {
		return String.isNotBlank(Site.getPathPrefix()) ? inUncouthUrl.replace('/apex/', Site.getPathPrefix() + '/') : inUncouthUrl;
	}

	public String groupImageUrl {
		get {
			return chatterGroup.FullPhotoUrl == NULL ? CommunityUtils.checkUrl('/profilephoto/0F9/F') : chatterGroup.FullPhotoUrl;
		}
	}

	public Integer getRequestCount() {
		return CommunityUtils.getRequestJoinGroupCount(chatterGroup.Id);
	}

	public String getMemberModalTitle() {
		String result = managerMode ? Label.LBL_Update_Managers : (requestMode ? Label.LBL_PendingRequestsManager_Title : Label.LBL_Add_Remove_Members);
		return changeOwnerMode ? Label.LBL_Assign_New_Owner : result;
	}

	public Boolean getShowChangeOwnerLink() {
		return managerMode && !changeOwnerMode && (control.UserRecordAccess.HasAllAccess == true || (control.OwnerId == UserInfo.getUserId() && control.UserRecordAccess.HasEditAccess == true) || CommunityUtils.isModifyAllData());
	}

	// MEMBER HANDLER CLASS
	private final static Integer MEMBER_PAGE_SIZE = 10;
	public MemberPage members { get;set; }
	public MemberPage managers { get;set; }
	public Boolean accepted { get; set; }
	public String requesterId { get; set; }
	public void performRequestAction() {
		CommunityUtils.membership(requesterId, String.valueOf(control.Id), (accepted == true ? '7' : '8'));
		accepted = NULL;
		requesterId = NULL;
		allusers.init();
	}

	public class MemberPage {
		transient public List<Member> users { get;set; }
		public Integer pageNumber { get;set; }
		public Integer totalPages { get;set; }
		public Integer totalUsers { get;set; }
		public Boolean hasNext { get;set; }
		public Boolean hasPrevious { get;set; }
		public Boolean showPagination { get;set; }
		public String query { get;set; }
		public Integer columnSort { get {return columnSort == NULL ? 1 : columnSort;}set; }
		public Boolean ascSort { get {return ascSort == NULL ? true : ascSort;}set; }
		private Integer prevCol;
		private String mode;
		private Id gIdChatter;
		private Id gIdControl;
		private Id ownerControlId;

		public MemberPage(String inMode, Id inChId, Community_Group_Control__c inCgc) {
			mode = inMode;
			gIdChatter = inChId;
			gIdControl = inCgc.Id;
			ownerControlId = inCgc.OwnerId;
			init();
		}

		public void init() {
			Boolean allMode = mode == 'all';
			Boolean membersMode = mode == 'members';
			Boolean managersMode = mode == 'managers' || mode == 'managersonly';
			Boolean requestsMode = mode == 'requests';
			//Get active network member

			List<User> allUsers;
			
			String queryGIdChatter = CommunityUtils.validateId(gIdChatter);
			String queryGIdControl = CommunityUtils.validateId(gIdControl);
			if (allMode) { 
				List<String> orderList = new List<String> {'', 'Name'};
				String columnSortStr = (columnSort > 0) ? orderList[columnSort] : '';
				allUsers = CommunityHelperWithoutSharing.getCommunityUsers(query, 50000, new List<String>{'ContactId', 'City', 'Country', 'Community_Contact_ID__c', 'SmallPhotoUrl'}, columnSortStr , ascSort);
			}
			else if (membersMode) {
				if (!SObjectType.CollaborationGroupMember.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.CollaborationGroupMember);
				String mQuery2 = 'SELECT MemberId, Member.Name, Member.Id, Member.ContactId, Member.City, Member.Country, Member.Community_Contact_ID__c, Member.SmallPhotoUrl FROM CollaborationGroupMember';
				mQuery2 += ' WHERE CollaborationGroupId =\'' + queryGIdChatter + '\' AND Member.isActive = true';
				mQuery2 = checkQuery(mQuery2, 'Member.');
				if (columnSort > 0) {
					List<String> orderList = new List<String> {'','Member.Name'};
					mQuery2 += ' ORDER BY ' + orderList[columnSort] + (ascSort ? ' ASC' : ' DESC');
				}
				allUsers = new List<User>();
				for (CollaborationGroupMember mu : Database.query(mQuery2)) {
					allUsers.add(mu.Member);
				}
			}
			else if (managersMode) {
				if (!SObjectType.Community_Group_Manager__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Group_Manager__c);
				String mQuery3 = 'SELECT MemberId, Member.Name, Member.Id, Member.ContactId, Member.City, Member.Country, Member.Community_Contact_ID__c, Member.SmallPhotoUrl FROM CollaborationGroupMember';
				mQuery3 += ' WHERE CollaborationGroupId =\'' + gIdChatter + '\' AND Member.isActive = true';
				mQuery3 = checkQuery(mQuery3, 'Member.');
				if (columnSort > 0) {
					List<String> orderList = new List<String> {'','Member.Name'};
					mQuery3 += ' ORDER BY ' + orderList[columnSort] + (ascSort ? ' ASC' : ' DESC');
				}
				Set<Id> colMemberIds = new Set<Id>();
				allUsers = new List<User>();
				if (mode != 'managersonly') {
					for (CollaborationGroupMember mu : Database.query(mQuery3)) {
						allUsers.add(mu.Member);
						colMemberIds.add(mu.Member.Id);
					}
				}
				mQuery3 = 'SELECT Group_Manager_User__c, Group_Manager_User__r.Id, Group_Manager_User__r.Name, Group_Manager_User__r.ContactId, Group_Manager_User__r.City, Group_Manager_User__r.Country, Group_Manager_User__r.Community_Contact_ID__c, Group_Manager_User__r.SmallPhotoUrl FROM Community_Group_Manager__c';
				mQuery3 += ' WHERE Group_Manager_User__r.Id NOT IN :colMemberIds AND Group_Control__c =\'' + gIdControl + '\'';
				mQuery3 = checkQuery(mQuery3, 'Group_Manager_User__r.');
				if (columnSort > 0) {
					List<String> orderList = new List<String> {'','Group_Manager_User__r.Name'};
					mQuery3 += ' ORDER BY ' + orderList[columnSort] + (ascSort ? ' ASC' : ' DESC');
				}
				for (Community_Group_Manager__c cgm : Database.query(mQuery3)) {
					allUsers.add(cgm.Group_Manager_User__r);
				}
			}
			else if (requestsMode) {
				Set<Id> initialFoundUsers = new Set<Id>();
				if (!SObjectType.CollaborationGroupMemberRequest.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.CollaborationGroupMemberRequest);
				for (CollaborationGroupMemberRequest cgmrItem : [SELECT RequesterId FROM CollaborationGroupMemberRequest WHERE CollaborationGroupId =:queryGIdChatter AND Status = 'Pending']) {
					initialFoundUsers.add(cgmrItem.RequesterId);
				}
				allUsers = new List<User>();
				if (initialFoundUsers.size() > 0) {
					if (!SObjectType.User.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.User);
					String mQuery4 = 'SELECT Id, Name, ContactId, City, Country, Community_Contact_ID__c, SmallPhotoUrl FROM User WHERE Id IN :initialFoundUsers';
					mQuery4 = checkQuery(mQuery4, '');
					if (columnSort > 0) {
						List<String> orderList = new List<String> {'','Name'};
						mQuery4 += ' ORDER BY ' + orderList[columnSort] + (ascSort ? ' ASC' : ' DESC');
					}
					allUsers = Database.query(mQuery4);
				}
			}
			Integer mlSize = allUsers.size();
			Integer memberPageSize = MEMBER_PAGE_SIZE;
			totalPages = mlSize / memberPageSize + ((Math.mod(mlSize, memberPageSize) == 0) ? 0 : 1);
			totalPages = totalPages == 0 ? 1 : totalPages;
			showPagination = totalPages > 1;
			pageNumber = pageNumber == NULL ? 1 : (pageNumber > totalPages ? totalPages : pageNumber);
			hasNext = pageNumber < totalPages;
			hasPrevious = pageNumber > 1;
			Integer startCopyInterval = pageNumber > 1 ? ((pageNumber - 1) * memberPageSize) : 0;
			Integer endCopyInterval = (mlSize <= (startCopyInterval + memberPageSize)) ? mlSize : (startCopyInterval + memberPageSize);
			Map<Id, Id> userByContactIdsMap = new Map<Id, Id>();
			Set<Id> usersIds = new Set<Id>();
			for (Integer ii = startCopyInterval; ii < endCopyInterval; ii++) {
				usersIds.add(allUsers[ii].Id);
				try {
					userByContactIdsMap.put(Id.valueOf(allUsers[ii].ContactId != NULL ? allUsers[ii].ContactId : allUsers[ii].Community_Contact_ID__c), allUsers[ii].Id);
				}
				catch(Exception e) {}
			}
			Map<Id, String> roleMap = new Map<Id, String>();
			if (!SObjectType.Contact.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Contact);
			for (Contact cItem : [SELECT Id, Primary_Role__c FROM Contact WHERE Id IN :userByContactIdsMap.keySet()]) {
				roleMap.put(userByContactIdsMap.get(cItem.Id), cItem.Primary_Role__c);
			}
			Set<Id> membersIds = new Set<Id>();
			if (!SObjectType.CollaborationGroupMember.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.CollaborationGroupMember);
			for (CollaborationGroupMember mu2 : [SELECT MemberId FROM CollaborationGroupMember WHERE CollaborationGroupId = :queryGIdChatter AND MemberId IN :usersIds]) {
				membersIds.add(mu2.MemberId);
			}
			Set<Id> managersIds = new Set<Id>();
			if (!SObjectType.Community_Group_Manager__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Group_Manager__c);
			for (Community_Group_Manager__c cgm2 : [SELECT Group_Manager_User__c FROM Community_Group_Manager__c WHERE Group_Control__c = :queryGIdControl AND Group_Manager_User__c IN :usersIds]) {
				managersIds.add(cgm2.Group_Manager_User__c);
			}
			Set<Id> subscribedToUsers = new Set<Id>();
			if (membersMode) {
				if (!SObjectType.EntitySubscription.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.EntitySubscription);
				for (EntitySubscription es : [SELECT Id, ParentId FROM EntitySubscription WHERE SubscriberId =:Userinfo.getUserId() AND ParentId IN :usersIds LIMIT 500]) {
					subscribedToUsers.add(es.ParentId);
				}
			}
			Set<Id> activeNMs = new Set<Id>();
			if (managersMode) {
				for (NetworkMember nm: [SELECT Id, MemberId FROM NetworkMember WHERE Member.isActive = true AND MemberId IN :usersIds AND NetworkId = :Network.getNetworkId()]) {
					activeNMs.add(nm.MemberId);
				}
			}

			users = new List<Member>();
			for (Integer jj = startCopyInterval; jj < endCopyInterval; jj++) {
				Member nm = new Member(allUsers[jj], membersIds.contains(allUsers[jj].Id), managersIds.contains(allUsers[jj].Id), roleMap.get(allUsers[jj].Id), ownerControlId);
				nm.city = allUsers[jj].City;
				nm.country = allUsers[jj].Country;
				nm.follow = subscribedToUsers.contains(allUsers[jj].Id);
				nm.available = managersMode ? activeNMs.contains(allUsers[jj].Id) : true;
				users.add(nm);
			}
			totalUsers = allUsers.size();
		}

		private String checkQuery(String instr, String inq) {
			if (String.isNotBlank(query)) {
				String escapedQuery = String.escapeSingleQuotes(query);
				instr += ' AND (' + inq + 'FirstName LIKE \'' + escapedQuery + '%\'';
				instr += ' OR ' + inq + 'LastName LIKE \'' + escapedQuery + '%\'';
				instr += ' OR ' + inq + 'Name LIKE \'' + escapedQuery + '%\')';
			}
			return instr;
		}

		public void column() {
			ascSort = (prevCol != NULL && columnSort != prevCol) ? true : !ascSort;
			prevCol = columnSort;
			init();
		}

		public void nextPage() {
			pageNumber++;
			init();
		}

		public void lastPage() {
			pageNumber = totalPages;
			init();
		}

		public void previousPage() {
			pageNumber--;
			init();
		}

		public void firstPage() {
			pageNumber = 1;
			init();
		}

		public void newOwner(Id inOid) {
			ownerControlId = inOid;
		}
	}

	public class Member {
		public String name { get;set; }
		public String id { get;set; }
		public String role { get;set; }
		public String photourl { get;set; }
		public String city { get;set; }
		public String country { get;set; }
		public Boolean member { get;set; }
		public Boolean manager { get;set; }
		public Boolean owner { get;set; }
		public Boolean follow { get; set; }
		public Boolean available { get; set; }


		public Member(User inU, Boolean inMember, Boolean inManager, String inRole, Id inOwnerId) {
			name = inU.Name;
			id = inU.Id;
			owner = inOwnerId == inU.Id;
			role = inRole;
			photourl = inU.SmallPhotoUrl;
			member = inMember;
			manager = inManager;
		}
	}

	public class MembershipButton {
		public String userId { get;set; }
		public String toogleMode { get;set; }
		public String styleClass { get;set; }
		public String icon { get;set; }
		public String label { get;set; }

		public MembershipButton(String inToogleMode, String inStyleClass, String inIcon, String inLabel) {
			toogleMode = inToogleMode;
			styleClass = inStyleClass;
			icon = inIcon;
			label = inLabel;
		}
	}

	//getTagsCount
	public Boolean getRequiredTags() {
		Community_Settings__c cs = Community_Settings__c.getInstance();
		return cs != NULL && cs.Create_Group_Require_Tags__c == true;
	}
	
	public Integer getTagsCount() {
		Community_Settings__c cs = Community_Settings__c.getInstance();
		return (cs != NULL && cs.Create_Group_Max_Tags__c != NULL) ? Integer.valueOf(cs.Create_Group_Max_Tags__c) : -1;
	}
	
	
	private final String TAGS_INPUT_NAME = 'tags';
	
	public void saveGroupTags () {
		String tagsIdsString = ApexPages.currentPage().getParameters().get(TAGS_INPUT_NAME);
		CommunityTagSelectorController ctsc = new CommunityTagSelectorController();
		ctsc.objectId = control.Id;
		ctsc.objectType = Community_Group_Control_Tag__c.getSObjectType().getDescribe().getName();
		ctsc.filterName = Community_Group_Control_Tag__c.Group_Control__c.getDescribe().getName();
		ctsc.saveTags(tagsIdsString);
	}
	
	public class Statistic {
		public Integer totalMembers { get; set; }
		public Integer newThisWeek { get; set; }
		public Integer newLastMonth { get; set; }
		public Integer overallActivity { get; set; }
		public Integer postsThisWeek { get; set; }
		public Integer postThisMonth { get; set; }

		public Statistic() {
			totalMembers = 0;
			newThisWeek = 0;
			newLastMonth = 0;
			overallActivity = 0;
			postsThisWeek = 0;
			postThisMonth = 0;
		}
	}

}
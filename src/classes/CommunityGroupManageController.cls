public without sharing class CommunityGroupManageController {

	public Community_Group_Control__c control { get;set; }
	public CollaborationGroup chatterGroup { get;set; }
	public Boolean tinyGroup { get;set; }
	public Boolean allOk { get;set; }
	public String newComment { get;set; }

	public String updateMemberId {get; set;}
	public String updateMemberFieldName {get; set;}
	public String updateMemberFieldValue {get; set;}

	public final static Integer PAGE_SIZE = 5;
	public Integer pageSize { get { return PAGE_SIZE; } }

	public Boolean editMode { get { return editMode == NULL ? false : editMode; } set; }

	public CommunityGroupManageController() {
		init();
	}

	private void init() {
		//control = pullGroupControlRecord(false);
		control = pullGroupControlRecord(true);

		allOk = control != NULL;
		if (allOk) {
			tinyGroup = control.Chatter_Group_ID__c == NULL;
			if (!tinyGroup) {
				chatterGroup = [SELECT Id, FullPhotoUrl FROM CollaborationGroup WHERE Id = :control.Chatter_Group_ID__c];
				members = new MemberPage('members', chatterGroup.Id, control);
			}
			managers = new MemberPage('managers', (chatterGroup == NULL ? NULL : chatterGroup.Id), control);
		}

		//editMode = true;
	}

	public static Community_Group_Control__c pullGroupControlRecord(Boolean useFieldSet) {
		//useFieldSet = true; //hardcode - 
		String chatterGroupId = ApexPages.currentPage().getParameters().get('gr');
		String groupControlId = ApexPages.currentPage().getParameters().get('gc');
		if (String.isNotBlank(chatterGroupId) || String.isNotBlank(groupControlId)) {
			Set<String> collectedFields = new Set<String> {'Id', 'Name', 'Chatter_Group_ID__c', 'Type__c', 'OwnerId'};
			if (useFieldSet) {
				String pp = CommunityUtils.getPackagePrefix();
				Boolean isPP = String.isNotBlank(pp);
				for (Schema.FieldSetMember f : SObjectType.Community_Group_Control__c.FieldSets.EditGroup.getFields()) {
					String tempFieldName = isPP ? f.getFieldPath().replace(pp,'') : f.getFieldPath();
					collectedFields.add(tempFieldName);
				}
			}
			List<String> fieldList = new List<String>();
			fieldList.addAll(collectedFields);
			String mQuery = 'SELECT ' + String.join(fieldList, ', ') + ' FROM Community_Group_Control__c WHERE ';
			mQuery += String.isNotBlank(chatterGroupId) ? 'Chatter_Group_ID__c = :chatterGroupId' : 'Id = :groupControlId';
			List<Community_Group_Control__c> cgcList = Database.query(mQuery);
			return cgcList.size() > 0 ? cgcList[0] : NULL;
		}
		return NULL;
	}

	public void editModeAction() {
		control = pullGroupControlRecord(true);
		editMode = true;
	}

	public void submitAction() {
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
			sres.totalMembers = [SELECT COUNT() FROM CollaborationGroupMember WHERE CollaborationGroupId = :chatterGroup.Id];
			sres.newThisWeek = [SELECT COUNT() FROM CollaborationGroupMember WHERE CollaborationGroupId = :chatterGroup.Id AND CreatedDate = THIS_WEEK];
			sres.newLastMonth = [SELECT COUNT() FROM CollaborationGroupMember WHERE CollaborationGroupId = :chatterGroup.Id AND CreatedDate = LAST_MONTH];
			sres.overallActivity = [SELECT COUNT() FROM FeedItem WHERE ParentId = :chatterGroup.Id];
			sres.postsThisWeek = [SELECT COUNT() FROM FeedItem WHERE ParentId = :chatterGroup.Id AND CreatedDate = THIS_WEEK];
			sres.postThisMonth = [SELECT COUNT() FROM FeedItem WHERE ParentId = :chatterGroup.Id AND CreatedDate = THIS_MONTH];
		}
		return sres;
	}

	public Boolean getUserCanAccess() {
		Integer userHasCGM = [SELECT COUNT() FROM Community_Group_Manager__c WHERE Group_Manager_User__c =:UserInfo.getUserId() AND Group_Control__c =:control.Id];
		return userHasCGM > 0;
	}

	//ADD/REMOVE MEMBERS/MANAGERS

	public Boolean memberMode { get { return memberMode == NULL ? false : memberMode; } set; }
	public Boolean managerMode { get { return managerMode == NULL ? false : managerMode; } set; }
	public Boolean requestMode { get { return requestMode == NULL ? false : requestMode; } set; }
	public Boolean showOnlyMode { get { return showOnlyMode == NULL ? false : showOnlyMode; } set; }
	public MemberPage allusers { get;set; }

	public void msShow() {
		Id tempChGroup = chatterGroup == NULL ? NULL : chatterGroup.Id;
		String determineMode = managerMode ? (showOnlyMode ? 'managers' : 'members') : (showOnlyMode ? 'members' : 'all');
		determineMode = requestMode ? 'requests' : determineMode;
		allusers = new MemberPage(determineMode, tempChGroup, control);
	}

	public void msDone() {
		memberMode = NULL;
		managerMode = NULL;
		requestMode = NULL;
		allusers = NULL;
		init();
	}

	private static Map<Integer,String> BTN_MAP = new Map<Integer,String> {
		1 => '2:;: btn-u-blue:;:fa-check:;:' + Label.LBL_Member,
		2 => '1:;: :;:fa-plus-circle:;:' +Label.LBL_Add,
		3 => '4:;: :;:fa-star-half-o:;:' + Label.LBL_Manager,
		4 => '3:;: btn-u-blue:;:fa-check:;:' + Label.LBL_Member/*,
		7 => '2:;: btn-u-blue:;:fa-check:;:' + Label.LBL_Member,
		8 => '1:;: :;:fa-plus-circle:;:' +Label.LBL_Add*/
	};

	@RemoteAction
	public static String membership(String inUserId, String inGroupContolId, Integer inMode) {
		CommunityUtils.membership(inUserId, inGroupContolId, String.valueOf(inMode));
		String resultHtml;
		List<String> parts = BTN_MAP.get(inMode).split(':;:');
		resultHtml = '<button class="btn-u' + parts[1] + '" onclick="msproc(' + parts[0] + ',\'' + inUserId + '\');return false;">';
		resultHtml += '<i class="fa ' + parts[2] + '"></i>&nbsp;' + parts[3] + '</button>';
		return resultHtml + '-;-' + inUserId;
	}

	public String urlForGroupReturn {
		get {
			String chatterGroupId2 = ApexPages.currentPage().getParameters().get('gr');
			String groupControlId2 = ApexPages.currentPage().getParameters().get('gc');
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
		return managerMode ? Label.LBL_Update_Managers : (requestMode ? Label.LBL_PendingRequestsManager_Title : Label.LBL_Add_Remove_Members);
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
		//msShow();
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
			Boolean managersMode = mode == 'managers';
			Boolean requestsMode = mode == 'requests';
			List<User> allUsers;
			if (allMode) {
				String mQuery = 'SELECT Id, Name, ContactId, City, Country, Community_Contact_ID__c, SmallPhotoUrl FROM User WHERE (ContactId != NULL OR Community_Contact_ID__c != NULL) AND isActive = true';
				mQuery = checkQuery(mQuery, '');
				if (columnSort > 0) {
					List<String> orderList = new List<String> {'','Name'};
					mQuery += ' ORDER BY ' + orderList[columnSort] + (ascSort ? ' ASC' : ' DESC');
				}
				allUsers = Database.query(mQuery);
			}
			else if (membersMode) {
				String mQuery2 = 'SELECT MemberId, Member.Name, Member.Id, Member.ContactId, Member.City, Member.Country, Member.Community_Contact_ID__c, Member.SmallPhotoUrl FROM CollaborationGroupMember';
				mQuery2 += ' WHERE CollaborationGroupId =\'' + gIdChatter + '\' AND (Member.ContactId != NULL OR Member.Community_Contact_ID__c != NULL) AND Member.isActive = true';
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
				String mQuery3 = 'SELECT Group_Manager_User__c, Group_Manager_User__r.Id, Group_Manager_User__r.Name, Group_Manager_User__r.ContactId, Group_Manager_User__r.City, Group_Manager_User__r.Country, Group_Manager_User__r.Community_Contact_ID__c, Group_Manager_User__r.SmallPhotoUrl FROM Community_Group_Manager__c';
				mQuery3 += ' WHERE Group_Control__c =\'' + gIdControl + '\' AND (Group_Manager_User__r.ContactId != NULL OR Group_Manager_User__r.Community_Contact_ID__c != NULL) AND Group_Manager_User__r.isActive = true';
				mQuery3 = checkQuery(mQuery3, 'Group_Manager_User__r.');
				if (columnSort > 0) {
					List<String> orderList = new List<String> {'','Group_Manager_User__r.Name'};
					mQuery3 += ' ORDER BY ' + orderList[columnSort] + (ascSort ? ' ASC' : ' DESC');
				}
				allUsers = new List<User>();
				for (Community_Group_Manager__c cgm : Database.query(mQuery3)) {
					allUsers.add(cgm.Group_Manager_User__r);
				}
			}
			else if (requestsMode) {
				Set<Id> initialFoundUsers = new Set<Id>();
				for (CollaborationGroupMemberRequest cgmrItem : [SELECT RequesterId FROM CollaborationGroupMemberRequest WHERE CollaborationGroupId =:gIdChatter AND Status = 'Pending']) {
					initialFoundUsers.add(cgmrItem.RequesterId);
				}
				allUsers = new List<User>();
				if (initialFoundUsers.size() > 0) {
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
			for (Contact cItem : [SELECT Id, Primary_Role__c FROM Contact WHERE Id IN :userByContactIdsMap.keySet()]) {
				roleMap.put(userByContactIdsMap.get(cItem.Id), cItem.Primary_Role__c);
			}
			Set<Id> membersIds = new Set<Id>();
			for (CollaborationGroupMember mu2 : [SELECT MemberId FROM CollaborationGroupMember WHERE CollaborationGroupId = :gIdChatter AND MemberId IN :userByContactIdsMap.values()]) {
				membersIds.add(mu2.MemberId);
			}
			Set<Id> managersIds = new Set<Id>();
			for (Community_Group_Manager__c cgm2 : [SELECT Group_Manager_User__c FROM Community_Group_Manager__c WHERE Group_Control__c = :gIdControl AND Group_Manager_User__c IN :userByContactIdsMap.values()]) {
				managersIds.add(cgm2.Group_Manager_User__c);
			}
			Set<Id> subscribedToUsers = new Set<Id>();
			if (membersMode) {
				for (EntitySubscription es : [SELECT Id, ParentId FROM EntitySubscription WHERE SubscriberId =:Userinfo.getUserId() AND ParentId IN :usersIds LIMIT 500]) {
					subscribedToUsers.add(es.ParentId);
				}
			}
			users = new List<Member>();
			for (Integer jj = startCopyInterval; jj < endCopyInterval; jj++) {
				Member nm = new Member(allUsers[jj], membersIds.contains(allUsers[jj].Id), managersIds.contains(allUsers[jj].Id), roleMap.get(allUsers[jj].Id), ownerControlId);
				nm.city = allUsers[jj].City;
				nm.country = allUsers[jj].Country;
				nm.follow = subscribedToUsers.contains(allUsers[jj].Id);
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
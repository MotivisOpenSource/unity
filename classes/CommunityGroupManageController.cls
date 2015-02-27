public without sharing class CommunityGroupManageController extends CommunityGroupsBase {

	//public ChatterGroupDetail CurrentGroup { get; set; }
	public Community_Group_Control__c control { get;set; }
	public CollaborationGroup chatterGroup { get;set; }
	public Boolean tinyGroup { get;set; }
	public Boolean allOk { get;set; }
	public String newComment { get;set; }
	public transient Boolean showFeed { get;set; }

	//public String currentAddMemberId { get; set; }
	//public String currentAddManagerId {get; set;}
	//public String currentRemoveManagerId {get; set;}
	//public String currentRemoveMemberId {get; set;}

	public String updateMemberId {get; set;}
	public String updateMemberFieldName {get; set;}
	public String updateMemberFieldValue {get; set;}

	public final static Integer PAGE_SIZE = 5;
	public Integer pageSize { get { return PAGE_SIZE; } }

	public transient ChatterWrapperPage messagesPage { get;set; }
	public Boolean editMode { get { return editMode == NULL ? false : editMode; } set; }

	private final String CurrentCommunityId = getCurrentCommunityId();

	public String SitePrefix {
		get {
			if (this.SitePrefix == NULL) {
				this.SitePrefix = Site.getPathPrefix();
			}
			return this.SitePrefix;
		}
		private set;
	}

	public CommunityGroupManageController() {
		init();
	}

	private void init() {
		control = pullGroupControlRecord(false);
		allOk = control != NULL;
		if (allOk) {
			tinyGroup = control.Chatter_Group_ID__c == NULL;
			initFeeds();
			if (!tinyGroup) {
				chatterGroup = [SELECT Id, FullPhotoUrl FROM CollaborationGroup WHERE Id = :control.Chatter_Group_ID__c];
				members = new MemberPage('members', chatterGroup.Id, control);
			}
			managers = new MemberPage('managers', (chatterGroup == NULL ? NULL : chatterGroup.Id), control);
		}

		//feed
		showFeed = true;
		editMode = true;
	}

	public static Community_Group_Control__c pullGroupControlRecord(Boolean useFieldSet) {
		useFieldSet = true; //hardcode - 
		String chatterGroupId = ApexPages.currentPage().getParameters().get('g');
		String groupControlId = ApexPages.currentPage().getParameters().get('gc');
		if (String.isNotBlank(chatterGroupId) || String.isNotBlank(groupControlId)) {
			Set<String> collectedFields = new Set<String> {'Id', 'Name', 'Chatter_Group_ID__c', 'Type__c', 'Image_Path__c', 'OwnerId'};
			if (useFieldSet) {
				for (Schema.FieldSetMember f : SObjectType.Community_Group_Control__c.FieldSets.EditGroup.getFields()) {
					collectedFields.add(f.getFieldPath());
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
		update control;
		control = pullGroupControlRecord(false);
		editMode = false;
	}

	public void cancelAction() {
		control = pullGroupControlRecord(false);
		editMode = false;
	}


	//public PageReference addMember() {
	//	System.debug('addMember');
	//	System.debug('chatterGroup.Id: ' + chatterGroup.Id);
	//	System.debug('currentAddMemberId: ' + currentAddMemberId);
	//	ConnectApi.ChatterGroups.addMember(CurrentCommunityId, chatterGroup.Id, currentAddMemberId);
	//	membership(currentAddMemberId, control.Id, '1');
	//	return null;
	//}
	//public PageReference removeMember() {
	//	System.debug('removeMember');
	//	System.debug('chatterGroup.Id: ' + chatterGroup.Id);
	//	System.debug('currentRemoveMemberId: ' + currentRemoveMemberId);
	//	ConnectApi.ChatterGroups.deleteMember(chatterGroup.Id, currentRemoveMemberId);
	//	membership(currentRemoveMemberId, control.Id, '2');
	//	return null;
	//}
	//public PageReference addManager() {
	//	System.debug('addManager');
	//	System.debug('chatterGroup.Id: ' + chatterGroup.Id);
	//	System.debug('currentAddManagerId: ' + currentAddManagerId);
	//	ConnectApi.ChatterGroups.updateGroupMember(chatterGroup.Id, currentAddManagerId, ConnectApi.GroupMembershipType.GroupManager);
	//	membership(currentAddManagerId, control.Id, '3');
	//	return null;
	//}
	//public PageReference removeManager() {
	//	System.debug('removeManager');
	//	System.debug('chatterGroup.Id: ' + chatterGroup.Id);
	//	System.debug('currentRemoveManagerId: ' + currentRemoveManagerId);
	//	ConnectApi.ChatterGroups.updateGroupMember(chatterGroup.Id, currentRemoveManagerId, ConnectApi.GroupMembershipType.StandardMember);
	//	membership(currentRemoveManagerId, control.Id, '4');
	//	return null;
	//}

	public Boolean renderCreateEvent {
		get {
			return tinyGroup == true && SObjectType.Community_Events__c.isCreateable() && SObjectType.Community_Event_Tag__c.isCreateable();
		}
	}

	//ADD/REMOVE MEMBERS/MANAGERS

	public Boolean memberMode { get { return memberMode == NULL ? false : memberMode; } set; }
	public Boolean managerMode { get { return managerMode == NULL ? false : managerMode; } set; }
	public MemberPage allusers { get;set; }

	public void msShow() {
		Id tempChGroup = chatterGroup == NULL ? NULL : chatterGroup.Id;
		//allusers = new MemberPage(managerMode ? 'members' : 'all', tempChGroup, control);
		allusers = new MemberPage('all', tempChGroup, control);

	}

	public void msDone() {
		memberMode = NULL;
		managerMode = NULL;
		allusers = NULL;
		init();
	}

	/*
		inUserId - user to proccess
		inGroupContolId - group control to reference
		inMode:
			1 - add member
			2 - remove member©
			3 - add manager
			4 - remove manager
	*/
	@RemoteAction
	public static String membership(String inUserId, String inGroupContolId, String inMode) {
		Integer inmm = Integer.valueOf(inMode);
		Community_Group_Control__c cgc = [SELECT Id, Chatter_Group_ID__c FROM Community_Group_Control__c WHERE Id =:inGroupContolId];
		if (inmm < 3) {
			List<CollaborationGroupMember> cgmList = [SELECT Id FROM CollaborationGroupMember WHERE MemberId =:inUserId AND CollaborationGroupId =:cgc.Chatter_Group_ID__c];
			if (inmm == 2) {
				delete cgmList;
			}
			else if (cgmList.size() == 0){
				insert new CollaborationGroupMember(MemberId = inUserId, CollaborationGroupId = cgc.Chatter_Group_ID__c);
			}
		}
		else {
			List<Community_Group_Membership__c> cgmList2 = [SELECT Id FROM Community_Group_Membership__c WHERE Group_Membership_User__c =:inUserId AND Group_Control__c =:cgc.Id];
			List<EntitySubscription> esList2 = [SELECT Id FROM EntitySubscription WHERE ParentId = :cgc.Id AND SubscriberId = :inUserId];
			if (inmm == 4) {
				delete cgmList2;
				delete esList2;
			}
			else {
				if (cgmList2.size() == 0) {
					insert new Community_Group_Membership__c(Group_Membership_User__c = inUserId, Group_Control__c = cgc.Id);
				}
				if (esList2.size() == 0) {
					insert new EntitySubscription(ParentId = cgc.Id, SubscriberId = inUserId, NetworkId = Network.getNetworkId());
				}
			}
		}
		return 'ok:' + inMode + ':' + inUserId;
	}

	public String urlForGroupReturn {
		get {
			String chatterGroupId2 = ApexPages.currentPage().getParameters().get('g');
			String groupControlId2 = ApexPages.currentPage().getParameters().get('gc');
			String resultUrl = prepareUrl(Page.CommunityGroupDetailPage.getUrl());
			if (String.isNotBlank(chatterGroupId2)) {
				resultUrl += '?g=' + chatterGroupId2;
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
						+ '?g=' + chatterGroup.Id + '&retURL='
						+ EncodingUtil.urlEncode(prepareUrl(Page.CommunityGroupManager.getUrl()) + '?g=' + chatterGroup.Id, 'UTF-8');
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
			return (control != null && control.get('Image_Path__c') != null && String.isNotBlank(control.Image_Path__c)) ? control.Image_Path__c : '/profilephoto/0F9/F' ;
		}
	}

	// Feed section

	public void initFeeds() {
		messagesPage = new ChatterWrapperPage();
		List<FeedItem> feedsItemList = [SELECT Id, Body, CreatedDate, CreatedBy.Name, CreatedById FROM FeedItem WHERE ParentId =:control.Id];
		if (!feedsItemList.isEmpty()) {
			Set<Id> feedItemsIds = new Set<Id>();
			Set<Id> usersToSelectFoto = new Set<Id>();
			for (FeedItem fi : feedsItemList) {
				feedItemsIds.add(fi.Id);
				usersToSelectFoto.add(fi.CreatedById);
			}
			List<FeedComment> toProc = [SELECT Id, CommentBody, CreatedBy.Name, CreatedById, CreatedDate, FeedItemId FROM FeedComment WHERE FeedItemId IN :feedItemsIds ORDER BY CreatedDate DESC];
			//Photo
			Map<Id, FeedComment> feedItemToFCMap = new Map<Id, FeedComment>();
			for (FeedComment fcItem : toProc) {
				usersToSelectFoto.add(fcItem.CreatedById);
				if (!feedItemToFCMap.containsKey(fcItem.FeedItemId)) {
					feedItemToFCMap.put(fcItem.FeedItemId, fcItem);
				}
			}
			Map<Id, String> userPhotoMap = new Map<Id, String>();
			if (usersToSelectFoto.size() > 0) {
				for (User userItem : [SELECT Id, SmallPhotoUrl FROM User WHERE Id IN :usersToSelectFoto]) {
					userPhotoMap.put(userItem.Id, userItem.SmallPhotoUrl);
				}
			}
			//End Photo
			for (FeedItem fiItem : feedsItemList) {
				ChatterWrapper cw7;
				if (feedItemToFCMap.containsKey(fiItem.Id)) {
					FeedComment fct = feedItemToFCMap.get(fiItem.Id);
					cw7 = new ChatterWrapper(fct.CreatedBy.Name, fct.CommentBody, fct.CreatedDate, userPhotoMap.get(fct.CreatedById), fiItem.Id);
				}
				else {
					cw7 = new ChatterWrapper(fiItem.CreatedBy.Name, fiItem.Body, fiItem.CreatedDate, userPhotoMap.get(fiItem.CreatedById), fiItem.Id);
				}
				messagesPage.add(cw7, false);
			}
		}
	}

	public void sendNewMessage() {
		/*if (newComment != NULL && newComment != '' && coachUser != NULL) {
			ConnectApi.ChatterMessage cMessage = ConnectApi.ChatterMessages.sendMessage(newComment, coachUser.Id);
			newComment = NULL;
			List<Cookie> existCookies = ApexPages.currentPage().getCookies().values();
			existCookies.add(new Cookie(COOKIE_CONVERSATION_ID, cMessage.conversationId, null, 3600, false));
			ApexPages.currentPage().setCookies(existCookies);
		}*/
		if (String.isNotBlank(newComment)) {
			insert new FeedItem (
				Type = 'TextPost',
				Body = newComment,
				ParentId = control.Id/*,
				NetworkScope = Network.getNetworkId()*/
			);
		}
	}

	@RemoteAction
	public static String getMessages(String inPosition, String inConvId, String inPageToken) {
		String[] cm = inConvId.split(':;:');
		ConversationWrapper cw = new ConversationWrapper();
		cw.position = inPosition;
		if (cm[0] == 'M') {
			/* PRIVATE MESSAGES NOT IMPLEMENTED
			ConnectApi.ChatterConversation chc = ConnectApi.ChatterMessages.getConversation(cm[1], inPageToken, PAGE_SIZE);
			cw.nextPageToken = (chc.messages.nextPageToken != NULL) ? ('M:;:' + chc.messages.nextPageToken) : NULL;
			cw.feedStyle = false;
			for (ConnectApi.ChatterMessage cmItem : chc.messages.messages) {
				cw.messages.add(new ChatterWrapper(cmItem, NULL));
				cw.lmid = cmItem.id;
			}*/
		}
		else if (cm[0] == 'F') {
			populateCW(cw, Datetime.now(), cm[1]);
		}
		return json.serialize(cw);
	}

	@RemoteAction
	public static String addCommentPM(String inPosition2, Id inLastMessId, String inComment) {
		ConversationWrapper cw = new ConversationWrapper();
		cw.position = inPosition2;
		/* PRIVATE MESSAGES NOT IMPLEMENTED
		ConnectApi.ChatterMessage chm = ConnectApi.ChatterMessages.replyToMessage(inComment, inLastMessId);
		cw.messages.add(new ChatterWrapper(chm, NULL));
		*/
		insert new FeedComment(CommentBody = inComment, FeedItemId = inLastMessId);
		User currentUser = [SELECT Id, Name, SmallPhotoUrl FROM User WHERE Id = :UserInfo.getUserId()];
		cw.messages.add(new ChatterWrapper(currentUser.Name, inComment, Datetime.now() , currentUser.SmallPhotoUrl, NULL));
		return json.serialize(cw);
	}

	@RemoteAction
	public static String getNextMessages(String inPosition, String inPageToken) {
		String[] cm2 = inPageToken.split(':;:');
		ConversationWrapper cw2 = new ConversationWrapper();
		cw2.position = inPosition;
		if (cm2[0] == 'M') {
			/* PRIVATE MESSAGES NOT IMPLEMENTED
			ConnectApi.ChatterMessagePage cmp = ConnectApi.ChatterMessages.getMessages(cm2[1], PAGE_SIZE);
			cw2.nextPageToken = (cmp.nextPageToken != NULL) ? ('M:;:' + cmp.nextPageToken) : NULL;
			for (ConnectApi.ChatterMessage cmItem2 : cmp.messages) {
				cw2.messages.add(new ChatterWrapper(cmItem2, NULL));
				cw2.lmid = cmItem2.id;
			}
			*/
		}
		else if (cm2[0] == 'F') {
			populateCW(cw2, Datetime.valueOf(Long.valueOf(cm2[1])), cm2[2]);
		}
		return json.serialize(cw2);
	}

	private static void populateCW(ConversationWrapper incw, Datetime inDate, String inFIid) {
		incw.feedStyle = true;
		FeedItem fi = [SELECT Id, Body, CreatedDate, CreatedBy.Name, CreatedById FROM FeedItem WHERE Id =:inFIid];
		incw.lmid = fi.Id;
		List<FeedComment> toProc2 = [
						SELECT Id, CommentBody, CreatedBy.Name, CreatedById, CreatedDate, FeedItemId
						FROM FeedComment
						WHERE FeedItemId = :inFIid AND CreatedDate < :inDate
						ORDER BY CreatedDate DESC LIMIT :(PAGE_SIZE + 1)
							];
		Boolean haveNextPage = (toProc2.size() == (PAGE_SIZE + 1));
		if (haveNextPage) {
			toProc2.remove(PAGE_SIZE);
			incw.nextPageToken = 'F:;:' + String.valueOf(toProc2[PAGE_SIZE - 1].CreatedDate.getTime()) + ':;:' + toProc2[PAGE_SIZE - 1].FeedItemId;
		}
		Set<Id> usersToSelectFoto = new Set<Id>();
		Map<Id, String> userFotoMap = new Map<Id, String>();
		usersToSelectFoto.add(fi.CreatedById);
		for (FeedComment fcItem2 : toProc2) {
			usersToSelectFoto.add(fcItem2.CreatedById);
		}
		if (usersToSelectFoto.size() > 0) {
			for (User userItem : [SELECT Id, SmallPhotoUrl FROM User WHERE Id IN :usersToSelectFoto]) {
				userFotoMap.put(userItem.Id, userItem.SmallPhotoUrl);
			}
		}
		for (FeedComment fcItem3 : toProc2) {
			incw.messages.add(new ChatterWrapper(fcItem3.CreatedBy.Name, fcItem3.CommentBody, fcItem3.CreatedDate, userFotoMap.get(fcItem3.CreatedById), NULL));
		}
		if (!haveNextPage) {
			incw.messages.add(new ChatterWrapper(fi.CreatedBy.Name, fi.Body, fi.CreatedDate, userFotoMap.get(fi.CreatedById), NULL));
		}
	}

	public class ConversationWrapper {
		public String position { get;set; }
		public String lmid { get;set; }
		public String nextPageToken { get;set; }
		public List<ChatterWrapper> messages { get;set; }
		public Boolean feedStyle { get;set; }
		public Boolean showMore { get {
				return nextPageToken != NULL;
			}
		}

		public ConversationWrapper() {
			messages = new List<ChatterWrapper>();
		}
	}

	public class ChatterWrapperPage {
		public List<ChatterWrapper> CWList { get;set; }

		public ChatterWrapperPage() {
			CWList = new List<ChatterWrapper>();
		}

		public void add(ChatterWrapper inCW, Boolean inForceFirst) {
			Boolean noAdded = true;
			if (!inForceFirst) {
				for (Integer mli=0; mli<CWList.size(); mli++) {
					if (CWList[mli].CommentDate < inCW.CommentDate) {
						CWList.add(mli, inCW);
						noAdded = false;
						break;
					}
				}
			}
			else if (CWList.size() > 0){
				CWList.add(0, inCW);
				noAdded = false;
			}
			if (noAdded) {
				CWList.add(inCW);
			}
		}
	}

	public class ChatterWrapper {
		public String Name { get;set; }
		public String Comment { get;set; }
		public String FotoUrl { get;set; }
		public DateTime CommentDate { get;set; }
		public String CommentDateStr { get;set; }
		public String ConversationId { get;set; }
		/*public String MessUrl { get;set; }*/
		// Mode:
		// 1 - private message
		// 2 - old conversation with coach
		// 3 - feed element
		public String Mode { get;set; }

		public ChatterWrapper() {
		}
		/* PRIVATE MESSAGES NOT IMPLEMENTED
		public ChatterWrapper(ConnectApi.ChatterMessage inCM, String inCId) {
			Name = inCM.sender.name;
			Comment = inCM.body.text;
			FotoUrl = inCM.sender.photo.smallPhotoUrl;
			CommentDate = inCM.sentDate;
			CommentDateStr = (CommentDate != NULL) ? CommentDate.format('MMMM dd, yyyy hh:mm a') : '';
			ConversationId = 'M:;:' + inCId;
			MessUrl = '?c=' + inCId;
			Mode = '1';
		}
		*/
		public ChatterWrapper(String inName, String inComment, DateTime inDT, String inFotoUrl, String inCId) {
			Name = inName;
			Comment = inComment;
			FotoUrl = inFotoUrl;
			CommentDate = inDT;
			CommentDateStr = (CommentDate != NULL) ? CommentDate.format('MMMM dd, yyyy hh:mm a') : '';
			ConversationId = 'F:;:' + inCId;
			/*MessUrl = '?c=' + inCId;*/
			Mode = '2';
		}

		public ChatterWrapper(Datetime inCreatedDate, aBody inBody, aActor inUser, aParent inParent) {
			Name = inUser.name;
			String assemblyComment = '';
			if (inBody.messageSegments != NULL && inBody.messageSegments.size() > 0) {
				for (aMs msItem : inBody.messageSegments) {
					assemblyComment += (msItem.type == 'Mention') ? ('<span class="c-user">' + msItem.text + '</span>') : (msItem.text + '');
				}
			}
			Comment = assemblyComment;
			FotoUrl = inUser.photo.smallPhotoUrl;
			CommentDate = inCreatedDate;
			CommentDateStr = (CommentDate != NULL) ? CommentDate.format('MMMM dd, yyyy hh:mm a') : '';
			/*MessUrl = (inParent == NULL) ? '?p=user' : inParent.urlParameter();*/
			Mode = '3';
		}
	}

	//feed handle class
	public class aFeed {
		public aActor actor;
		public aBody body;
		public aParent parent;
		public Datetime createdDate;
		public aCommentPage comments;
	}
	public class aPhoto {
		public String smallPhotoUrl;
	}
	public class aActor {
		public aPhoto photo;
		public String name;
	}
	public class aMs {
		public String text;
		public String type;
	}
	public class aBody {
		public List<aMs> messageSegments;
		public String text;
	}
	public class aParent {
		public String id;
	}
	public class aCommentPage {
		public List<aComment> comments;
	}
	public class aComment {
		public aBody body;
		public Datetime createdDate;
		public aActor user;
		public aParent parent;
	}

	// MEMBER HANDLER CLASS
	private final static Integer MEMBER_PAGE_SIZE = 10;
	public MemberPage members { get;set; }
	public MemberPage managers { get;set; }

	public PageReference updateMemberField() {
		System.debug('updateMemberId: ' + updateMemberId);
		System.debug('updateMemberFieldName: ' + updateMemberFieldName);
		System.debug('updateMemberFieldValue: ' + updateMemberFieldValue);

		for(Member currentM : members.users) {
			if(currentM.id == updateMemberId) {
				if(updateMemberFieldName.equalsIgnoreCase('member')) {
					currentM.member = Boolean.valueOf(updateMemberFieldValue);
				}
				if(updateMemberFieldName.equalsIgnoreCase('manager')) {
					currentM.manager = Boolean.valueOf(updateMemberFieldValue);
				}
				System.debug('currentMemeber:  ' + currentM);
				break;
			}
		}
		for(Member currentM : managers.users) {
			if(currentM.id == updateMemberId) {
				if(updateMemberFieldName.equalsIgnoreCase('member')) {
					currentM.member = Boolean.valueOf(updateMemberFieldValue);
				}
				if(updateMemberFieldName.equalsIgnoreCase('manager')) {
					currentM.manager = Boolean.valueOf(updateMemberFieldValue);
				}
				System.debug('currentManager:  ' + currentM);
				break;
			}
		}
		return null;
	}


	public class MemberPage {
		transient public List<Member> users { get;set; }
		public Integer pageNumber { get;set; }
		public Integer totalPages { get;set; }
		public Boolean hasNext { get;set; }
		public Boolean hasPrevious { get;set; }
		public Boolean showPagination { get;set; }
		public String query { get;set; }
		public Integer columnSort { get {return columnSort == NULL ? 0 : columnSort;}set; }
		public Boolean ascSort { get {return ascSort == NULL ? false : ascSort;}set; }
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
			List<User> allUsers;
			if (allMode) {
				String mQuery = 'SELECT Id, Name, ContactId, City, Country, Community_Contact_ID__c, SmallPhotoUrl FROM User WHERE (ContactId != NULL OR Community_Contact_ID__c != NULL) AND isActive = true';
				if (String.isNotBlank(query)) {
					mQuery += ' AND (FirstName LIKE \'' + query + '%\' OR LastName LIKE \'' + query + '%\')';
				}
				if (columnSort > 0) {
					List<String> orderList = new List<String> {'','Name'};
					mQuery += ' ORDER BY ' + orderList[columnSort] + (ascSort ? ' ASC' : ' DESC');
				}
				allUsers = Database.query(mQuery);
			}
			else if (membersMode) {
				String mQuery2 = 'SELECT MemberId, Member.Name, Member.Id, Member.ContactId, Member.City, Member.Country, Member.Community_Contact_ID__c, Member.SmallPhotoUrl FROM CollaborationGroupMember';
				mQuery2 += ' WHERE CollaborationGroupId =\'' + gIdChatter + '\' AND (Member.ContactId != NULL OR Member.Community_Contact_ID__c != NULL) AND Member.isActive = true';
				if (String.isNotBlank(query)) {
					mQuery2 += ' AND (Member.FirstName LIKE \'' + query + '%\' OR Member.LastName LIKE \'' + query + '%\')';
				}
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
				String mQuery3 = 'SELECT Group_Membership_User__c, Group_Membership_User__r.Id, Group_Membership_User__r.Name, Group_Membership_User__r.ContactId, Group_Membership_User__r.City, Group_Membership_User__r.Country, Group_Membership_User__r.Community_Contact_ID__c, Group_Membership_User__r.SmallPhotoUrl FROM Community_Group_Membership__c';
				mQuery3 += ' WHERE Group_Control__c =\'' + gIdControl + '\' AND (Group_Membership_User__r.ContactId != NULL OR Group_Membership_User__r.Community_Contact_ID__c != NULL) AND Group_Membership_User__r.isActive = true';
				if (String.isNotBlank(query)) {
					mQuery3 += ' AND (Group_Membership_User__r.FirstName LIKE \'' + query + '%\' OR Group_Membership_User__r.LastName LIKE \'' + query + '%\')';
				}
				if (columnSort > 0) {
					List<String> orderList = new List<String> {'','Group_Membership_User__r.Name'};
					mQuery3 += ' ORDER BY ' + orderList[columnSort] + (ascSort ? ' ASC' : ' DESC');
				}
				allUsers = new List<User>();
				for (Community_Group_Membership__c cgm : Database.query(mQuery3)) {
					allUsers.add(cgm.Group_Membership_User__r);
				}
			}
			Integer mlSize = allUsers.size();
			totalPages = mlSize / MEMBER_PAGE_SIZE + ((Math.mod(mlSize, MEMBER_PAGE_SIZE) == 0) ? 0 : 1);
			totalPages = totalPages == 0 ? 1 : totalPages;
			showPagination = totalPages > 1;
			pageNumber = pageNumber == NULL ? 1 : pageNumber;
			hasNext = pageNumber < totalPages;
			hasPrevious = pageNumber > 1;
			Integer startCopyInterval = pageNumber > 1 ? ((pageNumber - 1) * MEMBER_PAGE_SIZE) : 0;
			Integer endCopyInterval = (mlSize <= (startCopyInterval + MEMBER_PAGE_SIZE)) ? mlSize : (startCopyInterval + MEMBER_PAGE_SIZE);
			Map<Id, Id> userByContactIdsMap = new Map<Id, Id>();
			for (Integer ii = startCopyInterval; ii < endCopyInterval; ii++) {
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
			for (Community_Group_Membership__c cgm2 : [SELECT Group_Membership_User__c FROM Community_Group_Membership__c WHERE Group_Control__c = :gIdControl AND Group_Membership_User__c IN :userByContactIdsMap.values()]) {
				managersIds.add(cgm2.Group_Membership_User__c);
			}
			users = new List<Member>();
			for (Integer jj = startCopyInterval; jj < endCopyInterval; jj++) {
				Member nm = new Member(allUsers[jj], membersIds.contains(allUsers[jj].Id), managersIds.contains(allUsers[jj].Id), roleMap.get(allUsers[jj].Id), ownerControlId);
				nm.city = allUsers[jj].City;
				nm.country = allUsers[jj].Country;
				users.add(nm);
			}

		}

		public void column() {
			ascSort = (prevCol == NULL || columnSort != prevCol) ? true : !ascSort;
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
			pageNumber = 0;
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
}
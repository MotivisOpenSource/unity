public with sharing class CommunityProfilePageController {

	public Boolean allOk { get;set; }
	public Boolean current { get;set; }
	public String currentProfileId { get;set; }
	public Community_Profile__c currentProfile { get;set; }
	public List<FieldSection> overviewTab { get;set; }
	public Id currentUserId { get;set; }
	public List<ProfileTab> profiles { get;set; }
	public transient String FullPhotoUrl { get;set; }
	public transient List<InterestSection> interests { get;set; }

	private Id contactId;
	private static Map<String, Schema.SObjectField> CP_FIELDS = SObjectType.Community_Profile__c.fields.getMap();

	public CommunityProfilePageController() {
		try {
			String tempContactId = ApexPages.currentPage().getParameters().get('cid');
			String tempUserId = ApexPages.currentPage().getParameters().get('id');
			if (String.isBlank(tempUserId) && String.isNotBlank(tempContactId)) {
				contactId = Id.valueOf(tempContactId);
				List<User> currentUserList2 = [SELECT Id, ContactId, FullPhotoUrl FROM User WHERE ContactId = :contactId OR Community_Contact_ID__c = :contactId];
				Boolean userFound = currentUserList2.size() > 0;
				currentUserId = userFound ? currentUserList2[0].Id : NULL;
				FullPhotoUrl = userFound ? currentUserList2[0].FullPhotoUrl : '/profilephoto/005/F';
			}
			else {
				currentUserId = String.isNotBlank(tempUserId) ? Id.valueOf(tempUserId) : UserInfo.getUserId();
				User currentUserLocal2 = [SELECT ContactId, Community_Contact_ID__c, FullPhotoUrl FROM User WHERE Id = :currentUserId];
				contactId = currentUserLocal2.ContactId != NULL ? currentUserLocal2.ContactId : currentUserLocal2.Community_Contact_ID__c;
				FullPhotoUrl = currentUserLocal2.FullPhotoUrl;
			}
			allOk = contactId != NULL;
			current = (String.isNotBlank(currentUserId) && currentUserId == UserInfo.getUserId());
		}
		catch(Exception e) {
			allOk = false;
		}
		if (allOk) {
			init();
			initInterests();
		}
	}

	public void init() {
		try {
			// select available profiles for current user
			List<Community_Profile__c> localProfiles = [SELECT Id, Name, Primary__c, RecordType.Name FROM Community_Profile__c WHERE Contact__c = :contactId];
			Map<Id, Community_Profile__c> cpMap = new Map<Id, Community_Profile__c>();
			Community_Profile__c primaryCp;
			for (Community_Profile__c cpItem1 : localProfiles) {
				primaryCp = (cpItem1.Primary__c == true && primaryCp == NULL) ? cpItem1 : primaryCp;
				cpMap.put(cpItem1.Id, cpItem1);
			}
			// select current profile
			if (String.isNotBlank(currentProfileId) && cpMap.containsKey(currentProfileId)) {
				currentProfile = cpMap.get(currentProfileId);
			}
			else if (primaryCp != NULL) {
				currentProfile = primaryCp;
			}
			else {
				Contact tmpContact = [SELECT Primary_Community_Profile__c FROM Contact WHERE Id = :contactId];
				if (tmpContact.Primary_Community_Profile__c != NULL && cpMap.containsKey(tmpContact.Primary_Community_Profile__c)) {
					currentProfile = cpMap.get(tmpContact.Primary_Community_Profile__c);
				}
				else if (tmpContact.Primary_Community_Profile__c == NULL) {
					currentProfile = [SELECT Id, Name, Primary__c, RecordType.Name FROM Community_Profile__c WHERE Contact__c = :contactId ORDER BY CreatedDate DESC LIMIT 1];
				}
				else {
					currentProfile = [SELECT Id, Name, Primary__c, RecordType.Name FROM Community_Profile__c WHERE Id = :tmpContact.Primary_Community_Profile__c];
					localProfiles.add(currentProfile);
				}
			}
			// initialize profile tab
			profiles = new List<ProfileTab>();
			for (Community_Profile__c lpItem : localProfiles) {
				profiles.add(new ProfileTab(lpItem, (lpItem.Id == currentProfile.Id)));
			}
			//handle add to package dynamic section labels
			String section1 = Label.LBL_About_me;
			String section2 = Label.LBL_Contact;
			// select contact with field from fieldset
			overviewTab = new List<FieldSection>();
			String rtName = currentProfile.RecordType.Name.replace('/','');
			Map<String, FieldSection> tabMap = new Map<String, FieldSection>();
			for (Schema.FieldSet fsItem : SObjectType.Community_Profile__c.FieldSets.getMap().values()) {
				String fsLabel = fsItem.getLabel();
				if (fsLabel.contains(':')) {
					String[] parts = fsLabel.split(':');
					if (parts.size() == 3 && parts[0] == rtName && parts[2].isNumeric()) {
						Integer sNum = Integer.valueOf(parts[2]);
						Boolean notAdded = true;
						for (Integer ii = 0; ii < overviewTab.size(); ii++) {
							if (overviewTab[ii].sectionOrder >= sNum) {
								overviewTab.add(ii, new FieldSection(fsItem, parts[1], sNum));
								notAdded = false;
								break;
							}
						}
						if (notAdded) {
							overviewTab.add(new FieldSection(fsItem, parts[1], sNum));
						}
					}
				}
			}
			Set<String> profileFields = new Set<String> {'Id', 'Name', 'Contact__r.Name'};
			for (FieldSection fs2 : overviewTab) {
				for (FieldItem fi2 : fs2.fi) {
					profileFields.add(fi2.name);
				}
			}
			List<String> fieldList = new List<String>();
			fieldList.addAll(profileFields);
			currentProfile = Database.query('SELECT ' + String.join(fieldList, ', ') + ' FROM Community_Profile__c WHERE Id =\'' + currentProfile.Id + '\'');
		}
		catch (Exception e) {
			allOk = false;
		}
	}

	public String getStudentName() {
		return currentProfile.Contact__r.Name;
	}

	private void initInterests() {
		Set<Id> activeTags = new Set<Id>();
		for (Community_Profile_Tag__c cptItem : [SELECT Community_Tag__c FROM Community_Profile_Tag__c WHERE Contact__c =:contactId AND Active__c = true]) {
			activeTags.add(cptItem.Community_Tag__c);
		}
		Map<Id,InterestSection> isMap = new Map<Id,InterestSection>();
		for (Community_Tag__c ctItem : [
						SELECT Name, Id, Community_Theme__c, Community_Theme__r.Name, Community_Theme__r.Id
						FROM Community_Tag__c
						WHERE Community_Theme__r.Theme_Type__c = 'Interest'
						ORDER BY Community_Theme__r.Name, Name
							]) {
			if (!isMap.containsKey(ctItem.Community_Theme__c)) {
				isMap.put(ctItem.Community_Theme__c, new InterestSection(ctItem.Community_Theme__r.Name, ctItem.Community_Theme__r.Id));
			}
			isMap.get(ctItem.Community_Theme__c).it.add(new InterestTag(ctItem, activeTags.contains(ctItem.Id)));
		}
		interests = isMap.values();
	}

	public void submit() {
		try {
			update currentProfile;
		}
		catch (Exception e) {
			ApexPages.addMessages(e);
		}
	}

	// Change password section
	public String oldPassword { get; set; }
	public String newPassword { get; set; }
	public String confirmPassword { get; set; }
	public Boolean showChangePasswordSuccessMsg { get; set; }

	public void changePassword() {
		showChangePasswordSuccessMsg = NULL;
		try {
			if (Site.changePassword(newPassword, confirmPassword, oldPassword) != NULL) {
				oldPassword = NULL;
				newPassword = NULL;
				confirmPassword = NULL;
				showChangePasswordSuccessMsg = true;
			}
		}
		catch (Exception e) {
			ApexPages.addMessages(e);
		}
	}

	public void cancelChangePassword() {
		oldPassword = NULL;
		newPassword = NULL;
		confirmPassword = NULL;
		showChangePasswordSuccessMsg = NULL;
	}

	public Boolean getShowChangePassword() {
		Set<String> noredirect = new Set<String> { 'Standard', 'Salesforce' };
		Map<Id, Profile> studentsProfiles = new Map<Id, Profile>([SELECT Id FROM Profile WHERE Name LIKE '%Community%']);
		Community_Settings__c cs = Community_Settings__c.getInstance();
		return !noredirect.contains(Userinfo.getUserType())
				&& studentsProfiles.containsKey(Userinfo.getProfileId())
				&& (cs == NULL || cs.Disable_Change_Password__c != true);
	}

	public String getLastTimePasswordChange() {
		String result = '';
		if (showChangePasswordSuccessMsg != true) {
			try {
				Datetime dt = [SELECT LastPasswordChangeDate FROM User WHERE Id = :UserInfo.getUserId()].LastPasswordChangeDate;
				result = Label.LBL_PasswordChange_Message + ' ' + dt.format();
			}
			catch (Exception e) {}
		}
		return result;
	}

	public NotificationPage getEmailNotifications() {
		List<NotificationSection> resultSections = new List<NotificationSection> {
			new NotificationSection(
				Label.LBL_General,
				true,
				new List<NotificationItem> {
					new NotificationItem('PreferencesDisableAllFeedsEmail',Label.LBL_EmailNotifications)
				}
			),
			new NotificationSection(
				Label.LBL_Follows,
				false,
				new List<NotificationItem> {
					new NotificationItem('PreferencesDisableFollowersEmail',Label.LBL_FollowMe)
				}
			),
			new NotificationSection(
				Label.LBL_PostsLikes_Title,
				false,
				new List<NotificationItem> {
					new NotificationItem('PreferencesDisableProfilePostEmail',Label.LBL_ProfilePosts),
					new NotificationItem('PreferencesDisableSharePostEmail',Label.LBL_SharesPosts),
					new NotificationItem('PreferencesDisableLikeEmail',Label.LBL_LikesPost)
				}
			),
			new NotificationSection(
				Label.LBL_Comments_Title,
				false,
				new List<NotificationItem> {
					new NotificationItem('PreferencesDisableChangeCommentEmail',Label.LBL_CommentsStatusChange),
					new NotificationItem('PreferencesDisProfPostCommentEmail',Label.LBL_CommentsProfilePost),
					new NotificationItem('PreferencesDisableLaterCommentEmail',Label.LBL_CommentsAfterMe),
					new NotificationItem('PreferencesDisableBookmarkEmail',Label.LBL_CommentsOnBookmarked),
					new NotificationItem('PreferencesDisCommentAfterLikeEmail',Label.LBL_CommentsOnLike)
				}
			),
			new NotificationSection(
				Label.LBL_Mentions_Title,
				false,
				new List<NotificationItem> {
					new NotificationItem('PreferencesDisableMentionsPostEmail',Label.LBL_MentionsMePost),
					new NotificationItem('PreferencesDisMentionsCommentEmail',Label.LBL_MentionsMeComment),
					new NotificationItem('PreferencesDisableMessageEmail',Label.LBL_MessagesMe)
				}
			)
		};
		return new NotificationPage(resultSections);
	}

	public List<DigestItem> getDigestSettings() {
		List<DigestItem> resultList = new List<DigestItem>();
		for (CollaborationGroupMember cgmItem : [
					SELECT CollaborationGroupId, CollaborationGroup.Name, NotificationFrequency
					FROM CollaborationGroupMember
					WHERE MemberId = :UserInfo.getUserId()
					ORDER BY CollaborationGroup.Name
						]) {
			resultList.add(new DigestItem(cgmItem));
		}
		return resultList;
	}

	public DigestItem getDefaultDigest() {
		NetworkMember nm = (Test.isRunningTest() || Network.getNetworkId() == NULL)
				? new NetworkMember()
				: [SELECT DefaultGroupNotificationFrequency FROM NetworkMember WHERE MemberId = :UserInfo.getUserId() AND NetworkId = :Network.getNetworkId()];
		return new DigestItem(nm);
	}

	//remote actions
	@RemoteAction
	public static String toggle(String inid, Boolean sel) {
		User currentUserLocal3 = [SELECT ContactId, Community_Contact_ID__c, FullPhotoUrl FROM User WHERE Id =:UserInfo.getUserId()];
		Id ccId = currentUserLocal3.ContactId != NULL ? currentUserLocal3.ContactId : currentUserLocal3.Community_Contact_ID__c;
		if (ccId != NULL) {
			List<Community_Profile_Tag__c> cptList3 = [SELECT Id, Active__c FROM Community_Profile_Tag__c WHERE Contact__c = :ccId AND Community_Tag__c = :inid LIMIT 1];
			if (cptList3.size() > 0) {
				cptList3[0].Active__c = sel;
				update cptList3;
			}
			else {
				insert new Community_Profile_Tag__c (Contact__c = ccId, Community_Tag__c = inid, Active__c = true);
			}
		}
		return '';
	}

	@RemoteAction
	public static String toggleUserNotification(String fieldName) {
		NetworkMember nm = Database.query('SELECT Id, ' + fieldName + ' FROM NetworkMember WHERE MemberId =\'' + UserInfo.getUserId() + '\' AND NetworkId =\'' + Network.getNetworkId() + '\'');
		Boolean tb = (Boolean)nm.get(fieldName) == true;
		nm.put(fieldName, !tb);
		update nm;
		return '';
	}

	@RemoteAction
	public static String toggleUserDigest(String groupId, String freq) {
		if (String.isBlank(groupId)) {
			NetworkMember nm = [SELECT Id, DefaultGroupNotificationFrequency FROM NetworkMember WHERE MemberId = :UserInfo.getUserId() AND NetworkId = :Network.getNetworkId()];
			nm.DefaultGroupNotificationFrequency = freq;
			update nm;
		}
		else {
			CollaborationGroupMember cgm = [SELECT Id, NotificationFrequency FROM CollaborationGroupMember WHERE MemberId = :UserInfo.getUserId() AND CollaborationGroupId = :groupId];
			cgm.NotificationFrequency = freq;
			update cgm;
		}
		return '';
	}

	public class FieldSection {
		public String sectionLabel { get;set; }
		public Integer sectionOrder;
		public List<FieldItem> fi { get;set; }

		public FieldSection(Schema.FieldSet infs, String inlabel, Integer inorder) {
			fi = new List<FieldItem>();
			sectionLabel = inlabel;
			sectionOrder = inorder;
			for (Schema.FieldSetMember f3 : infs.getFields()) {
				fi.add(new FieldItem(f3));
			}
		}

		public Boolean getShowSection() {
			Boolean result = false;
			for (FieldItem fi1 : this.fi) {
				result = fi1.isAccessible ? true : result;
			}
			return result;
		}
	}

	private static Map<DisplayType, String> TYPE_TO_STYLE = new Map<DisplayType, String> {
		DisplayType.String => 'input', DisplayType.TextArea => 'textarea', DisplayType.Boolean => 'checkbox',
		DisplayType.DateTime => 'text', DisplayType.Date => 'text', DisplayType.Time => 'text'
	};

	public class FieldItem {
		public String name { get;set; }
		public String label { get;set; }
		public Boolean required { get;set; }
		public Boolean isUpdateable { get;set; }
		public Boolean isAccessible { get;set; }
		public String inputStyle { get { return inputStyle == NULL ? 'input' : inputStyle; } set; }
		public Boolean checkbox { get;set;}

		public FieldItem(Schema.FieldSetMember infsm) {
			name = infsm.getFieldPath();
			required = infsm.getRequired() || infsm.getDBRequired();
			DescribeFieldResult dfr = CP_FIELDS.get(name).getDescribe();
			isUpdateable = dfr.isUpdateable();
			isAccessible = dfr.isAccessible();
			label = dfr.getLabel();
			inputStyle = TYPE_TO_STYLE.get(dfr.getType());
			checkbox = dfr.getType() == DisplayType.Boolean;
		}
	}

	public class ProfileTab {
		public String name { get;set; }
		public Boolean active { get;set; }
		public String profileId { get;set; }

		public ProfileTab(Community_Profile__c incp, Boolean inisa) {
			name = incp.RecordType.Name;
			active = inisa;
			profileId = incp.Id;
		}
	}

	public class InterestSection {
		public String id { get;set; }
		public String name { get;set; }
		public List<InterestTag> it { get;set; }

		public InterestSection(String inn, String itemId) {
			this.it = new List<InterestTag>();
			this.name = inn;
			this.id = itemId;
		}
	}

	public class InterestTag {
		public String tagId { get;set; }
		public Boolean checked { get;set; }
		public String name { get;set; }

		public InterestTag(Community_Tag__c inct, Boolean inchkd) {
			tagId = inct.Id;
			checked = inchkd;
			name = inct.Name;
		}
	}

	public class NotificationPage {
		public List<NotificationSection> sections { get; set; }
		public NetworkMember nm { get; set; }

		public NotificationPage(List<NotificationSection> s) {
			sections = s;
			List<String> userFields = new List<String>();
			for (NotificationSection sItem : sections) {
				for (NotificationItem iItem : sItem.items) {
					userFields.add(iItem.fieldName);
				}
			}
			nm = (Test.isRunningTest() || Network.getNetworkId() == NULL)
				? new NetworkMember()
				: Database.query('SELECT ' + String.join(userFields, ', ') + ' FROM NetworkMember WHERE MemberId =\'' + UserInfo.getUserId() + '\' AND NetworkId =\'' + Network.getNetworkId() + '\'');
			Boolean initialDisabled = nm.PreferencesDisableAllFeedsEmail == true;
			for (NotificationSection sItem2 : sections) {
				for (NotificationItem iItem2 : sItem2.items) {
					iItem2.disabled = !sItem2.general && initialDisabled;
					iItem2.checked = (Boolean)nm.get(iItem2.fieldName) != true;
				}
			}
		}
	}

	public class NotificationSection {
		public String sectionLabel { get; set; }
		public Boolean general { get; set; }
		public List<NotificationItem> items { get; set; }

		public NotificationSection(String l, Boolean d, List<NotificationItem> i) {
			sectionLabel = l;
			general = d == true;
			items = (i != NULL) ? i : new List<NotificationItem>();
		}
	}

	public class NotificationItem {
		public String fieldName { get; set; }
		public String fieldLabel { get; set; }
		public Boolean disabled;
		public Boolean checked;

		public NotificationItem(String n, String l) {
			fieldName = n;
			fieldLabel = l;
		}

		public String getInputHtml() {
			return '<input type="checkbox" onchange="chnot(this);" name="' + fieldName + '"'
					+ (disabled ? ' disabled="disabled"' : '')
					+ (checked ? ' checked="true"' : '')
					+ '/><i' + (disabled ? '' : (checked ? ' class="green-btn"' : ' class="red-btn"')) + '></i>';
		}
	}

	public class DigestItem {
		public String gname { get; set; }
		public String gid { get; set; }
		public String eepStyle { get; set; }
		public String ddStyle { get; set; }
		public String wdStyle { get; set; }
		public String nStyle { get; set; }

		public DigestItem(CollaborationGroupMember cgm) {
			gname = cgm.CollaborationGroup.Name;
			gid = cgm.CollaborationGroupId;
			eepStyle = cgm.NotificationFrequency == 'P' ? ' fa fa-dot-circle-o' : '';
			ddStyle = cgm.NotificationFrequency == 'D' ? ' fa fa-dot-circle-o' : '';
			wdStyle = cgm.NotificationFrequency == 'W' ? ' fa fa-dot-circle-o' : '';
			nStyle = cgm.NotificationFrequency == 'N' ? ' fa fa-dot-circle-o' : '';
		}

		public DigestItem(NetworkMember inu) {
			gname = '';
			gid = '';
			eepStyle = inu.DefaultGroupNotificationFrequency == 'P' ? ' fa fa-dot-circle-o' : '';
			ddStyle = inu.DefaultGroupNotificationFrequency == 'D' ? ' fa fa-dot-circle-o' : '';
			wdStyle = inu.DefaultGroupNotificationFrequency == 'W' ? ' fa fa-dot-circle-o' : '';
			nStyle = inu.DefaultGroupNotificationFrequency == 'N' ? ' fa fa-dot-circle-o' : '';
		}
	}
	
	public Boolean getIsSubscribe() { 
	    List<EntitySubscription> followings = [
				Select SubscriberId, ParentId, IsDeleted, Id, CreatedDate, CreatedById
				From EntitySubscription
				WHERE SubscriberId =:Userinfo.getUserId()
				AND ParentId = :currentUserId
				LIMIT 1
			];
		return (followings.isEmpty())?false:true;
	}

	public void subscribeUser(){ 
	    CommunityUtils.subscriberUser(currentUserId,!getIsSubscribe());
	}
}
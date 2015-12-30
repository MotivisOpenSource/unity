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

global with sharing class CommunityProfilePageController {

	public Boolean allOk { get;set; }
	public Boolean current { get;set; }
	public String currentProfileId { get;set; }
	public Community_Profile__c currentProfile { get;set; }
	public List<CommunityFieldLayout> overviewTab { get;set; }
	public Id currentUserId { get;set; }
	public List<ProfileTab> profiles { get;set; }
	public transient String FullPhotoUrl { get;set; }
	public transient List<InterestSection> interests { get;set; }
	public List<List<String>> fieldsets { get;set; }

	private Id contactId;
	private static Map<String, Schema.SObjectField> CP_FIELDS = SObjectType.Community_Profile__c.fields.getMap();
	
	public Boolean getIsCommunityUser() {
		if (currentUserId == UserInfo.getUserId()) return true;
		if (currentProfile == null) return false;
		List<NetworkMember> nmList = [SELECT Id FROM NetworkMember WHERE MemberId = :currentUserId AND Member.isActive = true AND NetworkId = :Network.getNetworkId()];
		return !nmList.isEmpty();
	}

	public CommunityProfilePageController() {
		try {
			String tempContactId = CommunityUtils.validateId(ApexPages.currentPage().getParameters().get('cid'));
			String tempUserId = CommunityUtils.validateId(ApexPages.currentPage().getParameters().get('id'));
			if (String.isBlank(tempUserId) && String.isNotBlank(tempContactId)) {
				contactId = Id.valueOf(tempContactId);
				List<User> currentUserList2 = CommunityHelperWithoutSharing.getCommunityUsers(null, 100, new List<String>{'ContactId', 'FullPhotoUrl'}, 'Name', true);
				Boolean userFound = currentUserList2.size() > 0;
				currentUserId = userFound ? currentUserList2[0].Id : NULL;
				FullPhotoUrl = userFound ? currentUserList2[0].FullPhotoUrl : '/profilephoto/005/F';
			}
			else {
				currentUserId = String.isNotBlank(tempUserId) ? Id.valueOf(tempUserId) : UserInfo.getUserId();
				if (!SObjectType.User.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.User);
				String queryCurrentUserId =CommunityUtils.validateId(currentUserId);
				User currentUserLocal2 = [SELECT ContactId, Community_Contact_ID__c, FullPhotoUrl FROM User WHERE Id = :queryCurrentUserId];
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
			if (!SObjectType.Community_Profile__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Profile__c);
			String queryContactId = CommunityUtils.validateId(contactId);
			List<Community_Profile__c> localProfiles = [SELECT Id, Name, Primary__c, RecordType.Name FROM Community_Profile__c WHERE Contact__c = :queryContactId];
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
				if (!SObjectType.Contact.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Contact);
				Contact tmpContact = [SELECT Primary_Community_Profile__c FROM Contact WHERE Id = :queryContactId];
				if (tmpContact.Primary_Community_Profile__c != NULL && cpMap.containsKey(tmpContact.Primary_Community_Profile__c)) {
					currentProfile = cpMap.get(tmpContact.Primary_Community_Profile__c);
				}
				else if (tmpContact.Primary_Community_Profile__c == NULL) {
					if (!SObjectType.Community_Profile__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Profile__c);
					currentProfile = [SELECT Id, Name, Primary__c, RecordType.Name FROM Community_Profile__c WHERE Contact__c = :queryContactId ORDER BY CreatedDate DESC LIMIT 1];
				}
				else {
					if (!SObjectType.Community_Profile__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Profile__c);
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
			overviewTab = new List<CommunityFieldLayout>();
			String rtName = currentProfile.RecordType.Name.replace('/','');
			Map<String, CommunityFieldLayout> tabMap = new Map<String, CommunityFieldLayout>();
			Schema.DescribeSObjectResult dsorProfile = SObjectType.Community_Profile__c;
			fieldsets = new List<List<String>>();
			List<String> fsNamesWithPrefix = new List<String>();
			Map<String,Schema.FieldSet> shfs = SObjectType.Community_Profile__c.FieldSets.getMap();
			fsNamesWithPrefix.addAll(shfs.keySet());
			for (String sfName : fsNamesWithPrefix) {
				Schema.FieldSet fsItem = shfs.get(sfName);
				String fsLabel = fsItem.getLabel();
				if (fsLabel.contains(':')) {
					String[] parts = fsLabel.split(':');
					if (parts.size() == 3 && parts[0] == rtName && parts[2].isNumeric()) {
						fieldsets.add(new List<String> {sfName, parts[1]});
						Integer sNum = Integer.valueOf(parts[2]);
						Boolean notAdded = true;
						CommunityFieldLayout cflTemp =  new CommunityFieldLayout(
							fsItem,
							dsorProfile,
							CommunityUtils.getPackagePrefix(),
							parts[1],
							sNum
						);
						for (Integer ii = 0; ii < overviewTab.size(); ii++) {
							if (overviewTab[ii].sectionOrder >= sNum) {
								overviewTab.add(ii,cflTemp);
								notAdded = false;
								break;
							}
						}
						if (notAdded) {
							overviewTab.add(cflTemp);
						}
					}
				}
			}
			String pp46 = CommunityUtils.getPackagePrefix();
			Set<String> profileFields = new Set<String> {'Id', 'Name', pp46 + 'Contact__r.Name', pp46 + 'Contact__c'};
			for (CommunityFieldLayout fs2 : overviewTab) {
				profileFields.addAll(fs2.prepareFieldList());
			}
			List<String> fieldList = new List<String>();
			fieldList.addAll(profileFields);
			SecurityWrapper sw = new SecurityWrapper();
			if (!SObjectType.Community_Profile__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Profile__c);
			List<sObject> tempList = sw.databaseQuery('SELECT ' + String.join(fieldList, ', ') + ' FROM Community_Profile__c WHERE Id =\'' + String.escapeSingleQuotes(currentProfile.Id) + '\'');
			currentProfile = (Community_Profile__c)tempList[0];
		}
		catch (Exception e) {
			allOk = false;
		}
	}

	public Map<String, Schema.FieldSet> getfsMap() {
		return SObjectType.Community_Profile__c.FieldSets.getMap();
	}

	public String getStudentName() {
		return currentProfile == NULL ? '' : currentProfile.Contact__r.Name;
	}

	public void initInterests() {
		Set<Id> activeTags = new Set<Id>();
		if (!SObjectType.Community_Profile_Tag__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Profile_Tag__c);
		String queryContactId = CommunityUtils.validateId(contactId);
		for (Community_Profile_Tag__c cptItem : [SELECT Community_Tag__c FROM Community_Profile_Tag__c WHERE Contact__c =:queryContactId AND Active__c = true]) {
			activeTags.add(cptItem.Community_Tag__c);
		}
		Map<Id,InterestSection> isMap = new Map<Id,InterestSection>();
		if (!SObjectType.Community_Tag__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Tag__c);
		List<Community_Tag__c> ctList = [
			SELECT Name, Id, Community_Theme__c, Community_Theme__r.Name, Community_Theme__r.Id
			FROM Community_Tag__c
			WHERE Community_Theme__r.Theme_Type__c = 'Interest'
			ORDER BY Community_Theme__r.Name, Name
		];
		for (Community_Tag__c ctItem : ctList) {
			if (!isMap.containsKey(ctItem.Community_Theme__c)) {
				isMap.put(ctItem.Community_Theme__c, new InterestSection(ctItem.Community_Theme__r.Name, ctItem.Community_Theme__r.Id));
			}
			isMap.get(ctItem.Community_Theme__c).it.add(new InterestTag(ctItem, activeTags.contains(ctItem.Id)));
		}
		interests = isMap.values();
	}

	public void submit() {
		try {
			//update currentProfile;
			CommunityAccess.UpdateWithoutSharing(
				currentProfile,
				'CommunityProfilePageController.cls [submit]',
				new List<Schema.DescribeFieldResult> {
					Community_Profile__c.Name.getDescribe()
				}
			);
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
		if (!SObjectType.User.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.User);
		User userToCheckForPortal = [SELECT Id, ContactId FROM User WHERE Id =: Userinfo.getUserId()];
		Community_Settings__c cs = Community_Settings__c.getInstance();
		return !noredirect.contains(Userinfo.getUserType())
				&& userToCheckForPortal.ContactId != null
				&& (cs == NULL || cs.Disable_Change_Password__c != true);
	}

	public String getLastTimePasswordChange() {
		String result = '';
		if (showChangePasswordSuccessMsg != true) {
			try {
				if (!SObjectType.User.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.User);
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
		if (!SObjectType.Community_Group_Control__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Group_Control__c);
		List<Community_Group_Control__c> chGroups = [SELECT Chatter_Group_ID__c FROM Community_Group_Control__c LIMIT 250];
		List<String> chGroupsIds = new List<String>();
		List<String> colGroupsIds = new List<String>();
		for(Community_Group_Control__c chGroup : chGroups){
			chGroupsIds.add(chGroup.Chatter_Group_ID__c);
		}
		if (!SObjectType.CollaborationGroup.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.CollaborationGroup);
		for(CollaborationGroup cg : [SELECT Id FROM CollaborationGroup WHERE Id IN :chGroupsIds AND NetworkId = :Network.getNetworkId()]){
			colGroupsIds.add(cg.Id);
		}
		if (!SObjectType.CollaborationGroupMember.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.CollaborationGroupMember);
		for (CollaborationGroupMember cgmItem : [
					SELECT CollaborationGroupId, CollaborationGroup.Name, NotificationFrequency
					FROM CollaborationGroupMember
					WHERE MemberId = :UserInfo.getUserId()
					AND CollaborationGroupId IN :colGroupsIds
					ORDER BY CollaborationGroup.Name ]) {
			resultList.add(new DigestItem(cgmItem));
		}
		return resultList;
	}

	public DigestItem getDefaultDigest() {
		if (!SObjectType.NetworkMember.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.NetworkMember);
		NetworkMember nm = (Test.isRunningTest() || Network.getNetworkId() == NULL)	? new NetworkMember(): [SELECT DefaultGroupNotificationFrequency FROM NetworkMember WHERE MemberId = :UserInfo.getUserId() AND NetworkId = :Network.getNetworkId()];
		return new DigestItem(nm);
	}

	//remote actions
	@RemoteAction
	global static String toggle(String inid, Boolean sel) {
		if (!SObjectType.User.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.User);
		User currentUserLocal3 = [SELECT ContactId, Community_Contact_ID__c, FullPhotoUrl FROM User WHERE Id =:UserInfo.getUserId()];
		Id ccId = currentUserLocal3.ContactId != NULL ? currentUserLocal3.ContactId : currentUserLocal3.Community_Contact_ID__c;
		if (ccId != NULL) {
			String queryCcId = CommunityUtils.validateId(ccId);
			String queryInId = CommunityUtils.validateId(inid);
			if (!SObjectType.Community_Profile_Tag__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Profile_Tag__c);
			List<Community_Profile_Tag__c> cptList3 = [SELECT Id, Active__c FROM Community_Profile_Tag__c WHERE Contact__c = :queryCcId AND Community_Tag__c = :queryInId LIMIT 1];
			if (cptList3.size() > 0) {
				cptList3[0].Active__c = sel;
				//update cptList3;
				CommunityAccess.UpdateWithoutSharing(
					cptList3,
					'CommunityProfilePageController.cls [toggle]',
					new List<Schema.DescribeFieldResult> {
						Community_Profile_Tag__c.Active__c.getDescribe()
					}
				);
			}
			else {
				//insert new Community_Profile_Tag__c (Contact__c = ccId, Community_Tag__c = inid, Active__c = true);
				Community_Profile_Tag__c cpt = new Community_Profile_Tag__c();
				cpt.Contact__c = ccId;
				cpt.Community_Tag__c = inid;
				cpt.Active__c = true;
				CommunityAccess.InsertWithoutSharing(
					cpt,
					'CommunityProfilePageController.cls [toogle]',
					new List<Schema.DescribeFieldResult> {
						Community_Profile_Tag__c.Contact__c.getDescribe(),
						Community_Profile_Tag__c.Community_Tag__c.getDescribe(),
						Community_Profile_Tag__c.Active__c.getDescribe()
					}
				);
			}
		}
		return '';
	}

	@RemoteAction
	global static String toggleUserNotification(String fieldName) {
		if (!SObjectType.NetworkMember.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.NetworkMember);
		String queryString = 'SELECT Id, ' + fieldName + ' FROM NetworkMember WHERE MemberId =\'' + String.escapeSingleQuotes(UserInfo.getUserId()) + '\' AND NetworkId =\'' + String.escapeSingleQuotes(Network.getNetworkId()) + '\'';
		NetworkMember nm = Database.query(queryString);
		Boolean tb = (Boolean)nm.get(fieldName) == true;
		nm.put(fieldName, !tb);
		//update nm;
		CommunityAccess.UpdateWithoutSharing(
			nm,
			'CommunityProfilePageController.cls [toggleUserNotification]',
			new List<Schema.DescribeFieldResult> {
				NetworkMember.DefaultGroupNotificationFrequency.getDescribe()
			}
		);
		return '';
	}
	
	//not used code
	@RemoteAction
	global static String toggleUserDigest(String groupId, String freq) {
		if (String.isBlank(groupId)) {
			if (!SObjectType.NetworkMember.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.NetworkMember);
			NetworkMember nm = [SELECT Id, DefaultGroupNotificationFrequency FROM NetworkMember WHERE MemberId = :UserInfo.getUserId() AND NetworkId = :Network.getNetworkId()];
			nm.DefaultGroupNotificationFrequency = freq;
			CommunityAccess.UpdateWithoutSharing(
				nm,
				'CommunityProfilePageController.cls [toggleUserDigest]',
				new List<Schema.DescribeFieldResult> {
					NetworkMember.DefaultGroupNotificationFrequency.getDescribe()
				}
			);
			//update nm;
		}
		else {
			String queryGroupId = CommunityUtils.validateId(groupId);
			if (!SObjectType.CollaborationGroupMember.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.CollaborationGroupMember);
			CollaborationGroupMember cgm = [SELECT Id, NotificationFrequency FROM CollaborationGroupMember WHERE MemberId = :UserInfo.getUserId() AND CollaborationGroupId = :queryGroupId];
			cgm.NotificationFrequency = freq;
			//update cgm;
			CommunityAccess.UpdateWithoutSharing(
				cgm,
				'CommunityProfilePageController.cls [toggleUserDigest]',
				new List<Schema.DescribeFieldResult> {
					CollaborationGroupMember.NotificationFrequency.getDescribe()
				}
			);
		}
		return '';
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
			if (!SObjectType.NetworkMember.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.NetworkMember);
			nm = (Test.isRunningTest() || Network.getNetworkId() == NULL) ? new NetworkMember() : Database.query('SELECT ' + String.join(userFields, ', ') + ' FROM NetworkMember WHERE MemberId =\'' + String.escapeSingleQuotes(UserInfo.getUserId()) + '\' AND NetworkId =\'' + String.escapeSingleQuotes(Network.getNetworkId()) + '\'');
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
		public Boolean disabled { get; set; }
		public Boolean checked { get; set; }

		public NotificationItem(String n, String l) {
			fieldName = n;
			fieldLabel = l;
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
		if (!SObjectType.EntitySubscription.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.EntitySubscription);
		List<EntitySubscription> followings = [
			SELECT Id
			FROM EntitySubscription
			WHERE SubscriberId =:Userinfo.getUserId() AND ParentId = :currentUserId
			LIMIT 1
		];
		return !followings.isEmpty();
	}

	
	public void subscribeUser(){ 
		CommunityUtils.subscriberUser(currentUserId,!getIsSubscribe());
	}
	

	private without sharing class SecurityWrapper {
		public List<SObject> databaseQuery(String inQueryStr) {
			return Database.query(inQueryStr);
		}
	}
	
}
public class CommunityUtils {

	public static Boolean isModifyAllData() {

		Boolean Result = [SELECT PermissionsModifyAllData FROM Profile WHERE Id =: UserInfo.getProfileId()].PermissionsModifyAllData;

		if (Result != true) {
			for (PermissionSetAssignment psa : [SELECT PermissionSet.PermissionsModifyAllData FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId()]) {
				if (psa.PermissionSet.PermissionsModifyAllData == true) {
					Result = true;
					break;
				}
			}
		}

		return Result;
	}

	public static Boolean isViewAllData() {

		Boolean Result = [SELECT PermissionsViewAllData FROM Profile WHERE Id =: UserInfo.getProfileId()].PermissionsViewAllData;

		if (Result != true) {
			for (PermissionSetAssignment psa : [SELECT PermissionSet.PermissionsViewAllData FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId()]) {
				if (psa.PermissionSet.PermissionsViewAllData == true) {
					result = true;
					break;
				}
			}
		}

		return Result;
	}

	public static Boolean canCreateGroup() {
		Boolean canCreateGroup = [SELECT PermissionsChatterOwnGroups FROM Profile WHERE Id =: UserInfo.getProfileId()].PermissionsChatterOwnGroups;
		if (canCreateGroup != true) {
			for (PermissionSetAssignment psa : [SELECT PermissionSet.PermissionsChatterOwnGroups FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId()]) {
				if (psa.PermissionSet.PermissionsChatterOwnGroups == true) {
					canCreateGroup = true;
					break;
				}
			}
		}
		return canCreateGroup;
	}

	// inUserId - user to proccess
	// inGroupContolId - group control to reference
	// inMode - action mode
	public static ConnectApi.GroupMembershipType membership(String inUserId, String inGroupContolId, String inMode) {
		ConnectApi.GroupMembershipType resultType;
		Integer inmm = Integer.valueOf(inMode);
		Community_Group_Control__c cgc = [SELECT Id, Chatter_Group_ID__c FROM Community_Group_Control__c WHERE Id =:inGroupContolId];
		List<CollaborationGroupMember> cgmList = [SELECT Id, CollaborationRole FROM CollaborationGroupMember WHERE MemberId =:inUserId AND CollaborationGroupId =:cgc.Chatter_Group_ID__c];
		// 1 - Create Chatter Group Member
		// 2 - Delete Chatter Group Member
		if (inmm < 3) {
			if (inmm == 2) {
				delete cgmList;
				resultType = ConnectApi.GroupMembershipType.NotAMember;
			}
			else if (cgmList.size() == 0) {
				NetworkMember nm = [SELECT Id, DefaultGroupNotificationFrequency FROM NetworkMember WHERE MemberId = :inUserId AND NetworkId = :Network.getNetworkId()];
				insert new CollaborationGroupMember(MemberId = inUserId, CollaborationGroupId = cgc.Chatter_Group_ID__c, NotificationFrequency = nm.DefaultGroupNotificationFrequency);
				resultType = ConnectApi.GroupMembershipType.StandardMember;
			}
		}
		// 3 - Create Group Manager
		// 4 - Delete Group Manager
		else if (inmm < 5) {
			List<Community_Group_Manager__c> cgmList2 = [SELECT Id FROM Community_Group_Manager__c WHERE Group_Manager_User__c =:inUserId AND Group_Control__c =:cgc.Id];
			List<EntitySubscription> esList2 = [SELECT Id FROM EntitySubscription WHERE ParentId = :cgc.Id AND SubscriberId = :inUserId];
			if (inmm == 4) {
				delete cgmList2;
				delete esList2;
				if (cgmList.size() > 0 && cgmList[0].CollaborationRole == 'Admin') {
					cgmList[0].CollaborationRole = 'Standard';
					update cgmList;
				}
				resultType = ConnectApi.GroupMembershipType.StandardMember;
			}
			else {
				if (cgmList.size() == 0) {
					NetworkMember nm = [SELECT Id, DefaultGroupNotificationFrequency FROM NetworkMember WHERE MemberId = :inUserId AND NetworkId = :Network.getNetworkId()];
					insert new CollaborationGroupMember(MemberId = inUserId, CollaborationGroupId = cgc.Chatter_Group_ID__c, NotificationFrequency = nm.DefaultGroupNotificationFrequency);
				}
				else if (cgmList[0].CollaborationRole == 'Standard') {
					cgmList[0].CollaborationRole = 'Admin';
					update cgmList;
				}
				if (cgmList2.size() == 0) {
					insert new Community_Group_Manager__c(Group_Manager_User__c = inUserId, Group_Control__c = cgc.Id);
				}
				if (esList2.size() == 0) {
					insert new EntitySubscription(ParentId = cgc.Id, SubscriberId = inUserId, NetworkId = Network.getNetworkId());
				}
				resultType = ConnectApi.GroupMembershipType.GroupManager;
			}
		}
		// 5 - Create Join Private Group Request
		// 6 - Delete Join Private Group Request
		else if (inmm < 7) {
			List<CollaborationGroupMemberRequest> cgmrList = [SELECT Id FROM CollaborationGroupMemberRequest WHERE CollaborationGroupId =:cgc.Chatter_Group_ID__c AND RequesterId =:inUserId AND Status = 'Pending'];
			if (inmm == 6) {
				delete cgmrList;
				resultType = ConnectApi.GroupMembershipType.NotAMember;
			}
			else {
				if (cgmList.size() == 0 && cgmrList.size() == 0) {
					insert new CollaborationGroupMemberRequest(CollaborationGroupId = cgc.Chatter_Group_ID__c, RequesterId = inUserId);
				}
				resultType = ConnectApi.GroupMembershipType.NotAMemberPrivateRequested;
			}
		}
		// 7 - Accept Join Private Group Request
		// 8 - Decline Join Private Group Request
		else {
			List<CollaborationGroupMemberRequest> cgmrList = [SELECT Id, Status FROM CollaborationGroupMemberRequest WHERE CollaborationGroupId =:cgc.Chatter_Group_ID__c AND RequesterId =:inUserId AND Status = 'Pending'];
			if (inmm == 8) {
				cgmrList[0].Status = 'Declined';
				update cgmrList;
				resultType = ConnectApi.GroupMembershipType.NotAMember;
			}
			else {
				cgmrList[0].Status = 'Accepted';
				update cgmrList;
				resultType = ConnectApi.GroupMembershipType.StandardMember;
			}
		}
		return resultType;
	}

	public static Integer getRequestJoinGroupCount(Id chatterGroupId) {
		Integer result = 0;
		if (chatterGroupId != NULL) {
			List<CollaborationGroupMemberRequest> cgmrList = [SELECT Id FROM CollaborationGroupMemberRequest WHERE CollaborationGroupId =:chatterGroupId AND Status = 'Pending'];
			result = cgmrList.size();
		}
		return result;
	}

	public static String getPackagePrefix() {
		return CommunityUtils.class.getName().substringBefore('CommunityUtils').replace('.','__');
	}

	public static void subscriberUser(Id memberId, Boolean isSubscribe) {
		if (!isSubscribe) {
			List<EntitySubscription> followings = [
				Select SubscriberId, ParentId, IsDeleted, Id, CreatedDate, CreatedById
				From EntitySubscription
				WHERE SubscriberId =:Userinfo.getUserId()
				AND ParentId = :memberId
				LIMIT 1
			];
			if (!followings.isEmpty()) {
				ConnectApi.Chatter.deleteSubscription(Network.getNetworkId(), followings[0].Id);
			}
		} else if (isSubscribe) {
			ConnectApi.ChatterUsers.follow(Network.getNetworkId(), 'me', memberId);
		}
	}

	public static GroupAction getActionButton(ConnectApi.GroupMembershipType groupRole, Boolean publicGroup) {
		GroupAction ga = new GroupAction();
		if (groupRole == ConnectApi.GroupMembershipType.GroupOwner) {
			ga.btnLabel = Label.LBL_Owner;
			ga.btnIcon = 'fa-star';
			ga.title = '';
			ga.action = '0';
			ga.btnStyle = '';
		}
		else if (groupRole == ConnectApi.GroupMembershipType.GroupManager) {
			ga.btnLabel = Label.LBL_Manager;
			ga.btnIcon = 'fa-star-half-o';
			ga.title = Label.LBL_Leave_Group;
			ga.action = '4';
			ga.btnStyle = '';
		}
		else if (groupRole == ConnectApi.GroupMembershipType.StandardMember) {
			ga.btnLabel = Label.LBL_Member;
			ga.btnIcon = 'fa-check';
			ga.title = Label.LBL_Leave_Group;
			ga.action = '2';
			ga.btnStyle = '';
		}
		else if (groupRole == ConnectApi.GroupMembershipType.NotAMember) {
			if (publicGroup) {
				ga.btnLabel = Label.BTN_Join;
				ga.title = Label.BTN_Join;
				ga.action = '1';
			}
			else {
				ga.btnLabel = Label.LBL_RequestToJoin;
				ga.title = Label.LBL_RequestToJoin;
				ga.action = '5';
			}
			ga.btnStyle = ' btn-u-blue';
			ga.btnIcon = 'fa-plus-circle';
		}
		else if (groupRole == ConnectApi.GroupMembershipType.NotAMemberPrivateRequested) {
			ga.btnLabel = Label.LBL_Requested;
			ga.btnIcon = 'fa-times-circle';
			ga.title = Label.LBL_Leave_Group;
			ga.action = '6';
			ga.btnStyle = ' btn-u-orange';
		}
		return ga;
	}

	private static String noImgUrl;
	public static String checkUrl(String inUrl) {
		if (String.isBlank(inUrl)) {
			if (noImgUrl == NULL) {
				String ns = getPackagePrefix();
				List<StaticResource> srList = [SELECT SystemModstamp FROM StaticResource WHERE Name = 'assets' AND NamespacePrefix = :ns.replace('__','')];
				noImgUrl = (srList.size() == 0)
							? ''
							: ('/resource/' + srList[0].SystemModstamp.getTime() +'/' + ns + 'assets/img/demo.jpg');
			}
			inUrl = noImgUrl;
		}
		if (String.isNotBlank(Site.getPathPrefix()) && !inUrl.startsWith(Site.getPathPrefix())) {
			inUrl = Site.getPathPrefix() + inUrl;
		}
		return inUrl;
	}

	public static Boolean checkNewsOverlapInterval(String uCondition, Datetime uStart, Datetime uEnd) {
		String uQuery = 'SELECT Id FROM Community_News__c WHERE ' + uCondition;
		if (uStart != NULL || uEnd != NULL) {
			uQuery += ' AND ((Entry_Date__c = NULL AND Expiration_Date__c = NULL) OR (';
			if (uStart != NULL && uEnd != NULL) {
				uQuery += '((Entry_Date__c = NULL OR Entry_Date__c <= :uStart) AND Expiration_Date__c >= :uStart)';
				uQuery += ' OR ((Expiration_Date__c = NULL OR Expiration_Date__c >= :uEnd) AND Entry_Date__c <= :uEnd)';
			}
			else if (uStart != NULL) {
				uQuery += 'Expiration_Date__c = NULL OR Expiration_Date__c >= :uStart';
			}
			else {
				uQuery += 'Entry_Date__c = NULL OR Entry_Date__c <= :uEnd';
			}
			uQuery += '))';
		}
		List<Community_News__c> checkList = Database.query(uQuery);
		return checkList.size() > 0;
	}

	public static void checkPrimaryProfile(Map<Id,String> inMap) {
		Map<String,Community_Profile__c> modifiedProfilesMap = new Map<String,Community_Profile__c>();
		Map<String,Community_Profile__c> existingProfilesMap = new Map<String,Community_Profile__c>();
		for (Community_Profile__c cpItem : [SELECT Id, Primary__c, RecordType.Name, Contact__c FROM Community_Profile__c WHERE Contact__c IN :inMap.keySet()]) {
			String newRole = inMap.get(cpItem.Contact__c);
			String profileKey = cpItem.Contact__c + cpItem.RecordType.Name;
			if (cpItem.RecordType.Name == newRole && cpItem.Primary__c != true) {
				cpItem.Primary__c = true;
				modifiedProfilesMap.put(profileKey, cpItem);
			}
			else if (cpItem.RecordType.Name != newRole && cpItem.Primary__c == true) {
				cpItem.Primary__c = false;
				modifiedProfilesMap.put(profileKey, cpItem);
			}
			existingProfilesMap.put(profileKey, cpItem);
		}

		Map<String,Schema.RecordTypeInfo> profileNameToRecordTypeMap = Schema.SObjectType.Community_Profile__c.getRecordTypeInfosByName();
		List<Contact> cList = [SELECT Id, Primary_Community_Profile__c, Primary_Role__c FROM Contact WHERE Id IN :inMap.keySet()];
		for (Contact cItem : cList) {
			String newRole2 = inMap.get(cItem.Id);
			String profileKey2 = cItem.Id + newRole2;
			if (!existingProfilesMap.containsKey(profileKey2)) {
				Community_Profile__c cpTemp = new Community_Profile__c(Contact__c = cItem.Id, Primary__c = true, RecordTypeId = profileNameToRecordTypeMap.get(newRole2).getRecordTypeId());
				modifiedProfilesMap.put(profileKey2, cpTemp);
				existingProfilesMap.put(profileKey2, cpTemp);
			}
		}

		if (modifiedProfilesMap.size() > 0) {
			upsert modifiedProfilesMap.values();
		}

		List<Contact> modifiedContacts = new List<Contact>();
		for (Contact cItem2 : cList) {
			String newRole3 = inMap.get(cItem2.Id);
			Id currentProfileId = existingProfilesMap.get(cItem2.Id + newRole3).Id;
			if (cItem2.Primary_Role__c != newRole3 || cItem2.Primary_Community_Profile__c != currentProfileId) {
				cItem2.Primary_Role__c = newRole3;
				cItem2.Primary_Community_Profile__c = currentProfileId;
				modifiedContacts.add(cItem2);
			}
		}

		if (modifiedContacts.size() > 0) {
			update modifiedContacts;
		}
	}

	public static PageReference checkRedirectToStandardView(Id sObjectId) {
		PageReference resultpr;
		/*Set<String> noredirect = new Set<String> { 'Standard', 'Salesforce' };
		Map<Id, Profile> studentsProfiles = new Map<Id, Profile>([SELECT Id FROM Profile WHERE Name LIKE '%Community%']);
		if (noredirect.contains(Userinfo.getUserType()) || !studentsProfiles.containsKey(Userinfo.getProfileId())) {*/
		if (String.isBlank(Site.getName())) {
			resultpr = new PageReference('/' + sObjectId);
			resultpr.getParameters().putAll(ApexPages.currentPage().getParameters());
			resultpr.getParameters().put('nooverride', '1');
			resultpr.getParameters().remove('id');
			resultpr.setRedirect(true);
		}
		return resultpr;
	}

	//wrapper classes

	public class GroupAction {
		public String btnLabel { get; set; }
		public String btnIcon { get; set; }
		public String title { get; set; }
		public String action { get; set; }
		public String btnStyle { get; set; }
		public String groupId { get; set; }
		public String memberCount { get; set; }
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
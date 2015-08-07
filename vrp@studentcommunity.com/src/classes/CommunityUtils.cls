public with sharing class CommunityUtils {
    //Moderate Chatter
    public static Boolean isModerateChatter() {
		Boolean Result = [SELECT PermissionsModerateChatter,Name,id FROM Profile WHERE Id =: UserInfo.getProfileId()].PermissionsModerateChatter;
		if (Result != true) {
			for (PermissionSetAssignment psa : [SELECT PermissionSet.PermissionsModerateChatter FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId()]) {
				if (psa.PermissionSet.PermissionsModerateChatter == true) {
					Result = true;
					break;
				}
			}
		}
		return Result;
	}
	
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

	public static Integer accessSystemTagLevel() {
		Integer resultLevel = 0;
		String editPS = 'Edit_System_Tags';
		String viewPS = 'View_System_Tags';
		Set<String> psSet = new Set<String> {editPS, viewPS};
		String pp = getPackagePrefix();
		pp = (pp != NULL) ? pp.replace('__','') : '';
		for (PermissionSetAssignment psa2 : [
					SELECT PermissionSet.Name FROM PermissionSetAssignment
					WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSet.NamespacePrefix = :pp AND PermissionSet.Name IN :psSet
						]) {
			resultLevel = (psa2.PermissionSet.Name == viewPS && resultLevel < 2) ? 1 : 2;
		}
		return resultLevel;
	}

	public static String systemTagFilter(String inGlue, String inMs) {
		if (accessSystemTagLevel() == 0) {
			inMs += inGlue + ' != \'System\'';
		}
		return inMs;
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

	public static Set<String> checkFLSFields(String objectType, Set<String> collectedFields){
		String pref = CommunityUtils.getPackagePrefix();
		String obj = pref + objectType;
		Set<String> result = new Set<String>();
		Map<String, Schema.SObjectField> mapEventFields = Schema.getGlobalDescribe().get(obj).getDescribe().fields.getMap();
		if(collectedFields == NULL){
			collectedFields = mapEventFields.keySet();
		}
		for(String collectedField : collectedFields){
			if(mapEventFields.get(collectedField) != NULL && mapEventFields.get(collectedField).getDescribe().isAccessible()){
				result.add(pref + collectedField);
			}
		}
		return result;
	}

	// inUserId - user to proccess
	// inGroupContolId - group control to reference
	// inMode - action mode
	public static ConnectApi.GroupMembershipType membership(String inUserId, String inGroupContolId, String inMode) {
		return CommunityHelperWithoutSharing.membershipWOSH(inUserId,inGroupContolId,inMode);
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
			ga.lnkStyle = 'gr-plus';
			ga.lnkIcon = 'fa-star';
		}
		else if (groupRole == ConnectApi.GroupMembershipType.GroupManager) {
			ga.btnLabel = Label.LBL_Manager;
			ga.btnIcon = 'fa-star-half-o';
			ga.title = Label.LBL_Leave_Group;
			ga.action = '2';
			ga.btnStyle = '';
			ga.lnkStyle = 'gr-plus';
			ga.lnkIcon = 'fa-star-half-o';
		}
		else if (groupRole == ConnectApi.GroupMembershipType.StandardMember) {
			ga.btnLabel = Label.LBL_Member;
			ga.btnIcon = 'fa-check';
			ga.title = Label.LBL_Leave_Group;
			ga.action = '2';
			ga.btnStyle = '';
			ga.lnkIcon = 'fa-check-circle';
			ga.lnkStyle = 'gr-plus';
		}
		else if (groupRole == ConnectApi.GroupMembershipType.NotAMember) {
			if (publicGroup) {
				ga.btnLabel = Label.BTN_Join;
				ga.title = Label.BTN_Join;
				ga.action = '1';
				ga.lnkIcon = 'fa-plus-circle';
			}
			else {
				ga.btnLabel = Label.LBL_RequestToJoin;
				ga.title = Label.LBL_RequestToJoin;
				ga.action = '5';
				ga.lnkIcon = 'fa-minus-circle';
			}
			ga.btnStyle = ' btn-u-blue';
			ga.btnIcon = 'fa-plus-circle';
			ga.lnkStyle = 'bl-plus';
		}
		else if (groupRole == ConnectApi.GroupMembershipType.NotAMemberPrivateRequested) {
			ga.btnLabel = Label.LBL_Requested;
			ga.btnIcon = 'fa-times-circle';
			ga.title = Label.LBL_Leave_Group;
			ga.action = '6';
			ga.btnStyle = ' btn-u-orange';
			ga.lnkStyle = 'or-plus';
			ga.lnkIcon = 'fa-times-circle';
		}
		return ga;
	}

	//method for insert prefix if not in feedItem
	public static String checkURLforPref(String inUrl){
		String spp = Site.getPathPrefix();
		
		if(String.isNotBlank(spp)){
			inUrl = (inUrl.startsWith('/') && !inUrl.startsWith(Site.getPathPrefix())) ? spp + inUrl : inUrl;
		}else{
			inUrl = (inUrl.startsWith('/') && inUrl.split('/').size() > 2) ? inUrl.split('/',3)[2] : inUrl;
		}
		return inUrl;
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
	
	/*
	* metod for getting Available Groups to user (it means he is a member of group )
	*/
	public static List<String> getNamesOfAvailableGroups(List<String> groupIds){
		List<String> groupsNames = new List<String>();
		try {
			List<ConnectApi.BatchResult> batchResults = ConnectApi.ChatterGroups.getGroupBatch(Network.getNetworkId(),groupIds);
			for(ConnectApi.BatchResult batchResult : batchResults){
				if (batchResult.isSuccess()) {
					ConnectApi.ChatterGroup aGroup = (ConnectApi.ChatterGroup) batchResult.getResult();
					if((String.valueOf(aGroup.myRole) != 'NotAMember' 
						&& String.valueOf(aGroup.myRole) != 'NotAMemberPrivateRequested' 
						&& String.valueOf(aGroup.visibility) == 'PrivateAccess') || String.valueOf(aGroup.visibility) == 'PublicAccess'){
						groupsNames.add(aGroup.name);
					}
				}
				else {
					// Operation failed. Print errors.
					System.debug('FAILURE');
					System.debug(batchResult.getErrorMessage());
				}
			}
		}
		catch(Exception e){
			System.debug('FAILURE: '+e.getMessage());
		}
		return groupsNames;
	}

	public static Boolean checkAPIEnable (){

		return [SELECT ID, PermissionsApiEnabled FROM Profile WHERE ID = :Userinfo.getProfileId() LIMIT 1].PermissionsApiEnabled; 
	}

	public static Map<String,Boolean> checkCRUDforObject (String objName){
		Map<String, Boolean> result = new Map<String, Boolean>();
		Schema.DescribeSObjectResult obj = Schema.getGlobalDescribe().get(objName).getDescribe();
		
		result.put('isCreateable',obj.isCreateable());
		result.put('isAccessible',obj.isAccessible());
		result.put('isUpdateable',obj.isUpdateable());
		result.put('isDeletable',obj.isDeletable());


		return result;
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
		public String lnkIcon { get; set; }
		public String lnkStyle { get; set; }
	}
}
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
		ConnectApi.GroupMembershipType resultType;
		Integer inmm = Integer.valueOf(inMode);
		Community_Group_Control__c cgc = [SELECT Id, Chatter_Group_ID__c FROM Community_Group_Control__c WHERE Id =:inGroupContolId];
		List<CollaborationGroupMember> cgmList = [SELECT Id, CollaborationRole FROM CollaborationGroupMember WHERE MemberId =:inUserId AND CollaborationGroupId =:cgc.Chatter_Group_ID__c];
		// 1 - Create Chatter Group Member
		// 2 - Delete Chatter Group Member
		if (inmm < 3) {
			if (inmm == 2) {
				// delete manager if exist
				List<Community_Group_Manager__c> cgmList2 = [SELECT Id FROM Community_Group_Manager__c WHERE Group_Manager_User__c =:inUserId AND Group_Control__c =:cgc.Id];
				List<EntitySubscription> esList2 = [SELECT Id FROM EntitySubscription WHERE ParentId = :cgc.Id AND SubscriberId = :inUserId LIMIT 1];
				delete cgmList2;
				delete esList2;
				if (cgmList.size() > 0 && cgmList[0].CollaborationRole == 'Admin') {
					cgmList[0].CollaborationRole = 'Standard';
					update cgmList;
				}
				resultType = ConnectApi.GroupMembershipType.StandardMember;
				//
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
			List<EntitySubscription> esList2 = [SELECT Id FROM EntitySubscription WHERE ParentId = :cgc.Id AND SubscriberId = :inUserId LIMIT 1];
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
			List<ConnectApi.BatchResult> batchResults = ConnectApi.ChatterGroups.getGroupBatch(Network.getNetworkId(), groupIds);
			for(ConnectApi.BatchResult batchResult : batchResults){
			if (batchResult.isSuccess()) {
		           ConnectApi.ChatterGroup aGroup = (ConnectApi.ChatterGroup) batchResult.getResult();
		           if((String.valueOf(aGroup.myRole) != 'NotAMember' 
		            && String.valueOf(aGroup.myRole) != 'NotAMemberPrivateRequested' 
		            && String.valueOf(aGroup.visibility) == 'PrivateAccess') || String.valueOf(aGroup.visibility) == 'PublicAccess') {
		            groupsNames.add(aGroup.name);
		           }
			   }		      
		   }
		} 
		catch(Exception e) {
		  	System.debug('FAILURE: '+e.getMessage());
		}
		return groupsNames;
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

	public static void test1() {
		System.Debug('TEST 4 RUN!!!!!!!!!!!!!!!!');
		Community_Theme__c cth = new Community_Theme__c(Name='t',Theme_Type__c='Interest');
		insert cth;
		Community_Tag__c ct = new Community_Tag__c(Name='t',Community_Theme__c=cth.Id);
		insert ct;
		//add user and account
		Account acc = new Account(Name='testAccount');
		insert acc;
		Account acc2 = new Account(Name='testAccount2');
		insert acc2;
		Contact con = new Contact(LastName='TCLN', MailingPostalCode='99013', email='testc@testdomain.com', AccountId=acc.Id, Primary_Role__c='Student');
		insert con;
		Contact con2 = new Contact(LastName='TCLN2', MailingPostalCode='99013', email='testc2@testdomain.com', AccountId=acc2.Id, Primary_Role__c='Student');
		insert con2;
		Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		Profile profile2 = [SELECT Id FROM Profile WHERE Name = 'Chatter Free User'];
		User u1 = new User(alias='alias', email='email1@email.com', emailencodingkey='UTF-8', lastname='lastname', firstname = 'firstName', languagelocalekey='en_US',
			localesidkey='en_US', profileid = profile.Id, timezonesidkey='America/Los_Angeles', username='ttsde.tedf1@testmail.com',
			FederationIdentifier='TestContactName.TestContactLastname2', Community_Contact_ID__c=con.Id);
		insert u1;
		User u2 = new User(alias='alias', email='emai345l2@email.com', emailencodingkey='UTF-8', lastname='lastn4ame2', firstname = 'firstName2', languagelocalekey='en_US',
			localesidkey='en_US', profileid = profile2.Id, timezonesidkey='America/Los_Angeles', username='ttsde.tedf2@testmail.com',
			FederationIdentifier='TestCon3456tactName.TestContactLastname2', Community_Contact_ID__c=con2.Id);
		insert u2;
		System.runAs(u2) {
			CommunityUtils.isModifyAllData();
			CommunityUtils.isViewAllData();
			CommunityUtils.canCreateGroup();
			CommunityUtils.getPackagePrefix();
		}
		System.runAs(u1) {
	        // The following code runs as user 'u' 
	        System.debug('Current User: ' + UserInfo.getUserName());
	        System.debug('Current Profile: ' + UserInfo.getProfileId()); 
	      			
			CommunityUtils.isModifyAllData();
			CommunityUtils.isViewAllData();
			CommunityUtils.canCreateGroup();
			CommunityUtils.getPackagePrefix();
			
			CommunityUtils.getActionButton(ConnectApi.GroupMembershipType.GroupOwner, TRUE);
			CommunityUtils.getActionButton(ConnectApi.GroupMembershipType.GroupManager, TRUE);
			CommunityUtils.getActionButton(ConnectApi.GroupMembershipType.StandardMember, TRUE);
			CommunityUtils.getActionButton(ConnectApi.GroupMembershipType.NotAMember, TRUE);
			CommunityUtils.getActionButton(ConnectApi.GroupMembershipType.NotAMemberPrivateRequested, TRUE);
			
			CommunityUtils.getActionButton(ConnectApi.GroupMembershipType.GroupOwner, FALSE);
			CommunityUtils.getActionButton(ConnectApi.GroupMembershipType.GroupManager, FALSE);
			CommunityUtils.getActionButton(ConnectApi.GroupMembershipType.StandardMember, FALSE);
			CommunityUtils.getActionButton(ConnectApi.GroupMembershipType.NotAMember, FALSE);
			CommunityUtils.getActionButton(ConnectApi.GroupMembershipType.NotAMemberPrivateRequested, FALSE);
						
			CommunityUtils.subscriberUser(u2.Id,TRUE);
			CommunityUtils.subscriberUser(u2.Id,FALSE);	
			
			GroupAction ga = new GroupAction();
			ga.btnLabel = '1';
			ga.btnIcon = '2';
			ga.title = '3';
			ga.action = '4';
			ga.btnStyle = '5';
			ga.groupId = '6';
			ga.memberCount = '7';
			ga.lnkIcon = '8';
			ga.lnkStyle = '9';			
			
			List<Community_Group_Control__c> availibleGroupsControll = [SELECT Chatter_Group_ID__c, Id
	                 FROM Community_Group_Control__c
	                 WHERE Status__c = 'Approved'];
			List<String> groupIds = new List<String>();
			for (Community_Group_Control__c aGroup : availibleGroupsControll){
			    groupIds.add(aGroup.Chatter_Group_ID__c); 
			}		
			getNamesOfAvailableGroups(groupIds);
			
			
			List<String> checkFieldList = new List<String> {'Building__c', 'Room__c', 'Street_Address__c', 'City__c', 'State__c', 'Zip__c'};
			Set<String> checkFieldSet = new Set<String>();
			checkFieldSet.addAll(checkFieldList);
			checkFieldSet = CommunityUtils.checkFLSFields('Community_Events__c', checkFieldSet);
			checkFieldSet = CommunityUtils.checkFLSFields('Community_Events__c', null);
			
			string year = '2008';
			string month = '10';
			string day = '5';
			string hour = '12';
			string minute = '20';
			string second = '20';
			string stringDate = year + '-' + month + '-' + day + ' ' + hour + ':' 
			    + minute +  ':' + second;
			
			CommunityUtils.checkNewsOverlapInterval(' IsDeleted=false ', Datetime.valueOf(stringDate), Datetime.valueOf(stringDate));
			CommunityUtils.checkNewsOverlapInterval(' IsDeleted=false ', null, Datetime.valueOf(stringDate));
			CommunityUtils.checkNewsOverlapInterval(' IsDeleted=false ', Datetime.valueOf(stringDate), null);
			
			Test.setCurrentPage(Page.CommunityHome);		
			CommunityUtils.checkUrl('   ');
			CommunityUtils.checkUrl('/profilephoto/0F9/F');
			CommunityUtils.checkUrl('motivisSKL/profilephoto/0F9/F');
			
			Map<Id,String> contactToRoleMap = new Map<Id,String>();
			contactToRoleMap.put(con.Id, con.Primary_Role__c);
			CommunityUtils.checkPrimaryProfile(contactToRoleMap);
			
			ApexPages.StandardController stdctrl = new ApexPages.StandardController( new Community_News__c ( Id=[select id from Community_News__c limit 1][0].Id ) );
			Community_News__c newsLocal = (Community_News__c)stdctrl.getRecord();
			PageReference pr = CommunityUtils.checkRedirectToStandardView(newsLocal.Id);
			
			// 1 - Create Chatter Group Member
			// 2 - Delete Chatter Group Member
			// 3 - Create Group Manager
			// 4 - Delete Group Manager
			// 5 - Create Join Private Group Request
			// 6 - Delete Join Private Group Request
			// 7 - Accept Join Private Group Request
			// 8 - Decline Join Private Group Request
			
			CollaborationGroup cg = new CollaborationGroup();
			cg.Name = 'newgroup';
			cg.CollaborationType = 'Public' ;
			insert cg;			
			insert new Community_Group_Control__c(Name='1212t',Discoverable__c=true,Type__c='Public',Network__c='Internal', Chatter_Group_ID__c=cg.Id);
			Community_Group_Control__c control = [SELECT id FROM Community_Group_Control__c  Where Chatter_Group_ID__c =: cg.Id LIMIT 1];
			CommunityUtils.membership(UserInfo.getUserId(), control.Id, '1');
			CommunityUtils.membership(UserInfo.getUserId(), control.Id, '3');
			CommunityUtils.membership(UserInfo.getUserId(), control.Id, '5');
			CommunityUtils.getRequestJoinGroupCount(cg.Id) ;
		}
				
		/*
		Community_Group_Control__c control = [SELECT id, Name FROM Community_Group_Control__c Where Name = '1212t' LIMIT 1];
		System.Debug(control.Name);
		CommunityUtils.membership(UserInfo.getUserId(), control.Id, '1');
		CommunityUtils.membership(UserInfo.getUserId(), control.Id, '2');
		
		Id mainUser = UserInfo.getUserId();
		System.runAs(u1) {
			CommunityUtils.membership(mainUser, control.Id, '3');			
		}
		*/
		
	}

}
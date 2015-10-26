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

public without sharing class CommunityHelperWithoutSharing {
	public CommunityHelperWithoutSharing() {
		
	}
	public static String getCommunityGroupControl(ID chatterGroupId) {
		if(chatterGroupId != null) {
			List<Community_Group_Control__c> lgc = [SELECT ID,Name FROM Community_Group_Control__c Where Chatter_Group_ID__c = :chatterGroupId LIMIT 1];
			if(lgc.size()>0) return lgc[0].Id;
			else return null;
		}
		return null;
	}
	
	
	public static List<User> getCommunityUsers(String querySearchName, Integer queryLimit, List<String> listRequestedFields, String sortColumn, Boolean SortDitecrion) {
		String sortCol = sortColumn == null ? 'Name' : String.escapeSingleQuotes(sortColumn);
		String sortDir = SortDitecrion ? 'ASC':'DESC';
		List<User> uList = new List<User>();
		try {
			Set<Id> setNetworkMemberGroupId= new Set<Id>();
			for(NetworkMemberGroup item : [SELECT ParentId From NetworkMemberGroup Where NetworkId = :Network.getNetworkId() ]) {
				setNetworkMemberGroupId.add(item.ParentId);
			}
			Set<Id> setPermissionSetAssignmentID = new Set<Id>();
			for(PermissionSetAssignment item : [SELECT AssigneeId From PermissionSetAssignment Where PermissionSetID in :setNetworkMemberGroupId]) {
				setPermissionSetAssignmentID.add(item.AssigneeId);
			}
			querySearchName = querySearchName != null ? String.escapeSingleQuotes(querySearchName) : '%%';
			String UserId = (String) UserInfo.getUserId();
			String requiedFields = 'Id, Name';
			String requestedFields = ' ';
			if(listRequestedFields!=null) {
				for (String item:listRequestedFields){
					requestedFields += ' , ';
					requestedFields += item;
				}
			}
			String checkIfThisIsCommunityUser;
			if(Test.isRunningTest()){
				checkIfThisIsCommunityUser = ' ';
			}
			else {
				checkIfThisIsCommunityUser = +' AND (ProfileID in :setNetworkMemberGroupId OR Id in :setPermissionSetAssignmentID )';
			}
			String queryString	= 'SELECT '
				+ requiedFields
				+ requestedFields
				+' FROM User'
				+' WHERE (ContactId != NULL OR Community_Contact_ID__c != NULL) AND isActive = true'
				+' AND Id != :UserId'
				+' AND (FirstName LIKE :querySearchName OR LastName LIKE :querySearchName OR Name LIKE :querySearchName)'
				+ checkIfThisIsCommunityUser
				+' ORDER BY '+sortCol + ' ' + sortDir
				+' LIMIT :queryLimit';
				System.debug(queryString);
			uList = Database.query(queryString);
		}
		catch (Exception e) {
			System.debug(e);
		}
		return uList;
	}
	
	
	// used for CommunityNewsController
	public static String ImageLibFolder() {
		Community_Settings__c cs = Community_Settings__c.getInstance();			
		if(String.isNotBlank(cs.Image_Library_Folder__c)) {
		    List<sObject> folders = [SELECT Id, Name, DeveloperName FROM Folder where DeveloperName = :String.valueOf(cs.Image_Library_Folder__c)  Limit 1];
		    return folders.size()>0?folders[0].Id:null;	
		}
		return null;
	}
	

// used for CommunityHomeNotificationController
	public static List<FeedItem> getFeeds(Set<Id> controlsIds, String userId){
		String queryUserId = String.escapeSingleQuotes(userId);
		return [SELECT Id, ParentId, Type, CommentCount, LinkUrl, LastModifiedDate, CreatedById, Visibility 
				FROM FeedItem
				WHERE ParentId IN :controlsIds 
				AND CreatedById != :queryUserId
				AND Visibility = 'AllUsers'
				LIMIT 10000];
		}

// used for CommunityGroupManageController
	public static Integer getOverallActivity(String chatterGroupId){
		String queryChatterGroupId = String.escapeSingleQuotes(chatterGroupId);
		return [SELECT COUNT() FROM FeedItem WHERE ParentId = :queryChatterGroupId];
	}

	public static Integer getPostsThisWeek(String chatterGroupId){
		String queryChatterGroupId = String.escapeSingleQuotes(chatterGroupId);
		return [SELECT COUNT() FROM FeedItem WHERE ParentId = :queryChatterGroupId AND CreatedDate = THIS_WEEK];
	}

	public static Integer getPostThisMonth(String chatterGroupId){
		String queryChatterGroupId = String.escapeSingleQuotes(chatterGroupId);
		return [SELECT COUNT() FROM FeedItem WHERE ParentId = :queryChatterGroupId AND CreatedDate = THIS_MONTH];
	}

// used for CommunityGroupFilesController
	public static List<FeedItem> getFeeds(String chatterGroupId){
		String queryChatterGroupId = String.escapeSingleQuotes(chatterGroupId);
		String fQuery = 'SELECT Id, CreatedById, CreatedBy.Name, ContentFileName, LastModifiedDate FROM FeedItem';
		fQuery += ' WHERE Type = \'ContentPost\' AND ParentId = :queryChatterGroupId LIMIT 500';
		return Database.query(fQuery);
	}

// used for CommunityFeedController
	public static Attachment getAttachment(String attachId){
		String queryAttachId = String.escapeSingleQuotes(attachId);
		return [SELECT Id, Name, ContentType, Body, Description FROM Attachment WHERE Id = :queryAttachId LIMIT 1];
	}

	public static void deleteAttachment(List<Attachment> attachments){
		delete attachments;
	}

	public static ConnectApi.GroupMembershipType membershipWOSH(String inUserId, String inGroupContolId, String inMode) {
		ConnectApi.GroupMembershipType resultType;
		Integer inmm = Integer.valueOf(inMode);
		String queryInGroupContolId = String.escapeSingleQuotes(inGroupContolId);
		String queryInUserId = String.escapeSingleQuotes(inUserId);
		Community_Group_Control__c cgc = [SELECT Id, Chatter_Group_ID__c FROM Community_Group_Control__c WHERE Id = :queryInGroupContolId];
		List<CollaborationGroupMember> cgmList = [SELECT Id, CollaborationRole FROM CollaborationGroupMember WHERE MemberId =:queryInUserId AND CollaborationGroupId =:cgc.Chatter_Group_ID__c];
		// 1 - Create Chatter Group Member
		// 2 - Delete Chatter Group Member
		if (inmm < 3) {
			if (inmm == 2) {
				// delete manager if exist
				List<Community_Group_Manager__c> cgmList2 = [SELECT Id FROM Community_Group_Manager__c WHERE Group_Manager_User__c =:queryInUserId AND Group_Control__c =:cgc.Id];
				List<EntitySubscription> esList2 = [SELECT Id FROM EntitySubscription WHERE ParentId = :cgc.Id AND SubscriberId = :queryInUserId LIMIT 1];
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
				NetworkMember nm = [SELECT Id, DefaultGroupNotificationFrequency FROM NetworkMember WHERE MemberId = :queryInUserId AND NetworkId = :Network.getNetworkId()];
				insert new CollaborationGroupMember(MemberId = inUserId, CollaborationGroupId = cgc.Chatter_Group_ID__c, NotificationFrequency = nm.DefaultGroupNotificationFrequency);
				resultType = ConnectApi.GroupMembershipType.StandardMember;
			}
		}
		// 3 - Create Group Manager
		// 4 - Delete Group Manager
		else if (inmm < 5) {
			List<Community_Group_Manager__c> cgmList2 = [SELECT Id FROM Community_Group_Manager__c WHERE Group_Manager_User__c =:queryInUserId AND Group_Control__c =:cgc.Id];
			List<EntitySubscription> esList2 = [SELECT Id FROM EntitySubscription WHERE ParentId = :cgc.Id AND SubscriberId = :queryInUserId LIMIT 1];
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
					NetworkMember nm = [SELECT Id, DefaultGroupNotificationFrequency FROM NetworkMember WHERE MemberId = :queryInUserId AND NetworkId = :Network.getNetworkId()];
					insert new CollaborationGroupMember(MemberId = inUserId, CollaborationGroupId = cgc.Chatter_Group_ID__c, NotificationFrequency = nm.DefaultGroupNotificationFrequency);
				}
				else if (cgmList[0].CollaborationRole == 'Standard') {
					cgmList[0].CollaborationRole = 'Admin';
					update cgmList;
				}
				if (cgmList2.size() == 0) {
					insert new Community_Group_Manager__c(Group_Manager_User__c = inUserId, Group_Control__c = cgc.Id, Manager_Role__c = 'Manager');
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
			List<CollaborationGroupMemberRequest> cgmrList = [SELECT Id FROM CollaborationGroupMemberRequest WHERE CollaborationGroupId =:cgc.Chatter_Group_ID__c AND RequesterId =:queryInUserId AND Status = 'Pending'];
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
			List<CollaborationGroupMemberRequest> cgmrList = [SELECT Id, Status FROM CollaborationGroupMemberRequest WHERE CollaborationGroupId =:cgc.Chatter_Group_ID__c AND RequesterId =:queryInUserId AND Status = 'Pending'];
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
}

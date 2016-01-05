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

global with sharing class CommunityShareController {

	public String shareLinkUrl { get;set; }
	public String shareLinkName { get;set; }
	public String shareComment { get;set; }
	public String shareGroup { get;set; }
	public Boolean hasMessage { get { return hasMessage == NULL ? false : hasMessage; } set; }
	public String message { get; set; }
	public List<GroupFinderWrapper> availableGroups { get; set; }
	public List<GroupFinderWrapper> listGroupFindWrapper { get; set; }
	public Boolean availGroups {
		get {
			return availableGroups != NULL && !availableGroups.isEmpty();
		}
		set;
	}
	public SObject sobj {
		get;
		set {
			if (sobj == NULL) {
				sobj = value;
				init();
			}
		}
	}

	private void init() {
		if (sobj instanceof Community_Events__c) {
			shareLinkUrl = Page.CommunityEventDetail.getUrl().replace('/apex/','') + '?id=' + (String)sobj.get('Id');
			shareLinkName = (String)sobj.get('Name__c') + ' ' + (Datetime)sobj.get('Start__c');
		}
		else if (sobj instanceof Community_News__c) {
			shareLinkUrl = Page.CommunityNewsDetail.getUrl().replace('/apex/','') + '?id=' + (String)sobj.get('Id');
			shareLinkName = (String)sobj.get('Title__c');
		}
		availableGroups = getMyGroupsInGroupFinderWrapper(null, true);
	}

	//remote actions
	@RemoteAction
	global static String shareForGroups(String idsGroups, String shareComment, String shareLinkName, String sobjId, Boolean shareLinkProfile) {
		
		List<String> groupsIds = idsGroups.split(',');
		String shareLinkUrl;
		String message;
		String obj = String.valueOf(((Id)sobjId).getSObjectType());
		obj = obj.split('__').size() > 2 ? obj.split('__')[1] : obj.split('__')[0];
		if (obj.equalsIgnoreCase('Community_Events')) {
			shareLinkUrl = Page.CommunityEventDetail.getUrl().replace('/apex/','') + '?id=' + sobjId;
			shareLinkName = shareLinkName;
		}
		else {
			shareLinkUrl = Page.CommunityNewsDetail.getUrl().replace('/apex/','') + '?id=' +  sobjId;
			shareLinkName = shareLinkName;
		}
		try {
			Set<String> gcSet2 = new Set<String>();
			if (!SObjectType.Community_Group_Control__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Group_Control__c);
			for (Community_Group_Control__c cgc2 : [SELECT Chatter_Group_ID__c
													FROM Community_Group_Control__c
													WHERE Chatter_Group_ID__c IN :groupsIds
													AND Status__c = 'Approved']) {
				gcSet2.add(cgc2.Chatter_Group_ID__c);
			}
			String networkId = Network.getNetworkId();
			String cprefix = '';
			Network nRec;
			if(networkId!=null) {
				nRec = [SELECT UrlPathPrefix FROM Network WHERE Id = :Network.getNetworkId()];
				cprefix = nRec.UrlPathPrefix != null ? '/' + nRec.UrlPathPrefix + '/' : '/';
			}
			List<CollaborationGroup> cgrec = new List<CollaborationGroup>();

			if(gcSet2.isEmpty() && !shareLinkProfile){
				return 'ERR ' + Label.LBL_No_share_destination;
			}
			else if(!gcSet2.isEmpty()){
				if (!SObjectType.CollaborationGroup.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.CollaborationGroup);
				cgrec = [ SELECT Id, NetworkId
						FROM CollaborationGroup
						WHERE NetworkId = :Network.getNetworkId() AND Id IN :gcSet2
						];
			}
			if(shareLinkProfile){
				//insert
				FeedItem feed = new FeedItem (
									LinkUrl = cprefix + shareLinkUrl,
									Title = shareLinkName,
									ParentId = UserInfo.getUserId(),
									NetworkScope = Network.getNetworkId(),
									Body = shareComment	);
				CommunityAccess.InsertWithoutSharing(
					feed,
					'CommunityShareController.cls [shareForGroups]',
					new List<Schema.DescribeFieldResult> {
						FeedItem.LinkUrl.getDescribe(),
						FeedItem.Title.getDescribe(),
						FeedItem.Body.getDescribe()
					}
				);
				message	= 'SUCCESS';
			}
			if (!cgrec.isEmpty()) {
				List<FeedItem> shareFeeds = new List<FeedItem>();
				for(CollaborationGroup gr : cgrec){
					shareFeeds.add(
						new FeedItem (
									LinkUrl = cprefix + shareLinkUrl,
									Title = shareLinkName,
									ParentId = gr.Id,
									NetworkScope = gr.NetworkId,
									Body = shareComment	)
					);
				}
				//insert shareFeeds;
				CommunityAccess.InsertWithoutSharing(
					shareFeeds,
					'CommunityShareController.cls [shareForGroups]',
					new List<Schema.DescribeFieldResult> {
						FeedItem.LinkUrl.getDescribe(),
						FeedItem.Title.getDescribe(),
						FeedItem.Body.getDescribe()
					}
				);
				message	= 'SUCCESS';
			}
			else if(!shareLinkProfile){
				return 'ERR Something wrong with group name';
			}
		}
		catch(Exception e) {
			return 'ERR ' + e.getMessage();
		}
		return message;
	}

	public void availableGroupsProcess(){
		Map<Id, String> cGroups = new Map<Id, String>();
		if (!SObjectType.CollaborationGroup.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.CollaborationGroup);
		List<CollaborationGroup> groups = [SELECT Id, Name, CollaborationType, NetworkId FROM CollaborationGroup WHERE NetworkId =:Network.getNetworkId()];
		List<String> groupsNames = new List<String>();

		// Create a list of group IDs.
		List<String> groupIds = new List<String>();
		for (CollaborationGroup aGroup : groups){
			groupIds.add(aGroup.id); 
		}

		if(groupIds.isEmpty()) return;

		groupsNames = getNamesOfAvailableGroups(groupIds);

		Set<String> groupsNamesSet = new Set<String>();
		groupsNamesSet.addAll(groupsNames);
		for (CollaborationGroup aGroup : groups){
			if(groupsNamesSet.contains(aGroup.Name)){
				cGroups.put(aGroup.Id, aGroup.Name);
			}
		}

		Set<Id> cGroupsIds = cGroups.keySet();
		if (!SObjectType.Community_Group_Control__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Group_Control__c);
		List<Community_Group_Control__c> availibleGroupsControll = [SELECT Chatter_Group_ID__c, Id
																	FROM Community_Group_Control__c
																	WHERE Chatter_Group_ID__c IN :cGroupsIds
																	AND Status__c = 'Approved'];
		Map<Id, Id> cgiCGC = new Map<Id, Id>();
		for(Community_Group_Control__c availibleGC : availibleGroupsControll){
			cgiCGC.put(availibleGC.Id, availibleGC.Chatter_Group_ID__c);
		}

		Set<Id> availibleGCIds = new Set<Id>();
		availibleGCIds.addAll(cgiCGC.keySet());
		if (!SObjectType.Community_Group_Control_Tag__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Group_Control_Tag__c);
		List<Community_Group_Control_Tag__c> groupControlTags = [SELECT Group_Control__c, Community_Tag__r.Theme_Name__c 
																FROM Community_Group_Control_Tag__c 
																WHERE Group_Control__c IN :availibleGCIds ORDER BY Community_Tag__r.Theme_Name__c];
		Map<String, Set<Id>> tagsControllIdAndName = new Map<String, Set<Id>>();
		for(Community_Group_Control_Tag__c groupControlTag : groupControlTags){
			if(tagsControllIdAndName.get(groupControlTag.Community_Tag__r.Theme_Name__c) != null){
				tagsControllIdAndName.get(groupControlTag.Community_Tag__r.Theme_Name__c).add(groupControlTag.Group_Control__c);
			}else{
				tagsControllIdAndName.put(groupControlTag.Community_Tag__r.Theme_Name__c, new Set<Id>{groupControlTag.Group_Control__c});
			}
		}

		List<TagsForGroup> tagsForGroups = new List<TagsForGroup>();
		Set<Id> tControlls = new Set<Id>();
		for(String themeName : tagsControllIdAndName.keySet()){
			List<GroupFinderWrapper> wrappers = new List<GroupFinderWrapper>();
			for(Id tControll : tagsControllIdAndName.get(themeName)){
				wrappers.add(new GroupFinderWrapper(cGroups.get(cgiCGC.get(tControll)), cgiCGC.get(tControll)));
				tControlls.add(tControll);
			}
			wrappers.sort();
			tagsForGroups.add(new TagsForGroup(themeName, wrappers));
		}
		List<GroupFinderWrapper> wrapper = new List<GroupFinderWrapper>();
		for(Id gc : cgiCGC.keySet()){
			if(!tControlls.contains(gc)){
				wrapper.add(new GroupFinderWrapper(cGroups.get(cgiCGC.get(gc)), cgiCGC.get(gc)));
			}
		}
		
		tagsForGroups.sort();
		if(!wrapper.isEmpty()) {
			tagsForGroups.add(new TagsForGroup(Label.LBL_Other, wrapper));
		}
		listGroupFindWrapper = new List<GroupFinderWrapper>();
		for (TagsForGroup tfg : tagsForGroups) {
			for (GroupFinderWrapper gfw : tfg.wrapperGroup) {
				listGroupFindWrapper.add(gfw);
			}
		}
		listGroupFindWrapper.sort();
	}

	public static List<String> getNamesOfAvailableGroups(List<String> groupIds){

		List<String> groupsNames = new List<String>();
		try {
			Boolean hasShareAllGroups = CommunityUtils.isModifyAllData();
			List<ConnectApi.BatchResult> batchResults = ConnectApi.ChatterGroups.getGroupBatch(Network.getNetworkId(), groupIds);
			for (ConnectApi.BatchResult batchResult : batchResults) {
				if (batchResult.isSuccess()) {
					ConnectApi.ChatterGroup aGroup = (ConnectApi.ChatterGroup) batchResult.getResult();
					if (hasShareAllGroups || (String.valueOf(aGroup.myRole) != 'NotAMember' && String.valueOf(aGroup.myRole) != 'NotAMemberPrivateRequested')) {
						groupsNames.add(aGroup.name);
					}
				}
				else {
					System.debug('FAILURE');
					System.debug(batchResult.getErrorMessage());
				}
			}
		} catch (Exception e){
			System.debug('FAILURE: '+e.getMessage());
		}
		return groupsNames;
	}
	
	
	public static List<GroupFinderWrapper> getMyGroupsInGroupFinderWrapper(String query, Boolean onlyMember){
		List<GroupFinderWrapper> groupsNames = new List<GroupFinderWrapper>();
		List<CollaborationGroup> cgList = getAvailableCollaborationGroupList(query, onlyMember);
		for (CollaborationGroup cgItem : cgList) {
			groupsNames.add(new GroupFinderWrapper(cgItem.Name, cgItem.Id));
		}
		return groupsNames;
	}

	public static List<CollaborationGroup> getAvailableCollaborationGroupList(String search, Boolean onlyMember) {
		String querySearch = String.isBlank(search) ? '%%' : '%' + String.escapeSingleQuotes(search) + '%';
		Set<Id> filtredGroupIds = new Set<Id>();
		if (!SObjectType.Community_Group_Control__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Group_Control__c);
		for (Community_Group_Control__c gcItem : [SELECT Chatter_Group_ID__c FROM Community_Group_Control__c WHERE Status__c = 'Approved' AND Name LIKE :querySearch LIMIT 100]) {
			filtredGroupIds.add(gcItem.Chatter_Group_ID__c);
		}
		if (!SObjectType.CollaborationGroup.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.CollaborationGroup);
		if (!SObjectType.CollaborationGroupMember.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.CollaborationGroupMember);
		return onlyMember == false && CommunityUtils.isModifyAllData() ? [SELECT Id, Name FROM CollaborationGroup WHERE NetworkId = :Network.getNetworkId() AND Id IN :filtredGroupIds AND IsArchived = false ORDER BY Name ASC LIMIT 100] : [SELECT Id, Name FROM CollaborationGroup WHERE NetworkId = :Network.getNetworkId() AND Id IN :filtredGroupIds AND Id IN (SELECT CollaborationGroupId FROM CollaborationGroupMember WHERE MemberId = :UserInfo.getUserId()) AND IsArchived = false ORDER BY Name ASC LIMIT 100];
	}


	//remote actions
	@RemoteAction
	global static String getGroups(String query) {
		String result = '';
		Set<String> gcSet = new Set<String>();
		if (!SObjectType.Community_Group_Control__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Group_Control__c);
		for (Community_Group_Control__c cgc : [SELECT Chatter_Group_ID__c FROM Community_Group_Control__c WHERE Chatter_Group_ID__c != NULL AND Status__c = 'Approved']) {
			gcSet.add(cgc.Chatter_Group_ID__c);
		}
		if (!SObjectType.CollaborationGroup.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.CollaborationGroup);
		for (CollaborationGroup cg : [SELECT Name FROM CollaborationGroup WHERE Id IN :gcSet AND NetworkId = :Network.getNetworkId()]) {
			result += '<option value="' + cg.Name + '"></option>';
		}
		return result;
	}

	@RemoteAction
	global static String getGroupsSelector(String getGroupsSelector) {
		return JSON.serialize(getMyGroupsInGroupFinderWrapper(getGroupsSelector, false));
	}

	global class TagsForGroup implements Comparable{
		public List<GroupFinderWrapper> wrapperGroup {get; set;}
		public String TagName {get; set;}

		TagsForGroup(String inTagName, List<GroupFinderWrapper> inWrapperGroup){
			this.TagName = inTagName;
			this.wrapperGroup = inWrapperGroup;
		}

		global Integer compareTo(Object compareTo) {
			TagsForGroup compareToEmp = (TagsForGroup)compareTo;
			if (this.TagName == compareToEmp.TagName) return 0;
			return (this.TagName > compareToEmp.TagName) ? 1 : -1;
		}
	}

	global class GroupFinderWrapper implements Comparable{
		public String name { get; set; }
		public Id id { get; set;}

		GroupFinderWrapper(String inName, Id inId){
			this.name = inName;
			this.id = inId;
		}

		global Integer compareTo(Object compareTo) {
			GroupFinderWrapper compareToEmp = (GroupFinderWrapper)compareTo;
			if (this.name == compareToEmp.name) return 0;
			return (this.name > compareToEmp.name) ? 1 : -1;
		}
	}

}
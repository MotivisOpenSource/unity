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

global with sharing class CommunityFeedController {

	private static Integer RECENT_COMMENT_COUNT = 3;
	private static Integer PAGE_SIZE = 8;

	public static String testResult;
	public static String feedElIdForTest;
	public static String topicId { get;set; }
	public static String currentUserId { get{ return UserInfo.getUserId();} set;}
	public static Boolean fromEmail { get; set; }
	public static String feedfromEmailId { get; set; }
	public static Map<String, String> parentManagerId { get; set;}
	public Boolean grID { get; set; }
	public Boolean hideEventBtn { get { return hideEventBtn == true; } set; }
	public String parentId { get { return parentId == NULL ? UserInfo.getUserId() : parentId; } set; }
	public String feedType { get;set; }
	public Boolean fullMode { get;set; }
	public Boolean showFileUpload { get;set; }
	public String packagePrefix { get{ return CommunityUtils.getPackagePrefix();} }
	public Boolean isTopicCreateable { get{ return CommunityUtils.checkCRUDforObject('Topic').get('isCreateable');} }
	public Boolean isTopicAssignmentCreateable { get{ return CommunityUtils.checkCRUDforObject('TopicAssignment').get('isCreateable');} }
	public Boolean muteShowTooltip { get; set; }
    public Boolean isMuteShow { 
        get{
            if(ApexPages.currentPage().getUrl().containsIgnoreCase('CommunityFeed_MyFeed')){
                muteShowTooltip = feedType == '1' ? true : false;
                return feedType == '1' || feedType == '4';
            }
            return false;
        } 
    }
	public class UnityFeedException extends Exception {}
	public String parentIdForAtt {
		get {
			try {
				if (!SObjectType.User.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.User);
				User us = [SELECT Id, ContactId, Community_Contact_ID__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
				String contId = (us.ContactId != null) ? us.ContactId : us.Community_Contact_ID__c;
				if(contId != null) {
					String queryContId = CommunityUtils.validateId(contId);
					if (!SObjectType.Community_Profile__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Profile__c);
					List<Community_Profile__c> cpl = [SELECT Id FROM Community_Profile__c WHERE Contact__c = :queryContId LIMIT 1]; 
					if(cpl.size()>0) return cpl[0].Id;
				}
				return null;
			}
			catch(Exception ex) {
				return null;
			}
		}
		set;
	}
	public String NetworkId {
		get { 
		if(!parentId.startsWith('0F9') && (String.isBlank(feedType) || feedType == '4' || feedType == '5')){
			return 'AllNetworks';
			} else {
			return Network.getNetworkId();
		}
		}
		set;
	}
// must be deleted
	public String communityPrefix {
		get {
			String nwid = Network.getNetworkId();
			String servUrl = URL.getSalesforceBaseUrl().toExternalForm();
			if (!String.isBlank(nwid)) {
				nwid = Network.getLoginUrl(nwid);
				nwid = nwid.replace(servURL + '/', '');
				nwid = nwid.replace(servURL, '');
				nwid = nwid.split('/')[0];
				servUrl+= '/' + nwid;
			}

			return servUrl;
		}
		set;
	}

	public String currentUserPhoto {
		get {
            return ConnectApi.UserProfiles.getPhoto(Network.getNetworkId(),'me').smallPhotoUrl;
            //return ConnectApi.UserProfiles.getPhoto(Network.getNetworkId(),'me').smallPhotoUrl;
		}
	}

	//get feeds
	@RemoteAction
	global static String feeds(String inParentId, String inFeedType, String inPageToken) {
		FeedElementPage pf = pullFeeds(inParentId, inFeedType, inPageToken);
		if(Test.isRunningTest()){
			return testResult;
		}
		return json.serialize(pf);
	}

	//get feeds from topic
	@RemoteAction
	global static String feedsForTopics(Map<String, String> params) {
		String inParentId = params.get('parentId');
		String inFeedType = params.get('inFeedType');
		String inPageToken = params.get('inpt');
		topicId = params.get('topicId');
		FeedElementPage pf = pullFeedsForTopics(inParentId, inFeedType, inPageToken);
		if(Test.isRunningTest()){
			return testResult;
		}
		return json.serialize(pf);
	}

	//get one feed from email notification
	@RemoteAction
	global static String feedFromEmail(Map<String, String> params) {
		String inParentId = params.get('parentId');
		String inFeedType = params.get('inFeedType');
		String inPageToken = params.get('inpt');
		feedfromEmailId = params.get('feedId');
		Integer elementsPerBundle = 1;
		
		FeedElementPage fepResult = new FeedElementPage();
		fepResult.elements = new List<FeedElement>();
		String result;
		try{		
		ConnectApi.FeedElement fElement = ConnectApi.ChatterFeeds.getFeedElement(
											Network.getNetworkId(), 
											feedfromEmailId, 
											RECENT_COMMENT_COUNT, 
											elementsPerBundle);

			result = json.serialize(fElement);
		}catch(Exception ex){
            String sobjectName = ((Id)inParentId).getSObjectType().getDescribe().getName();
            Map<String, List<String>> parentTypeParentId = new Map<String, List<String>>{sobjectName => new List<String>{inParentId}};
            Map<String, List<String>> mapParents = getParentsNames(parentTypeParentId);
            String parentIdForObj;
            for(String key : mapParents.keySet()){
                if(key.containsIgnoreCase(inParentId)){
                    parentIdForObj = key;
                }
            }
            if(parentIdForObj == NULL){
                parentIdForObj = 'user';
                mapParents.put(parentIdForObj, new List<String>{null,null,null,prepareUrl(Page.CommunityFeed_MyFeed.getUrl())});
            }
            return json.serialize(mapParents.get(parentIdForObj)[3]);
		}
		FeedElement feResult = (FeedElement)JSON.deserialize(result,FeedElement.class);

		fepResult.elements.add(feResult);
		fepResult = initialRoles(fepResult);
		fepResult = initialParentId(fepResult);
		fepResult = initialTopics(fepResult);
		if(Test.isRunningTest()){
			return testResult;
		}
		
		return json.serialize(fepResult);
	}

	// feeds for topic
	private static FeedElementPage pullFeedsForTopics(String inParentId2, String inFeedType2, String inPageToken2) {
		
		Integer pageSize = PAGE_SIZE;

		List<String> feedsIds = new List<String>();
		Set<String> feedsParents = new Set<String>();
		Map<String, String> managersParent = new Map<String, String>();
		Map<String, String> customObjParent = new Map<String, String>();
		
		List<String> notManagerForGroups = new List<String>();
		Map<String, String> chatGroupIds = new Map<String, String>();
		Set<String> excludeIds = new Set<String>();
		Set<String> parentFollowingIds = new Set<String>();

		FeedElementPage fepResult = new FeedElementPage();
		fepResult.elements = new List<FeedElement>();

		String result = '';
		
		String queryTopicId = CommunityUtils.validateId(topicId);
		for(TopicAssignment topicA : [SELECT Id, NetworkId, TopicId, EntityId FROM TopicAssignment
										WHERE NetworkId =: Network.getNetworkId()
										AND TopicId =: queryTopicId LIMIT 1000]){
			feedsIds.add(topicA.EntityId);
		}
		if(inParentId2 != UserInfo.getUserId()){
			String queryInParentId2 = CommunityUtils.validateId(inParentId2);
			for(FeedItem fItem : [SELECT Id, ParentId FROM FeedItem WHERE Id IN :feedsIds AND ParentId =:queryInParentId2 LIMIT 1000]){
				feedsParents.add(fItem.Id);
				managersParent.put(fItem.Id, fItem.ParentId);
			}
		}
		else {
			for(FeedItem fItem : [SELECT Id, ParentId FROM FeedItem WHERE Id IN :feedsIds LIMIT 1000]){
				if(fItem.ParentId.getSObjectType().getDescribe().getName().containsIgnoreCase('Community_Group_Control')){
					managersParent.put(fItem.Id, fItem.ParentId);
				}
			}
		}
		if (!SObjectType.Community_Group_Manager__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Group_Manager__c);
		for(Community_Group_Manager__c cgm : [SELECT Id, Group_Control__c, Group_Control__r.Chatter_Group_ID__c,  
												Group_Manager_User__c, Manager_Role__c 
											FROM Community_Group_Manager__c
											WHERE Group_Control__r.Id IN :managersParent.values()
											]){
			chatGroupIds.put(cgm.Group_Control__r.Chatter_Group_ID__c, cgm.Group_Control__c);
		}
		List<String> inp = new List<String>();
		inp.addAll(chatGroupIds.keySet());
		notManagerForGroups = CommunityUtils.getIdsOfAvailableGroups(inp);
		for(String ids : notManagerForGroups){
			for(String key : managersParent.keySet()){
				if(managersParent.get(key) == chatGroupIds.get(ids)){
					excludeIds.add(key);
				}
			}			
		}
		// we use loop because ConnectApi retrieve specified number of records
		// and we can't determine which number we need (we should not display
		// managers feed, we exclude this)
		do{
			FeedElementPage fep = pullFeedsConnectApi(topicId, inFeedType2, inPageToken2, pageSize);
			for(FeedElement fe : fep.elements){
				if(feedsParents.isEmpty() && !excludeIds.contains(fe.Id)){
					fepResult.elements.add(fe);
				}else if(feedsParents.contains(fe.Id)){
					fepResult.elements.add(fe);
				}
			}
			fepResult.nextPageToken = fep.nextPageToken;
			inPageToken2 = fep.nextPageToken;
			pageSize = PAGE_SIZE - fepResult.elements.size();
		}while(fepResult.showMore && fepResult.elements.size() < PAGE_SIZE);
		fepResult = initialRoles(fepResult);
		fepResult = initialParentId(fepResult);
		fepResult = initialTopics(fepResult);
		return fepResult;
	}

	// ConnectApi function
	private static FeedElementPage pullFeedsConnectApi(String inParentId2, String inFeedType2, String inPageToken2, Integer pageSize) {
		ConnectApi.FeedElementPage fep = ConnectApi.ChatterFeeds.getFeedElementsFromFeed(
					Network.getNetworkId(),
					determineFeedType(inParentId2, inFeedType2),
					inParentId2,
					RECENT_COMMENT_COUNT,
					ConnectApi.FeedDensity.FewerUpdates,
					inPageToken2,
					pageSize,
					ConnectApi.FeedSortOrder.LastModifiedDateDesc
				);


		Schema.DescribeSObjectResult r = Community_Group_Control__c.sObjectType.getDescribe();
		String keyPrefix = r.getKeyPrefix();
		parentManagerId = new Map<String, String>();

		for(ConnectApi.FeedElement fe : fep.elements){
			if(fe.parent != NULL && fe.parent.id.substring(0, 3) == keyPrefix){
				parentManagerId.put(fe.id, fe.parent.id);
			}
		}
		String result = json.serialize(fep);
		FeedElementPage fepResult = (FeedElementPage)JSON.deserialize(result,FeedElementPage.class);

		return fepResult;
	}
	
	//feeds
	private static FeedElementPage pullFeeds(String inParentId2, String inFeedType2, String inPageToken2) {
		Integer pageSize = PAGE_SIZE;
		FeedElementPage fepResult = new FeedElementPage();
		fepResult.elements = new List<FeedElement>();

		Boolean hasShowManagerFeed = CommunityUtils.isViewAllData() || CommunityUtils.isModifyAllData();
		Map<String, String>	groupManagerMap = new Map<String, String>();
		List<Community_Group_Manager__c> cgmList = new List<Community_Group_Manager__c>();
		if (hasShowManagerFeed == false) {
			if (SObjectType.Community_Group_Manager__c.isAccessible()) {
				if (!SObjectType.Community_Group_Manager__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Group_Manager__c);
				cgmList = [SELECT Id, Group_Control__c, Manager_Role__c FROM Community_Group_Manager__c WHERE Group_Manager_User__c =: UserInfo.getUserId()];
			}
		}
		for(Community_Group_Manager__c cgm : cgmList){
			groupManagerMap.put(cgm.Group_Control__c, cgm.Manager_Role__c);
		}

		// we use loop because ConnectApi retrieve specified number of records
		// and we can't determine which number we need (we should not display
		// managers feed, we exclude this)
		do{
			FeedElementPage fep = pullFeedsConnectApi(inParentId2, inFeedType2, inPageToken2, pageSize);
			if (fep.elements.isEmpty()) {
				break;
			}

			for(FeedElement fel : fep.elements){
				if (parentManagerId.get(fel.id) == NULL || hasShowManagerFeed || groupManagerMap.get(parentManagerId.get(fel.id)) != NULL 
					|| CommunityUtils.isShowGroupManagerUser(parentManagerId.get(fel.id), true)){
					fepResult.elements.add(fel);
				}
			}
			fepResult.nextPageToken = fep.nextPageToken;
			inPageToken2 = fep.nextPageToken;
			pageSize = PAGE_SIZE - fepResult.elements.size();

		}while(fepResult.showMore && fepResult.elements.size() < PAGE_SIZE);
		
		fepResult = initialRoles(fepResult);
		fepResult = initialParentId(fepResult);
		fepResult = initialTopics(fepResult);
		
		return fepResult;
	}

	// need to determined roles
	public static List<String> getUsersIdsForElement(FeedElementPage currentFEP, Page2 page) {
		Set<String> UsersIds = new Set<String>(); 
		if(currentFEP != null ) {
			for(FeedElement fe : currentFEP.elements) {
				if(fe.actor != null && String.isNotBlank(fe.actor.id)) {
					if(!UsersIds.contains(fe.actor.id)) {
						UsersIds.add(fe.actor.id);
					}
				}
				if(!Test.isRunningTest() && fe.capabilities != null && !fe.capabilities.comments.page.items.isEmpty()) {
					for(FeedElementComment com : fe.capabilities.comments.page.items) {
						if(com.user != null && String.isNotBlank(com.user.id)) {
							if(!UsersIds.contains(com.user.id)) {
								UsersIds.add(com.user.id);
							}
						}
					}
				}
			}
		}
		if(page != null) {
			for(FeedElementComment com : page.items) {
				if(com.user != null && String.isNotBlank(com.user.id)) {
					if(!UsersIds.contains(com.user.id)) {
						UsersIds.add(com.user.id);
					}
				}
			}
		}
		return new List<String>(UsersIds);
	}

	// initial parent data for feed
	public static FeedElementPage initialParentId(FeedElementPage currentFeedPage){
		List<String> feedsItemsIds = new List<String>();
		Map<String, String> feedIdParentId = new Map<String, String>();
		Map<String, List<String>> parentTypeParentId = new Map<String, List<String>>();

		for(FeedElement fe : currentFeedPage.elements){
			feedsItemsIds.add(fe.Id);
		}

		for(FeedItem fItem : [SELECT Id, ParentId FROM FeedItem WHERE Id IN :feedsItemsIds Limit 10000]){
			String sobjectName = fItem.ParentId.getSObjectType().getDescribe().getName();
			if(parentTypeParentId.get(sobjectName) != null){
				parentTypeParentId.get(sobjectName).add(fItem.ParentId);
			}else{
				parentTypeParentId.put(sobjectName, new List<String>{fItem.ParentId});
			}
			feedIdParentId.put(fItem.Id, fItem.ParentId);
		}
		Map<String, List<String>> mapParents = getParentsNames(parentTypeParentId);
		Map<String, List<String>> feedIdParentNameId = new Map<String, List<String>>();

		for(String fIdpId : feedIdParentId.keySet()){
			String pId = feedIdParentId.get(fIdpId);
			for(String mpId : mapParents.keySet()){
				if(pId.equals(mpId)){
					feedIdParentNameId.put(fIdpId, mapParents.get(mpId));
				}
			}
			
		}
		
		for(FeedElement fe : currentFeedPage.elements){
			if(feedIdParentId.containsKey(fe.Id)){
				fe.parentId = feedIdParentId.get(fe.Id);
			}
			if(feedIdParentNameId.get(fe.Id) != null ){
				fe.parentType = feedIdParentNameId.get(fe.Id)[0];
				fe.parentName = feedIdParentNameId.get(fe.Id)[1];
				fe.parentAcssesType = feedIdParentNameId.get(fe.Id)[2];
				fe.parentLink = feedIdParentNameId.get(fe.Id)[3];
				fe.parentIcon = feedIdParentNameId.get(fe.Id)[4];
			}
		}

		return currentFeedPage;
	}

	// get parent data
	public static Map<String, List<String>> getParentsNames(Map<String, List<String>> parentTypeParentId){
		Map<String, List<String>> parentIdNameGroupType = new Map<String, List<String>>();
		
		for(String typeParent : parentTypeParentId.keySet()){

			if(typeParent.containsIgnoreCase('CollaborationGroup')){
				List<String> groupsIds = parentTypeParentId.get(typeParent);
				if (!SObjectType.Community_Group_Control__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Group_Control__c);
				List<Community_Group_Control__c> cGroups = [SELECT Id, Name, Type__c, Chatter_Group_ID__c FROM Community_Group_Control__c WHERE Chatter_Group_ID__c IN :groupsIds];
				for(Community_Group_Control__c cGroup : cGroups){
					parentIdNameGroupType.put(cGroup.Chatter_Group_ID__c, new List<String>{Label.LBL_Digest_Group, cGroup.Name, cGroup.Type__c, prepareUrl(Page.CommunityGroupDetailPage.getUrl())+'?gr='+cGroup.Chatter_Group_ID__c, 'fa fa-users'});
				}
				
			}
			if(typeParent.containsIgnoreCase('Community_Group_Control')){
				List<String> groupsManagerIds = parentTypeParentId.get(typeParent);
				if (!SObjectType.Community_Group_Control__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Group_Control__c);
				List<Community_Group_Control__c> groupsM = [SELECT Id, Name, Type__c, Chatter_Group_ID__c FROM Community_Group_Control__c WHERE Id IN :groupsManagerIds];
				for(Community_Group_Control__c groupM : groupsM){
					parentIdNameGroupType.put(groupM.Id, new List<String>{label.LBL_Manager, groupM.Name, groupM.Type__c, prepareUrl(Page.CommunityGroupManager.getUrl())+'?gr='+groupM.Chatter_Group_ID__c, 'fa fa-comments'});
				}
				
			}
			if(typeParent.containsIgnoreCase('Community_News')){
				List<String> newsIds = parentTypeParentId.get(typeParent);
				if (!SObjectType.Community_News__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_News__c);
				List<Community_News__c> cNews = [SELECT Id, Title__c FROM Community_News__c WHERE Id IN :newsIds];
				for(Community_News__c cNew : cNews){
					parentIdNameGroupType.put(cNew.Id, new List<String>{label.LBL_News, cNew.Title__c, null, prepareUrl(Page.CommunityNewsDetail.getUrl())+'?id='+cNew.Id, 'fa fa-newspaper-o'});
				}
				
			}
			if(typeParent.containsIgnoreCase('Community_Events')){
				List<String> eventsIds = parentTypeParentId.get(typeParent);
				if (!SObjectType.Community_Events__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Events__c);
				List<Community_Events__c> cEvents = [SELECT Id, Name__c FROM Community_Events__c WHERE Id IN :eventsIds];
				for(Community_Events__c cEvent : cEvents){
					parentIdNameGroupType.put(cEvent.Id, new List<String>{Label.LBL_Events, cEvent.Name__c, null, prepareUrl(Page.CommunityEventDetail.getUrl())+'?id='+cEvent.Id, 'fa fa-calendar'});
				}
				
			}
			if(typeParent.containsIgnoreCase('Community_Resource')){
				List<String> resourceIds = parentTypeParentId.get(typeParent);
				if (!SObjectType.Community_Resource__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Resource__c);
				List<Community_Resource__c> cResources = [SELECT Id, Name FROM Community_Resource__c WHERE Id IN :resourceIds];
				for(Community_Resource__c cResource : cResources){
					parentIdNameGroupType.put(cResource.Id, new List<String>{Label.LBL_Resources, cResource.Name, null, prepareUrl(Page.communityresourcedetail.getUrl())+'?id='+cResource.Id, 'fa fa-book'});
				}
            
		}
		}
		return parentIdNameGroupType;
	}

	// initial topics data for feeds

	public static Map<String, String> topicNamesAndIds { get; set; }
	public static FeedElementPage initialTopics(FeedElementPage currentFeedPage) {

		List<String> feedsItemsIds = new List<String>();
		List<String> topicsNames = new List<String>();
		Map<String, Set<String>> topicsNamesInFeed = new Map<String, Set<String>>();
		List<TopicCL> topicCLList = new List<TopicCL>();
		for(FeedElement fe : currentFeedPage.elements){
			for(MessageSegments ms : fe.body.messageSegments){
				
				if(ms.type.equalsIgnoreCase('HashTag')){
					String hashText = ms.text.substring(1).unescapeHtml4();
					if(topicsNamesInFeed.get(fe.Id) != null){
						Set<String> namesFE = topicsNamesInFeed.get(fe.Id);
						namesFE.add(hashText);
						topicsNamesInFeed.put(fe.Id, namesFE);
						topicsNames.add(hashText);
					}else{
						topicsNamesInFeed.put(fe.Id, new Set<String>{hashText});
						topicsNames.add(hashText);
					}
				}
			}

			if(!Test.isRunningTest()){
				fe.capabilities.comments.page = initialTopicsForComment(fe.capabilities.comments.page);
			}
			feedsItemsIds.add(fe.Id);
		}
		
		topicCLList = queryTopicCLList(feedsItemsIds, NULL, topicsNames);
		topicCLList.sort();
		for(FeedElement fe : currentFeedPage.elements){
			fe.topicsUser = new List<TopicCL>();
			Set<String> existingTopicNames = new Set<String>();

			for(TopicCL tcl : topicCLList){
				if(tcl.entityId == fe.Id) {
					fe.topicsUser.add(tcl);
					existingTopicNames.add(tcl.name.toLowerCase());
					if(!Test.isRunningTest()){
					for(FeedElementComment fec : fe.capabilities.comments.page.items){
							fec.topicsUser = fec.topicsUser == null ? new List<TopicCL>() : fec.topicsUser;
							fec.topicsUser.add(tcl);
						}
					}
				}
			}
			if(topicsNamesInFeed.get(fe.id) != null){
				for(String topName : topicsNamesInFeed.get(fe.id)){
					if(!existingTopicNames.contains(topName.toLowerCase())){
						TopicCL tcl1 = new TopicCL(topicNamesAndIds.get(topName), null);
						tcl1.name = topName;
						fe.topicsUser.add(tcl1);
					}
				}
			}
			
		}
		return currentFeedPage;
	}

	// initial topics data for feed's comments
	public static Page2 initialTopicsForComment(Page2 currentPage2) {

		List<String> topicsNames = new List<String>();
		Map<String, Set<String>> topicsNamesInComments = new Map<String, Set<String>>();
		List<TopicCL> topicCLList = new List<TopicCL>();
		
		for(FeedElementComment fec : currentPage2.items){
			for(MessageSegments msc : fec.body.messageSegments){
				if(msc.type.equalsIgnoreCase('HashTag')){
					String hashText = msc.text.substring(1).unescapeHtml4();
					if(topicsNamesInComments.get(currentPage2.feedId) != null){
						Set<String> namesFE = topicsNamesInComments.get(currentPage2.feedId);
						namesFE.add(hashText);
						topicsNamesInComments.put(currentPage2.feedId, namesFE);
						topicsNames.add(hashText);
					}else{
						topicsNamesInComments.put(currentPage2.feedId, new Set<String>{hashText});
						topicsNames.add(hashText);
					}
				}
			}
		}
		
		topicCLList = queryTopicCLList(NULL, currentPage2.feedId, topicsNames);
		topicCLList.sort();
		for(FeedElementComment fec : currentPage2.items){
			fec.topicsUser = new List<TopicCL>();
			Set<String> existingTopicNames = new Set<String>();

			for(TopicCL tcl : topicCLList){
				if(tcl.entityId == currentPage2.feedId) {
					fec.topicsUser.add(tcl);
					existingTopicNames.add(tcl.name.toLowerCase());
				}
			}
		
			if(topicsNamesInComments.get(currentPage2.feedId) != null){
				for(String topName : topicsNamesInComments.get(currentPage2.feedId)){
					if(!existingTopicNames.contains(topName.toLowerCase())){
						TopicCL tcl1 = new TopicCL(topicNamesAndIds.get(topName), null);
						tcl1.name = topName;
						fec.topicsUser.add(tcl1);					
					}
				}
			}
		}
		return currentPage2;
	}

	// get topic's data for feed or for comments
	public static List<TopicCL> queryTopicCLList(List<String> feedsItemsIds, String feedId, List<String> topicsNames){
		
		List<TopicCL> topicCLList = new List<TopicCL>();
		List<String> topicsIds = new List<String>();
		topicNamesAndIds = new Map<String, String>();
		if(feedsItemsIds != NULL){
		for(TopicAssignment topicA : [SELECT Id, NetworkId, TopicId, EntityType, EntityId FROM TopicAssignment
										WHERE NetworkId =: Network.getNetworkId()
										AND EntityId IN :feedsItemsIds LIMIT 10000]){
		
			topicCLList.add(new TopicCL(topicA.TopicId, topicA.EntityId));
		}
		}else{
		for(TopicAssignment topicA : [SELECT Id, NetworkId, TopicId, EntityType, EntityId FROM TopicAssignment
										WHERE NetworkId =: Network.getNetworkId()
											AND EntityId =:feedId LIMIT 10000]){
		
			topicCLList.add(new TopicCL(topicA.TopicId, topicA.EntityId));
		}
		}
		
		for(TopicCL tcl : topicCLList){
			topicsIds.add(tcl.id);
		}
		for(Topic top : [SELECT Id, Name FROM Topic WHERE Id IN :topicsIds OR Name IN :topicsNames LIMIT 20000]){
			Boolean match = false;
			topicNamesAndIds.put(top.Name, top.id);
			for(TopicCL tcl : topicCLList){
				if(tcl.id == top.id){
					tcl.Name = top.Name;
					match = true;
				}
			}
			if(!match){
				TopicCL tcl1 = new TopicCL(top.Id, null);
				tcl1.Name = top.Name;
				topicCLList.add(tcl1);
			}
		}
		return topicCLList;
	}

	public static void postFeedIntoTopics(FeedElementPage currentFeedPage, String topId) {
		List<String> feedsItemsIds = new List<String>();
		List<TopicAssignment> topAssignments= new List<TopicAssignment>();
		for(FeedElement fe : currentFeedPage.elements){
			TopicAssignment ta = new TopicAssignment();
			ta.NetworkId = Network.getNetworkId();
			ta.TopicId = topId;
			ta.EntityId = fe.id;
			topAssignments.add(ta);
		}
		insert topAssignments;
	}
		

	public static FeedElementPage initialRoles(FeedElementPage currentFeedPage) {
		List<String> Ids = getUsersIdsForElement(currentFeedPage, null);
		Map<Id, String> UserIdAndRoleMap = getUserRoles(Ids);
		currentFeedPage = initialRolesForFeedElementPage(currentFeedPage, UserIdAndRoleMap);
		return currentFeedPage;
	}

	public static Page2 initialRoles(Page2 currentPage2) {
		List<String> Ids = getUsersIdsForElement(null, currentPage2);
		Map<Id, String> UserIdAndRoleMap = getUserRoles(Ids);
		currentPage2 = initialRolesForPage2(currentPage2, UserIdAndRoleMap);
		return currentPage2;
	}

	public static FeedElementPage initialRolesForFeedElementPage(FeedElementPage currentFEP, Map<Id, String> userRoleMap) {
		for(FeedElement fe : currentFEP.elements) {
			if(fe.actor != null && String.isNotBlank(fe.actor.id)) {
				if(userRoleMap.containsKey(fe.actor.id)) {
					fe.actor.role = userRoleMap.get(fe.actor.id);
				}
			}
			if(!Test.isRunningTest() && fe.capabilities != null && !fe.capabilities.comments.page.items.isEmpty()) {
				for(FeedElementComment com : fe.capabilities.comments.page.items) {
					if(com.user != null && String.isNotBlank(com.user.id)) {
						if(userRoleMap.containsKey(com.user.id)) {
							com.user.role = userRoleMap.get(com.user.id);
						}
					}
				}
			}
		}
		return currentFEP;
	}

	public static Page2 initialRolesForPage2(Page2 currentPage, Map<Id, String> userRoleMap) {
		if(!currentPage.items.isEmpty()) {
			for(FeedElementComment com : currentPage.items) {
				if(com.user != null && String.isNotBlank(com.user.id)) {
					if(userRoleMap.containsKey(com.user.id)) {
						com.user.role = userRoleMap.get(com.user.id);
					}
				}
			}
		}
		return currentPage;
	}

	public static Map<Id, String> getUserRoles(List<String> userIds) {
		Map<Id, String> userIdAndRoleMap = new Map<Id, String>();
		Map<Id, Id> userIdAndContactId = new Map<Id, Id>();
		if(!userIds.isEmpty()) {
			if (!SObjectType.User.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.User);
			for(User u : [SELECT Id, Contact.Primary_Role__c, Community_Contact_ID__c FROM User WHERE Id IN: userIds]) {
				if(u.Contact != null && u.Contact.Primary_Role__c != null){
					userIdAndRoleMap.put(u.Id, (String)u.Contact.Primary_Role__c);
				}
				else if(u.Community_Contact_ID__c != null) {
					userIdAndContactId.put(u.Id, u.Community_Contact_ID__c);
				}
			}
		}
		Map<Id, String> contactIdAndRoleMap = new Map<Id, String>();
		if(!userIdAndContactId.values().isEmpty()) {
			if (!SObjectType.Contact.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Contact);
			for(Contact c : [SELECT Id, Primary_Role__c, Name FROM Contact WHERE Id IN: userIdAndContactId.values() AND Primary_Role__c != null]) {
				contactIdAndRoleMap.put(c.Id, c.Primary_Role__c);
			}
			for(String uId : userIdAndContactId.keySet()) {
				if(contactIdAndRoleMap.containsKey(userIdAndContactId.get(uId))) {
					if(!userIdAndRoleMap.containsKey(uId)) {
						userIdAndRoleMap.put(uId, contactIdAndRoleMap.get(userIdAndContactId.get(uId)));
					}
				}
			}
		}
		return userIdAndRoleMap;
	}

	/*
		feed type map:
		1 - What I Follow
		2 - To Me
		3 - Bookmarks
		4 - UserProfile
		5 - Record
	*/
	private static Map<String, ConnectApi.FeedType> FT_MAP = new Map<String, ConnectApi.FeedType> {
        '1' => ConnectApi.FeedType.News, '2' => ConnectApi.FeedType.To, '3' => ConnectApi.FeedType.Bookmarks, '4' => ConnectApi.FeedType.Muted, '5' => ConnectApi.FeedType.UserProfile,
        '6' => ConnectApi.FeedType.Record
	};

	private static ConnectApi.FeedType determineFeedType(String inp, String inft) {
		if (String.isBlank(inft) || !FT_MAP.containsKey(inft)) {
            inft = inp.startsWith('005') ? (inp == UserInfo.getUserId() ? '1' : '5') : '6';
		}
		return FT_MAP.get(inft);
	}

	//deprecated
	@RemoteAction
	global static String postFeed(String inParentId3, String inText3) {
		return 'deprecated';
	}

	@RemoteAction
	global static String postFeeds(Map<String, String> params) {
		String inParentId3 = params.get('parentId');
		String inText3 = params.get('inText');
		String topId = params.get('topicId');
		ConnectApi.FeedItemInput fei = new ConnectApi.FeedItemInput();
		fei.subjectId = inParentId3;
		fei.body = werewolfText(inText3);
		fei.feedElementType = ConnectApi.FeedElementType.FeedItem;
		fei.visibility = ConnectApi.FeedItemVisibilityType.AllUsers;
		ConnectApi.FeedElement feedEl = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), fei, NULL);
		String newFeed = json.serialize(feedEl);
		//String newFeed = json.serialize(ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), fei, NULL));
		feedElIdForTest = feedEl.Id;
		FeedElementPage fepResult = new FeedElementPage();
		fepResult.elements = new List<FeedElement> { (FeedElement)JSON.deserialize(newFeed,FeedElement.class) };
		fepResult = initialRoles(fepResult);
		if(String.isNotEmpty(topId)) postFeedIntoTopics(fepResult, topId);
		fepResult = initialTopics(fepResult);
		return json.serialize(fepResult);
	}

	@RemoteAction
	global static String updateFeed(Map<String, String> params) {
		String inParentId3 = params.get('parentId');
		String inText3 = params.get('inText');
		String feedId = params.get('feedId');

		ChatterActionLayout layout = (ChatterActionLayout)JSON.deserialize(inText3,ChatterActionLayout.class);
		
		ConnectApi.FeedItemInput fei = new ConnectApi.FeedItemInput();
		fei.body = Test.isRunningTest() ? werewolfText('test') : werewolfText(layout.items[0].value);
		try{
			ConnectApi.FeedElement feedEl = ConnectApi.ChatterFeeds.updateFeedElement(Network.getNetworkId(), feedId, fei);
		}catch(Exception ex){
			throw new UnityFeedException(ex.getMessage());
		}	
		
		return json.serialize('Success');
	}

	@RemoteAction
	global static String updateComment(Map<String, String> params) {
		String inCommentText = params.get('inText');
		String inCommId = params.get('commId');

		ConnectApi.CommentInput ci = new ConnectApi.CommentInput();
		ci.body = werewolfText(inCommentText);
		
		try{
			ConnectApi.Comment editedComment = ConnectApi.ChatterFeeds.updateComment(Network.getNetworkId(), inCommId, ci);
		}catch(Exception ex){
			throw new UnityFeedException(ex.getMessage());
		}	
		
		return json.serialize('Success');
	}

	private static Map<String, Map<String, Schema.DescribeFieldResult>> getSobjectFieldsDescribe(List<String> sObjectsTypes) {
		Map<String, Map<String, Schema.DescribeFieldResult>> sObjectResult = new Map<String, Map<String, Schema.DescribeFieldResult>>();
		Schema.DescribeSobjectResult[] results = Schema.describeSObjects(sObjectsTypes);
		for(Schema.DescribeSobjectResult res : results) {
			String sObjectName = res.getName();
			Map<String, Schema.DescribeFieldResult> fields = new Map<String, Schema.DescribeFieldResult>();
			for (Schema.sObjectField field : res.fields.getMap().values()) {
				Schema.DescribeFieldResult describe = field.getDescribe();
				fields.put(describe.getName(), describe);
			}
			sObjectResult.put(sObjectName, fields);
		}

		return sObjectResult;
	}

	// deprecated
	@RemoteAction
	global static String postAction(String inParentId4, String inText4, String inFile, String inFileType, String inFileName) {
		return 'deprecated';
	}

	@RemoteAction
	global static String postActions(Map<String, String> params) {
		String inParentId4 = params.get('parentId');
		String inText4 = params.get('jsontext');
		String inFile = params.get('infilebstr');
		String inFileType = params.get('infiletype');
		String inFileName = params.get('infilename');
		String topId = params.get('topicId');


		ChatterActionLayout layout = (ChatterActionLayout)JSON.deserialize(inText4,ChatterActionLayout.class);
		String errField;
		for (ChatterActionLayoutItem layoutItem : layout.items) {
			if(!Test.isRunningTest()){
				if (layoutItem.required && String.isBlank(layoutItem.value)) {
					errField = layoutItem.label;
					break;
				}
			}
		}
		ConnectApi.FeedItemInput fei = new ConnectApi.FeedItemInput();
		fei.subjectId = inParentId4;
		fei.feedElementType = ConnectApi.FeedElementType.FeedItem;
		fei.visibility = ConnectApi.FeedItemVisibilityType.AllUsers;
		String resultPage;
		if (String.isNotBlank(errField)) {
			throw new UnityFeedException('"' + errField + '" is required');
		}
		else if (layout.name == 'FeedItem.TextPost') {
			if(Test.isRunningTest()) layout.items[0].value = 'test';
			Map<String, String> params1 = new Map<String, String>();
			params1.put('parentId', inParentId4);
			params1.put('inText', layout.items[0].value);
			params1.put('topicId', topId);
			try {
				resultPage = postFeeds(params1);
			}catch(ConnectApi.ConnectApiException ex){
				throw new UnityFeedException(Label.ERR_Post_Too_Large);
			}
		}
		else if (layout.name == 'FeedItem.ContentPost') {
			if(Test.isRunningTest()) layout.items[1].value = 'test';
			fei.capabilities = new ConnectApi.FeedElementCapabilitiesInput();
			fei.capabilities.content = new ConnectApi.ContentCapabilityInput();
			fei.capabilities.content.title = inFileName;
			fei.capabilities.content.description = layout.items[1].value;
			fei.body = werewolfText(layout.items[1].value);
		}
		else if (layout.name == 'FeedItem.LinkPost') {
			if(Test.isRunningTest()){
				layout.items[2].value = 'test';
				layout.items[0].value = 'http//test.com';
				layout.items[1].value = 'test';
			}
			fei.capabilities = new ConnectApi.FeedElementCapabilitiesInput();
			fei.capabilities.link = new ConnectApi.LinkCapabilityInput();
			fei.capabilities.link.url = layout.items[0].value;
			fei.capabilities.link.urlName = layout.items[1].value;
			fei.body = werewolfText(layout.items[2].value);
		}
		else if (layout.name == 'FeedItem.PollPost') {
			fei.capabilities = new ConnectApi.FeedElementCapabilitiesInput();
			fei.capabilities.poll = new ConnectApi.PollCapabilityInput();
			List<String> choices = new List<String>();
			for ( Integer i = 1; i < layout.items.size(); i++) {

				choices.add(layout.items[i].value);
			}
			Set<String> choisesInd = new Set<String>();
			for(String chois : choices){
				choisesInd.add(chois.toLowerCase());
				if (chois.length() > 99) {
					throw new UnityFeedException(Label.ERR_Choice_To_Long);
				}
			}
			if(choisesInd.size() != choices.size()){
				throw new UnityFeedException(Label.ERR_Pole_SameValueWarning);
			}
			else {
				fei.capabilities.poll.choices = choices;
				fei.body = werewolfText(layout.items[0].value);
			}
		}
		else {

			// Define a record for the quick action to create
			Schema.SObjectType targetType = Schema.getGlobalDescribe().get(layout.objectName);
			if (targetType == null) { 
				targetType = Schema.getGlobalDescribe().get(CommunityUtils.getPackagePrefix() + layout.objectName);
			}
			sObject sObj = targetType.newSObject();
			String namespacePrefix = layout.objectName.split('__').size() > 2 ? layout.objectName.split('__')[0]+'__' : '';

			Map<String, Schema.DescribeFieldResult> sObjectFields = getSobjectFieldsDescribe(new List<String> { layout.objectName }).get(layout.objectName);
			if (sObjectFields == null) {
				sObjectFields = getSobjectFieldsDescribe(new List<String> { layout.objectName }).get(CommunityUtils.getPackagePrefix() + layout.objectName);
			}
			for (ChatterActionLayoutItem item : layout.items) {
				if (sObjectFields.containsKey(item.fieldName)) {
					Schema.DisplayType tpOfItem = sObjectFields.get(item.fieldName).getType();
					if (tpOfItem == Schema.DisplayType.Datetime) {
						sObj.put(item.fieldName, String.isBlank(item.value) ? null : Datetime.parse(item.value));
					}
					else if (tpOfItem == Schema.DisplayType.Date){
						sObj.put(item.fieldName, String.isBlank(item.value) ? null : Date.parse(item.value));
					}
					else {
						sObj.put(item.fieldName, item.value);
					}
				}
			}
			if(layout.name == 'Create_Event'){
				if(((DateTime)sObj.get(namespacePrefix + 'Start__c')) >= ((DateTime)sObj.get(namespacePrefix + 'End__c'))){
					throw new UnityFeedException(Label.ERR_Create_Event_Dates);
			}
			}
			//req.record = sObj; 
			Database.SaveResult res = Database.insert(sObj);

			// Provide the context ID (or parent ID). In this case, it is an Account record.
			//req.contextid = UserInfo.getUserId(); 

			//QuickAction.QuickActionResult res = QuickAction.performQuickAction(req);
			//system.debug(res);
			if (res.isSuccess()) {
				//resultPage = postFeed(inParentId4, res.getIds()[0]);
				if (layout.name == 'Create_Event') {
					fei.capabilities = new ConnectApi.FeedElementCapabilitiesInput();
					fei.capabilities.link = new ConnectApi.LinkCapabilityInput();
					fei.capabilities.link.url = prepareUrl(Page.CommunityEventDetail.getUrl()) + '?id=' + res.getId();
					//fei.capabilities.link.url = prepareUrl(Page.CommunityEventDetail.getUrl()) + '?id=' + res.getIds()[0];
					for (ChatterActionLayoutItem item : layout.items) {
						if (item.fieldName == namespacePrefix + 'Name__c') {
							fei.capabilities.link.urlName = item.value;
						}
						else if (item.fieldName == namespacePrefix + 'Description__c') {
							fei.body = werewolfText(item.value);
						}
					}
					if (fei.body == NULL) fei.body = werewolfText('');
					// insert group link for event
					//Community_Group_Control__c groupControl = [SELECT ID FROM Community_Group_Control__c WHERE Chatter_Group_ID__c = :inParentId4 LIMIT 1];
					if (!SObjectType.Community_Group_Control__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Group_Control__c);
					String queryInParentId4 = CommunityUtils.validateId(inParentId4);
					if(![SELECT ID FROM Community_Group_Control__c WHERE Chatter_Group_ID__c = :queryInParentId4 LIMIT 1].isEmpty()){
					if (!SObjectType.Community_Group_Control__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Group_Control__c);
						Id grControllID = [SELECT ID FROM Community_Group_Control__c WHERE Chatter_Group_ID__c = :queryInParentId4 LIMIT 1].Id;
						Community_Event_Tag__c communityEventTag = new Community_Event_Tag__c();
						communityEventTag.Community_Event__c = res.getId();
						communityEventTag.Community_Group_Control__c = grControllID;
						//insert communityEventTag;
						CommunityAccess.InsertWithoutSharing(
							communityEventTag,
							'CommunityFeedController.cls [postActions]',
							new List<Schema.DescribeFieldResult> {
								Community_Event_Tag__c.Community_Event__c.getDescribe(),
								Community_Event_Tag__c.Community_Group_Control__c.getDescribe()
							}
						);
					}
					//fei.body = werewolfText('Description');
				}
			}
			else {
				throw new UnityFeedException(String.valueOf(res.getErrors()));
			}
		}
		if (String.isBlank(resultPage) && fei.body != NULL) {
			String newFeedInsert;
			try {
				newFeedInsert = json.serialize(ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(),fei,null));
				}catch(ConnectApi.ConnectApiException caException){
				if (caException.getErrorCode() == 'STRING_TOO_LONG') {
					throw new UnityFeedException(Label.ERR_Post_Too_Large);
				}
				throw new UnityFeedException(caException.getMessage());
			}
			FeedElementPage fepResult = new FeedElementPage();
			fepResult.elements = new List<FeedElement> {(FeedElement)JSON.deserialize(newFeedInsert, FeedElement.class)};
			fepResult = initialRoles(fepResult);
			if(String.isNotEmpty(topId)) postFeedIntoTopics(fepResult, topId);
			fepResult = initialTopics(fepResult);
			resultPage = json.serialize(fepResult);
		}
		return resultPage;
	}

    @RemoteAction
    global static String muteFeeds(Map<String, String> params){
        String feedElementId = params.get('feedId');
        Boolean changeMute = params.get('isMutedByMe') == 'true' ? false : true;
        InlineActionResult result;
        try{
            ConnectApi.MuteCapability mc = ConnectApi.ChatterFeeds.setIsMutedByMe(Network.getNetworkId(), feedElementId, changeMute);
        }catch(Exception ex){
            if(Test.isRunningTest()) return 'Error'; 
            throw new UnityFeedException(ex.getMessage());
        }   
        result = new InlineActionResult('Muted ', ' ', feedElementId);

        return json.serialize(result);
    }

	private static String prepareUrl(String inUncouthUrl) {
		return String.isNotBlank(Site.getPathPrefix()) ? inUncouthUrl.replace('/apex/', Site.getPathPrefix() + '/') : inUncouthUrl;
	}

	@RemoteAction
	global static String postComment(String inFeedId, String inCommentText) {
		ConnectApi.CommentInput ci = new ConnectApi.CommentInput();
		ci.body = werewolfText(inCommentText);
		String newComment;
		try{
			newComment = json.serialize(ConnectApi.ChatterFeeds.postCommentToFeedElement(Network.getNetworkId(), inFeedId, ci, NULL));
		}catch(ConnectApi.ConnectApiException ex){
			throw new UnityFeedException(Label.ERR_Comment_Too_Large);
		}	
		//String newComment = json.serialize(ConnectApi.ChatterFeeds.postCommentToFeedElement(Network.getNetworkId(), inFeedId, ci, NULL));
		Page2 commentPage = new Page2();
		commentPage.feedId = inFeedId;
		commentPage.items = new List<FeedElementComment> { (FeedElementComment)JSON.deserialize(newComment,FeedElementComment.class) };
		commentPage = initialRoles(commentPage);
		commentPage = initialTopicsForComment(commentPage);
		return json.serialize(commentPage);
	}

	@RemoteAction
	global static String getComments(String inFeedId, String inPageToken) {
		String commentsString = json.serialize(ConnectApi.ChatterFeeds.getCommentsForFeedElement(Network.getNetworkId(), inFeedId, inPageToken, RECENT_COMMENT_COUNT));
		Page2 commentPage2 = (Page2)JSON.deserialize(commentsString,Page2.class);
		commentPage2.feedId = inFeedId;
		commentPage2 = initialRoles(commentPage2);
		commentPage2 = initialTopicsForComment(commentPage2);
		return json.serialize(commentPage2);
	}

	@RemoteAction
	global static String getCommentForEdit(Map<String, String> params) {
		String commentId = params.get('commentId');
		
		String commentsString = json.serialize(ConnectApi.ChatterFeeds.getComment(Network.getNetworkId(), commentId));
		//FeedElementComment commentPage2 = (FeedElementComment)JSON.deserialize(commentsString,FeedElementComment.class);
		Page2 commentPage2 = new Page2();
		commentPage2.items = new list<FeedElementComment>{(FeedElementComment)JSON.deserialize(commentsString,FeedElementComment.class)};
		//commentPage2.feedId = inFeedId;
		commentPage2 = initialRoles(commentPage2);
		commentPage2 = initialTopicsForComment(commentPage2);
		return json.serialize(commentPage2);
	}

	@RemoteAction
	global static String getTopics(String query){
		List<HashTagTopic> result = new List<HashTagTopic>();
		query = query.replace('\\','\\\\');
		query = '%' + String.escapeSingleQuotes(query) + '%';
		List<Topic> listTopics = [SELECT Id, Name, NetworkId, TalkingAbout FROM Topic WHERE NetworkId =: Network.getNetworkId() AND Name LIKE :query LIMIT 1000];
		for(Topic t : listTopics){
			result.add(new HashTagTopic(t));
		}
		result.sort();
		return json.serialize(result);
		
	}

	@RemoteAction
	global static String getUsers(String query) {
		List<MentionUser> result = new List<MentionUser>();
		Map<String, Community_Group_Control__c> groupsMap = new Map<String, Community_Group_Control__c>();
		Map<String, String> groupsMapPhoto = new Map<String, String>();
		query = '%' + String.escapeSingleQuotes(query) + '%';
		for (User u : CommunityHelperWithoutSharing.getCommunityUsers(query,10,new List<String>{'FirstName', 'LastName', 'SmallPhotoUrl', 'Contact.Primary_Role__c'},'Name',true))
				
				 {
			result.add(new MentionUser(u));
		}
		
		if (!SObjectType.Community_Group_Control__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Group_Control__c);
		List<Community_Group_Control__c> cgcList = [
													SELECT Chatter_Group_ID__c, Name
													FROM Community_Group_Control__c
													WHERE Chatter_Group_ID__c != NULL AND Name LIKE :query
													];
		for (Community_Group_Control__c cgc : cgcList) {
			groupsMap.put(cgc.Chatter_Group_ID__c, cgc);

		}
		Set<String> groupsNames = new Set<String>();
		List<String> groupsIds = new List<String>();
		groupsIds.addAll(groupsMap.keySet());

		if (!SObjectType.CollaborationGroup.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.CollaborationGroup);
		for(CollaborationGroup cg : [SELECT Id, SmallPhotoUrl FROM CollaborationGroup WHERE Id IN :groupsIds]){
			groupsMapPhoto.put(cg.Id, cg.SmallPhotoUrl);
		}

		groupsNames.addAll(CommunityUtils.getNamesOfAvailableGroups(groupsIds));
		for(String ids : groupsMap.keySet()){
			if(groupsNames.contains(groupsMap.get(ids).Name)){
				result.add(new MentionUser(groupsMap.get(ids), groupsMapPhoto.get(ids)));
			}
		} 
		result.sort();
		return json.serialize(result);
	}

	@RemoteAction
	global static String inlineAction(String inPid, String inCname, String inOid) {
		InlineActionResult result;
		// liker
		if (inCname == 'fa-thumbs-up') {
			if (String.isNotBlank(inOid)) {
					ConnectApi.ChatterFeeds.deleteLike(Network.getNetworkId(), inOid);
					result = new InlineActionResult(inCname, '', inPid);
			}
			else {
				ConnectApi.ChatterLike cl = inPid.startsWith('0D5')
											? ConnectApi.ChatterFeeds.likeFeedElement(Network.getNetworkId(), inPid)
											: ConnectApi.ChatterFeeds.likeComment(Network.getNetworkId(), inPid);
				result = new InlineActionResult(inCname, cl.id, inPid);
			}
		}
		// bookmark handler
		else if (inCname == 'fa-bookmark') {
			ConnectApi.BookmarksCapability bc = ConnectApi.ChatterFeeds.updateFeedElementBookmarks(Network.getNetworkId(), inPid, inOid!='true');
			result = new InlineActionResult(inCname, bc.isBookmarkedByCurrentUser ? 'true' : '', inPid);
		}
		// inappropriate handler
		else if (inCname == 'fa-flag') {
			String resultOid = '';
			if (String.isNotBlank(inOid)) {
				if (inPid.startsWith('0D5')) {
					ConnectApi.CommunityModeration.removeFlagFromFeedElement(Network.getNetworkId(), inPid, UserInfo.getUserId());
				}
				else {
					ConnectApi.CommunityModeration.removeFlagFromComment(Network.getNetworkId(), inPid, UserInfo.getUserId());
				}
			}
			else {
				if (inPid.startsWith('0D5')) {
					ConnectApi.CommunityModeration.addFlagToFeedElement(Network.getNetworkId(), inPid);
				}
				else {
					ConnectApi.CommunityModeration.addFlagToComment(Network.getNetworkId(), inPid);
				}
				resultOid = 'true';
			}
			result = new InlineActionResult(inCname, resultOid, inPid);
		}
		// delete feed/comment
		else if (inCname == 'fa-times') {
			try {
				if (inPid.startsWith('0D5')) {
					ConnectApi.ChatterFeeds.deleteFeedElement(Network.getNetworkId(), inPid);
				}
				else {
					ConnectApi.ChatterFeeds.deleteComment(Network.getNetworkId(), inPid);
				}
			}
			catch (Exception e) {}
			result = new InlineActionResult(inCname, '', inPid);
		}
		return json.serialize(result);
	}

// deprecated
	@RemoteAction
	global static String voteOnPoll(Id pollId, Id choiceId, String inParentId, String inFeedType) {
        return 'deprecated';
    }

    @RemoteAction
    global static String votesOnPoll(Map<String, String> params) {
        String pollId = params.get('pollId');
        String choiceId = params.get('choiceId');
        String inParentId = params.get('inParentId');
        String inFeedType = params.get('inFeedType');
        String voteFromEmail = params.get('fromEmail');
		ConnectApi.PollCapability poll = ConnectApi.ChatterFeeds.voteOnFeedElementPoll(Network.getNetworkId(), pollId, choiceId);

        if(voteFromEmail.equalsIgnoreCase('true')){
            Map<String, String> paramsForFeeds = new Map<String, String>();
            paramsForFeeds.put('parentId', inParentId);
            paramsForFeeds.put('inFeedType', inFeedType);
            paramsForFeeds.put('feedId', pollId);
            paramsForFeeds.put('inpt', NULL);
            return feedFromEmail(paramsForFeeds);
        }
		return feeds(inParentId, inFeedType, NULL);
	}

	@RemoteAction
	global static String insertAttacmentIntoFeed(String parentId, String attId, String jsStr) {
		String layoutItemsValue = '';
		Attachment att = CommunityHelperWithoutSharing.getAttachment(attId);
		if(jsStr != null){
			ChatterActionLayout layout = (ChatterActionLayout)JSON.deserialize(jsStr,ChatterActionLayout.class);
			layoutItemsValue = Test.isRunningTest() ? 'test' : layout.items[1].value;
		}
		ConnectApi.FeedItemInput fei = new ConnectApi.FeedItemInput();
		fei.subjectId = parentId;
		fei.feedElementType = ConnectApi.FeedElementType.FeedItem;
		fei.visibility = ConnectApi.FeedItemVisibilityType.AllUsers;
		fei.capabilities = new ConnectApi.FeedElementCapabilitiesInput();
		fei.capabilities.content = new ConnectApi.ContentCapabilityInput();
		fei.capabilities.content.title = att.Name;
		fei.capabilities.content.description = layoutItemsValue.length() > 1000 ? werewolfDescription(layoutItemsValue.substring(0, 1000)) : werewolfDescription(layoutItemsValue);
		fei.body = werewolfText(layoutItemsValue);
		String newFeed;
		try{
			newFeed = json.serialize(ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), fei, new ConnectApi.BinaryInput(att.Body, att.ContentType, att.Name)));
		}catch(ConnectApi.ConnectApiException ex){
			throw new UnityFeedException(Label.ERR_Post_Too_Large);
		}	
		FeedElementPage fepResult = new FeedElementPage();
		fepResult.elements = new List<FeedElement> { (FeedElement)JSON.deserialize(newFeed,FeedElement.class) };
		fepResult = initialRoles(fepResult);
		List<Attachment> lAttachment = new List<Attachment>();
		lAttachment.add(att);
		CommunityAccess.DeleteWithoutSharing(
			lAttachment,
			'CommunityFeedController.cls [insertAttacmentIntoFeed]'
		);
		return json.serialize(fepResult);

	}
	

	private static ConnectApi.MessageBodyInput werewolfText(String intxt) {
		ConnectApi.MessageBodyInput result = new ConnectApi.MessageBodyInput();
		result.messageSegments = new List<ConnectApi.MessageSegmentInput>();
		while(intxt.length() > 0) {
			Integer index = intxt.indexOf('@[');
			index = index == -1 ? intxt.length() : index;
			if (index > 0) {
				ConnectApi.TextSegmentInput tsi = new ConnectApi.TextSegmentInput();
				tsi.text = intxt.substring(0, index);
				result.messageSegments.add(tsi);
				intxt = intxt.substring(index, intxt.length());
			}
			else {
				Integer endIndex = intxt.indexOf(']');
				if (endIndex != -1 ) {
					if(intxt.substring(index + 2, endIndex) instanceof Id){
						try {
							ConnectApi.MentionSegmentInput msi = new ConnectApi.MentionSegmentInput();
							msi.id = Id.valueOf(intxt.substring(index + 2, endIndex));
							result.messageSegments.add(msi);
						}
						catch (Exception e) {
							endIndex = index+1;
						}
					}else{
						ConnectApi.TextSegmentInput tsi = new ConnectApi.TextSegmentInput();
						tsi.text = intxt.substring(index, endIndex+1);
						result.messageSegments.add(tsi);
					}
				}
				else {
					endIndex = index+1;
				}
				intxt = intxt.substring(endIndex+1, intxt.length());
			}
		}
		return result;
	}

	private static String werewolfDescription(String intxt) {
		String result = intxt;
		String res = intxt;
		Map<String, String> idsAndNames = new Map<String, String>();
		Set<String> usersIds = new Set<String>();
		Set<String> groupsIds = new Set<String>();
		
		while(intxt.length() > 0) {
			Integer index = intxt.indexOf('@[');
			index = index == -1 ? intxt.length() : index;
			if(index > 0){
				intxt = intxt.substring(index, intxt.length());
			}else if (index != -1) {
				Integer endIndex = intxt.indexOf(']');
				if (endIndex != -1) {
					String subStr = intxt.substring(index + 2, endIndex);
					if(subStr instanceof Id){
						String prefixId = subStr.substring(0, 3);
						if(prefixId == '0F9'){
							groupsIds.add(subStr);
						}else if(prefixId == '005'){
							usersIds.add(subStr);
						}
					}
				}else {
					endIndex = index+1;
				}
				intxt = intxt.substring(endIndex+1, intxt.length());
			}

		}
		
		while(res.length() > 0) {
			Integer index = res.indexOf('#[');
			index = index == -1 ? res.length() : index;
			if(index > 0){
				res = res.substring(index, res.length());
			}else if (index != -1) {
				Integer endIndex = res.indexOf(']');
				if (endIndex != -1) {
					String subStr = res.substring(index + 2, endIndex);
					String replaceString = '['+subStr+']';
					result = result.replace(replaceString, subStr);	
				}
				res = res.substring(endIndex+1, res.length());	
			}
		}
		if(!usersIds.isEmpty()){
			for(User u : CommunityHelperWithoutSharing.getUsers(usersIds)){
				idsAndNames.put(u.Id, u.Name);
			}
		}
		if(!groupsIds.isEmpty()){
			for(Community_Group_Control__c gr : CommunityHelperWithoutSharing.getGroups(groupsIds)){
				idsAndNames.put(gr.Chatter_Group_ID__c, gr.Name);
			}
		}
		for(String key : idsAndNames.keySet()){
			String replaceString = '['+key+']';
			result = result.replace(replaceString, idsAndNames.get(key));
		}
		return result;
	}

	public class InlineActionResult {
		public String cname { get; set; }
		public String oid { get; set; }
		public String pid { get; set; }
		public String stl { get { return ' ' + cname + (String.isBlank(oid) ? '' : ' active'); } }

		public InlineActionResult(String inc, String ino, String inp) {
			cname = inc;
			oid = ino;
			pid = inp;
		}
	}

	private static Boolean bool ;
	public static Boolean checkBool(){
		if(bool == null){
			Profile prof = [SELECT PermissionsModerateChatter, PermissionsModerateNetworkFeeds FROM Profile WHERE Id = :UserInfo.getProfileId() Limit 1];
			Boolean moderateChatter = prof.PermissionsModerateChatter;
			Boolean moderateFeeds = prof.PermissionsModerateNetworkFeeds;
			bool =  moderateChatter || moderateFeeds;
		}
		return bool;
	}

	public class FeedElementPage {
		public String nextPageToken { get;set; }
		public List<FeedElement> elements { get;set; }
		public Boolean showMore { get { return nextPageToken != NULL; } }
	}

	public class FeedElement {
		public Actor actor { get; set; }
		public Body body { get; set;}
		public Capabilities capabilities { get; set; }
		public Datetime createdDate { get; set; }
		public String id { get; set; }
		public String dateStr { get { return convertTimeDiff(createdDate);} }
		public Integer total { get { return (capabilities.comments != NULL) ? capabilities.comments.page.total : 0; }}
		public Boolean showCommentsCount { get {return total > 0;}}
		public Boolean showComments { get { return (capabilities.comments != NULL) ? capabilities.comments.page.items.size() > 0 : false; } }
		public Boolean isDeleteRestricted { get { return (checkBool() != true) ? actor.id == UserInfo.getUserId() || parentId == UserInfo.getUserId() : true;} set;  }
		public String countLikes { get { return (capabilities.chatterLikes != NULL) ? String.valueOf(capabilities.chatterLikes.page.total) : '0'; } }
		public String likeStyle { get { return (capabilities.chatterLikes != NULL && capabilities.chatterLikes.isLikedByCurrentUser) ? ' active' : ''; } }
		public String bookmarkStyle { get { return (capabilities.bookmarks != NULL && capabilities.bookmarks.isBookmarkedByCurrentUser) ? ' active' : ''; } }
		public String likeId { get { return (capabilities.chatterLikes != NULL && capabilities.chatterLikes.isLikedByCurrentUser) ? capabilities.chatterLikes.myLike.id : ''; } }
		public String bookmarkStatus { get { return (capabilities.bookmarks != NULL && capabilities.bookmarks.isBookmarkedByCurrentUser) ? 'true' : ''; } }
		public Boolean showLink { get { return capabilities.link != NULL; } }
		public String linkHref { get { return capabilities.link != NULL ? CommunityUtils.checkURLforPref(capabilities.link.url) : ''; } }
		public String linkName { get { return capabilities.link != NULL ? capabilities.link.urlName : ''; } }

		public Boolean showContent { get { return capabilities.content != NULL; } }
		public Boolean showFlag { get { return capabilities.moderation != NULL; } }
		public Boolean flagged { get { return (showFlag && capabilities.moderation != NULL && capabilities.moderation.moderationFlags != NULL) ? capabilities.moderation.moderationFlags.flaggedByMe : false; } }
		public String flagStatus { get { return flagged ? 'true' : ''; } }
		public String flagStyle { get { return flagged ? ' active' : ''; } }

		public String parentType { get; set; }
		public String parentName { get; set; }
		public String parentLink { get; set; }
		public String parentAcssesType { get; set; }
		public String parentIcon { get; set; }
		public String parentId { get; set; }

		public List<TopicCL> topicsUser { get; set; }
				
	}

	public class Body {
		public String text { get; set; }
		public List<MessageSegments> messageSegments {get; set;}
	}

	public class MessageSegments {
		public Record record { get; set; }
		public String text { get; set; }
		public String type { get; set; }
		public String name { get; set; }
	}
	public class Record {
		public String id { get; set; }
		
	}
	
	public class Actor {
		public String displayName { get; set; }
		public String role { get; set; }
		public String id { get; set; }
		public Photo photo { get; set; }
	}

	public class Photo {
		public String smallPhotoUrl { get; set; }
	}
	public class Capabilities {
		public Bookmarks bookmarks { get; set; }
		public ChatterLikes chatterLikes { get; set; }
		public Comments comments { get; set; }
		public Link link { get; set; }
		public Moderation moderation { get; set; }
		public Poll poll { get; set; }
		public Content content { get; set; }
		public Edit edit { get; set; }
		public Mute mute { get; set; }
	}

	public class Mute {
        public Boolean isMutedByMe { get; set; }
	}

	public class Edit {
		public Datetime lastEditedDate { get; set; }
		public String editedDate { get { return convertTimeDiff(lastEditedDate); } }
		public Boolean isEditRestricted { get; set; }
	}

	public class Poll {
		public String myChoiceId { get; set; }
		public Integer totalVoteCount { get; set; }
		public List<PollChoice> choices { get; set; }
	}
	public class PollChoice {
		public String id { get; set; }
		public Integer position { get; set; }
		public String text { get; set; }
		public Integer voteCount { get; set; }
		public Decimal voteCountRatio { get; set; }
	}

	public class Comments {
		public Page2 page { get; set; }
	}

	public class Moderation {
		public ModerationFlags moderationFlags { get; set; }
	}

	public class ModerationFlags {
		public Boolean flaggedByMe { get; set; }
	}

	public class ChatterLikes {
		public Boolean isLikedByCurrentUser { get; set; }
		public Link myLike { get; set; }
		public Page3 page { get; set; }
	}

	public class Page3 {
		public Integer total { get; set; }
	}

	public class Link {
		public String id { get; set; }
		public String url { get; set; }
		public String urlName { get; set; }
	}

	public class Content {
		public String id { get; set; }
		public String contentUrl { get; set; }
		public String title { get; set; }
		public String fileSize { get; set; }
		public String downloadUrl { get; set; }
		public String description { get; set; } 
		public String renditionUrl { get; set; }
		public String fileExtension { get; set; }

	}

	public class TopicCL implements Comparable{
		public String entityId { get; set; }
		public String id { get; set; }
		public String name { get; set; }

		public TopicCL(String Id, String EntityId){
			this.entityId = EntityId;
			this.id = Id;
		}

		public Integer compareTo(Object compareTo) {
	    	TopicCL compareToEmp = (TopicCL)compareTo;
	        if (this.name == compareToEmp.name) return 0;
	        if (this.name > compareToEmp.name) return 1;
	        return -1;   
		}

	}

	public class Bookmarks {
		public Boolean isBookmarkedByCurrentUser { get; set; }
	}

	public class Parent {
		public Id id { get; set; }
	}

	public class Page2 {
		public List<FeedElementComment> items { get; set; }
		public String nextPageToken { get; set; }
		public Integer total { get; set; }
		public String feedId { get; set; }
		public Boolean showNextComments { get { return nextPageToken != NULL; } }
	}

	public class FeedElementComment {
		public String id { get; set; }
		public Body body { get; set; }
		public Capabilities capabilities { get; set; }
		public Actor user { get; set; }
		public Datetime createdDate { get; set; }
		public String dateStr { get { return convertTimeDiff(createdDate);} }
		public Boolean isDeleteRestricted { get { return (checkBool() != true) ? user.id == UserInfo.getUserId() || parent.id == UserInfo.getUserId() : true;} set;  }
		public Page3 likes { get; set; }
		public Link myLike { get; set; }
		public ModerationFlags moderationFlags { get; set; }
		public Boolean showFlag { get { return moderationFlags != NULL; } }
		public Boolean flagged { get { return showFlag ? moderationFlags.flaggedByMe : false; } }
		public String flagStatus { get { return flagged ? 'true' : ''; } }
		public String flagStyle { get { return flagged ? ' active' : ''; } }
		public String countLikes { get { return String.valueOf(likes.total); } }
		public String likeStyle { get { return myLike != NULL ? ' active' : ''; } }
		public String likeId { get { return myLike != NULL ? myLike.id : ''; } }
		public Parent parent { get; set; }
		public List<TopicCL> topicsUser { get; set; }
	}

	private static String[] dLbl = String.isNotBlank(Label.LBL_FeedsTime) ? Label.LBL_FeedsTime.split(';') : (new String[]{});
	public static String convertTimeDiff(Datetime inDT) {
		String outStr = '';
		if (inDT != NULL && dLbl.size() == 12) {
			Datetime dNow = Datetime.now();
			Long dateDiff = dNow.getTime() - inDT.getTime();
			//more than 1 year
			if (dateDiff > 63244800000L) {
				outStr = dLbl[0];
			}
			//a year ago
			else if (dateDiff > 31622400000L) {
				outStr = dLbl[1];
			}
			//few month ago
			else if (dateDiff > 4809600000L) {
				outStr = String.valueOf(Datetime.newInstance(dateDiff).month()) + dLbl[2];
			}
			//a month ago
			else if (dateDiff > 2404800000L) {
				outStr = dLbl[3];
			}
			//few weeks ago
			else if (dateDiff > 1202400000L) {
				outStr = String.valueOf(dateDiff / 601200000L) + dLbl[4];
			}
			//a week ago
			else if (dateDiff > 601200000L) {
				outStr = dLbl[5];
			}
			//few days ago
			else if (dateDiff > 172800000L) {
				outStr = String.valueOf(Datetime.newInstance(dateDiff).day()) + dLbl[6];
			}
			//yesterday
			else if (dateDiff > 86400000L || (inDT.day() != dNow.day())) {
				outStr = dLbl[7];
			}
			//few hours ago
			else if (dateDiff > 7200000L) {
				outStr = String.valueOf(dNow.hour() - inDT.hour()) + dLbl[8];
			}
			//a hour ago
			else if (dateDiff > 3600000L) {
				outStr = dLbl[9];
			}
			//few minutes ago
			else if (dateDiff > 120000L) {
				outStr = String.valueOf(Datetime.newInstance(dateDiff).minute()) + dLbl[10];
			}
			//a minute ago
			else {
				outStr = dLbl[11];
			}
		}
		return outStr;
	}

	global class HashTagTopic implements Comparable{
		public String id { get; set; }
		public String name { get; set; }
		public String text { get; set; }
		public Integer talkingAbout { get; set; }
		public String type { get; set; }

		public HashTagTopic(Topic top) {
			id = top.Id;
			name = top.Name;
			text = top.talkingAbout == 1 ? Label.LBL_Person_Talking : Label.LBL_People_Talking;
			talkingAbout = top.talkingAbout;
			type = 'topic';
		}

		global Integer compareTo(Object compareTo) {
	    	HashTagTopic compareToEmp = (HashTagTopic)compareTo;
	        if (this.name == compareToEmp.name) return 0;
	        if (this.name > compareToEmp.name) return 1;
	        return -1;   
		}
	}

	global class MentionUser implements Comparable{
		public String id { get; set; }
		public String name { get; set; }
		public String avatar { get; set; }
		public String role { get; set; }
		public String type { get; set; }

		public MentionUser(User inu) {
			id = inu.Id;
			name = inu.Name;
			avatar = inu.SmallPhotoUrl;
			role = inu.Contact.Primary_Role__c;
			type = 'user';
		}

		public MentionUser(Community_Group_Control__c incgc, String smallPhotoUrl) {
			id = incgc.Chatter_Group_ID__c;
			name = incgc.Name;
			avatar = smallPhotoUrl;//CommunityUtils.checkUrl('/profilephoto/0F9/F');
			type = 'group';
		}

		global Integer compareTo(Object compareTo) {
	    	MentionUser compareToEmp = (MentionUser)compareTo;
	        if (this.name == compareToEmp.name) return 0;
	        if (this.name > compareToEmp.name) return 1;
	        return -1;   
		}
	}
	
	private static List<List<String>> CHATTER_ACTIONS = new List<List<String>> {
		new List<String> { label.LBL_Post, 'FeedItem.TextPost', 'fa-comment', 'TextPost'},
		new List<String> { label.LBL_File, 'FeedItem.ContentPost', 'fa-file-o', 'ContentPost'},
		new List<String> { label.LBL_Link, 'FeedItem.LinkPost', 'fa-link', 'LinkPost'},
		new List<String> { Label.LBL_Poll, 'FeedItem.PollPost', 'fa-bar-chart', 'PollPost'},
		new List<String> { 'Create Event', 'Create_Event', 'fa-calendar', 'Create_Event'}
	};

	private static Map<String, ChatterActionLayout> ACTION_LAYOUT = new Map<String, ChatterActionLayout> {
		'FeedItem.TextPost' => new ChatterActionLayout(
			'FeedItem.TextPost', 
			NULL, //object name
			true, //before fields
			new List<ChatterActionLayoutItem>{  //items |LABEL|FIELD NAME|FIELD TYPE|VALUE|REQUIRED|
				new ChatterActionLayoutItem (
					null,
					'message',	//fieldName
					'post',	//ftype
					'text',	//inputtype
					null,	//value
					label.LBL_Post_InputBox,	//placeholder
					true,	//required
					'validate-textarea'	//validationClass
				)
			},
			NULL, // after fields
			NULL, //post
			NULL //button text
		),
		'FeedItem.LinkPost' => new ChatterActionLayout(
			'FeedItem.LinkPost', //name
			NULL, //object name
			true, //before fields
			new List<ChatterActionLayoutItem>{ //items |LABEL|FIELD NAME|FIELD TYPE|VALUE|REQUIRED|
				new ChatterActionLayoutItem (
					'Link URL',
					'message-link-url',	//fieldName
					'input',	//ftype
					'url',	//inputtype
					null,	//value
					'http://',	//placeholder
					true,	//required
					'validate-url'	//validationClass
				),
				//new ChatterActionLayoutItem('Link Name', 'message-link-name', 'input', NULL, NULL), 
				new ChatterActionLayoutItem (
					'Link Name',
					'message-link-name',	//fieldName
					'input',	//ftype
					'text',	//inputtype
					null,	//value
					null,	//placeholder
					true,	//required
					'validate-textarea'	//validationClass
				),
				//new ChatterActionLayoutItem(NULL, 'message', 'post', NULL, NULL)
				new ChatterActionLayoutItem (
					null,
					'message',	//fieldName
					'post',	//ftype
					'text',	//inputtype
					null,	//value
					label.LBL_Link_InputBox,	//placeholder
					false,	//required
					null	//validationClass
				)
				

			},
			NULL, // after fields
			NULL, //post
			NULL //button text
		),
		'FeedItem.ContentPost' => new ChatterActionLayout(
			'FeedItem.ContentPost', //name
			NULL, //object name
			true, //before fields
			new List<ChatterActionLayoutItem>{ //items |LABEL|FIELD NAME|FIELD TYPE|VALUE|REQUIRED|
				//new ChatterActionLayoutItem('Upload file from your computer', 'file-input-selector', 'inputfile', NULL, true),
				new ChatterActionLayoutItem (
					'Upload file from your computer <br>'+label.LBL_File_Upload_Size_Limit,	//label
					'file-input-selector',	//fieldName
					'inputfile',	//ftype
					'text',	//inputtype
					null,	//value
					null,	//placeholder
					true,	//required
					'validate-inputfile'	//validationClass
				), 
				//new ChatterActionLayoutItem(NULL, NULL, 'post', NULL, NULL)
				new ChatterActionLayoutItem (
					null,	//label
					'message',	//fieldName
					'post',	//ftype
					'text',	//inputtype
					null,	//value
					label.LBL_File_InputBox,	//placeholder
					false,	//required
					null	//validationClass
				)
			},
			NULL, // after fields
			NULL, //post
			NULL //button text
		),
		'FeedItem.PollPost' => new ChatterActionLayout(
			'FeedItem.PollPost', //name
			NULL, //object name
			false, //before fields
			new List<ChatterActionLayoutItem>{ //items |LABEL|FIELD NAME|FIELD TYPE|VALUE|REQUIRED|PLACEHOLDER|
				//new ChatterActionLayoutItem(NULL, NULL, 'post', NULL, NULL, 'What would you like to ask?', 'validate-textarea'),
				new ChatterActionLayoutItem (
					null,
					'message',	//fieldName
					'post',	//ftype
					'text',	//inputtype
					null,	//value
					'What would you like to ask?',	//placeholder
					true,	//required
					'validate-textarea'	//validationClass
				),
				//new ChatterActionLayoutItem('Choice 1', NULL, 'input', NULL, true), 
				new ChatterActionLayoutItem (
					'Choice 1',
					'choice1',	//fieldName
					'input',	//ftype
					'text',	//inputtype
					null,	//value
					null,	//placeholder
					true,	//required
					null	//validationClass
				),
				//new ChatterActionLayoutItem('Choice 2', NULL, 'input', NULL, true)
				new ChatterActionLayoutItem (
					'Choice 2',
					'choice2',	//fieldName
					'input',	//ftype
					'text',	//inputtype
					null,	//value
					null,	//placeholder
					true,	//required
					null	//validationClass
				)
			},
			true, // after fields
			NULL, //post
			NULL //button text
		)
	};
	private static Map<String, String> getAvailableQuickActions() {
		Map<String, String> result = new Map<String, String>();
		List<QuickAction.DescribeAvailableQuickActionResult> result2 = QuickAction.DescribeAvailableQuickActions('Global');
		for (QuickAction.DescribeAvailableQuickActionResult qa : result2) {
			result.put(qa.getLabel(), qa.getName());
		}
		return result;
	}

	public List<ChatterActionItem> getAvailableActions() {
		Map<String, String> actionAvailable = getAvailableQuickActions();
		List<ChatterActionItem> resultList = new List<ChatterActionItem>();
		showFileUpload = showFileUpload == true && Community_Settings__c.getInstance().Chatter_Action_Disable_Group_Files__c != true;
		
		for (List<String> caa : CHATTER_ACTIONS) {
			for(String key : actionAvailable.keySet()){
				if (actionAvailable.get(key).contains(caa[3])
					&& ( (caa[3] != 'ContentPost' && caa[3] != 'Create_Event')
					|| (caa[3] == 'ContentPost' && showFileUpload && CommunityUtils.checkAPIEnable())
					|| (caa[3] == 'Create_Event' && hideEventBtn != true && CommunityUtils.checkCRUDforObject(CommunityUtils.getPackagePrefix()+'Community_Events__c').get('isCreateable') && CommunityUtils.checkAPIEnable())
				)
			) {
				resultList.add(new ChatterActionItem(caa[0],caa[1],caa[2]));
			}
		}
		}
		return resultList;
	}

	public class ChatterActionItem {
		public String label { get; set; }
		public String name { get; set; }
		public String icon { get; set; }

		public ChatterActionItem(String l, String n, String i) {
			label = l;
			name = n;
			icon = i;
		}
	}

	public class ChatterActionLayout {
		public String name { get; set; }
		public String objectName { get { return objectName == NULL ? 'FeedItem' : objectName; } set; }
		public Boolean beforeFields { get { return beforeFields == NULL ? false : beforeFields; } set; }
		public List<ChatterActionLayoutItem> items { get; set; }
		public Boolean afterFields { get { return afterFields == NULL ? false : afterFields; } set; }
		public Boolean post { get { return post == NULL ? true : post; } set; }
		public String btntxt { get { return btntxt == NULL ? 'Share' : btntxt; } set; }

		public ChatterActionLayout(QuickAction.DescribeQuickActionResult inDqar) {
			name = inDqar.getName();
			objectName = inDqar.getTargetSobjectType();
			post = false;
			btntxt = 'Save';
			items = new List<ChatterActionLayoutItem>();
			for (QuickAction.DescribeLayoutRow dlr : inDqar.getLayout().getLayoutRows()) {
				ChatterActionLayoutItem cali = new ChatterActionLayoutItem();
				for (QuickAction.DescribeLayoutItem dli : dlr.getLayoutItems()) {
					List<QuickAction.DescribeLayoutComponent> dlc = dli.getLayoutComponents();
					if (dlc != NULL && dlc.size() > 0 && dlc[0].type == 'Field') {
						cali.label = dli.getLabel();
						cali.fieldName = dlc[0].getValue();
						cali.required = dli.isRequired();
						LayoutComponent lc = (LayoutComponent)JSON.deserialize(JSON.serialize(dlc[0]),LayoutComponent.class);
						cali.ftype = lc.getFieldType(); // text date 
						cali.inputtype = lc.getInputType(); // textarea input 
						cali.validationClass = lc.getValidationClass();
					}
				}
				items.add(cali);
			}
		}

		public ChatterActionLayout(String n,  String obn, Boolean bf, List<ChatterActionLayoutItem> i, Boolean af, Boolean p, String bt) {
			this.name = n;
			this.objectName = obn;
			this.beforeFields = bf;
			this.items = i;
			this.afterFields = af;
			this.post = p;
			this.btntxt = bt;
		}
	}

	public class ChatterActionLayoutItem {
		public String label { get { return label == NULL ? '' : label; } set; }
		public String fieldName { get { return fieldName == NULL ? '' : fieldName; } set; }
		public String ftype { get { return ftype == NULL ? 'input' : ftype; } set; }
		public String inputtype { get { return inputtype == NULL ? 'text' : inputtype; } set; }
		public String value { get { return value == NULL ? '' : value; } set; }
		public String placeholder { get { return placeholder == NULL ? '' : placeholder; } set; }
		public Boolean required { get { return required == NULL ? false : required; } set; }
		public String requiredAttr { get { return required ? ' required="required" ' : ''; } set; }
		public String validationClass { get; set; }

		public ChatterActionLayoutItem(String label, String fieldName, String ftype, String inputtype, String value, String placeholder, Boolean required, String validationClass) {
			this.label = label; 
			this.fieldName = fieldName; 
			this.ftype = ftype; 
			this.inputtype = inputtype; 
			this.value = value; 
			this.placeholder = placeholder; 
			this.required = required; 
			this.validationClass = validationClass; 
		}

		public ChatterActionLayoutItem() {

		}
	}

	public class LayoutComponent {
		public LayoutComponentDetail details { get; set; }
		public String getValidationClass() { return !TYPE_TO_CLASS.containsKey(details.type) ? details.type : TYPE_TO_CLASS.get(details.type); }
		public String getInputType() { return !TYPE_TO_INPUTTYPE.containsKey(details.type) ? details.type : TYPE_TO_INPUTTYPE.get(details.type); }
		public String getFieldType() { return !TYPE_TO_INPUT.containsKey(details.type) ? 'input' : TYPE_TO_INPUT.get(details.type); }
	}

	public class LayoutComponentDetail {
		public String type { get; set; }
	}
	private static Map<String, String> TYPE_TO_CLASS = new Map<String, String> {
		'textarea' => 'validate-textarea',
		'date' => 'validate-datepicker',
		'datetime' => 'validate-datetimepicker',
		'url' => 'validate-url'
	};
	private static Map<String, String> TYPE_TO_INPUT = new Map<String, String> {
		'string' => 'input',
		'textarea' => 'textarea'
	};
	private static Map<String, String> TYPE_TO_INPUTTYPE = new Map<String, String> {
		'string' => 'text',
		//'date' => 'text',
		'date' => 'date',
		//'datetime' => 'text',
		'datetime' => 'datetime',
		'url' => 'url'
	};

	@RemoteAction
	global static String actionLayout(String name) {
		ChatterActionLayout result; 
		if (ACTION_LAYOUT.containsKey(name)) {
			result = ACTION_LAYOUT.get(name);
		}
		return JSON.serialize(result);
	}

	@RemoteAction
	global static String actionLayoutSForce(String describeQA) {
		ChatterActionLayout result; 
		if(describeQA != null){
			String dqa = (String)JSON.deserialize(describeQA, String.class);
			Map<String, Boolean> nameReq = new Map<String, Boolean>();
			List<String> splitSTR = dqa.split(',');
			List<String> fieldNames = new List<String>();
			String fName = splitSTR[0];
			String objName = splitSTR[1];
			for(Integer i = 2; i < splitSTR.size(); i++){
				String fNameSplit = CommunityUtils.getPackagePrefix() + splitSTR[i].split(':')[0].replaceAll(' ','_')+'__c';
				Boolean fReqSplit =  Boolean.valueOf(splitSTR[i].split(':')[1]);
				fieldNames.add(fNameSplit);
				nameReq.put(fNameSplit, fReqSplit);
			}
			
			SObjectType objectType = Schema.getGlobalDescribe().get(objName);
			if(objectType == null){ 
				objectType = Schema.getGlobalDescribe().get(CommunityUtils.getPackagePrefix() + objName);
			}
			Map<String,Schema.SObjectField> mfields = objectType.getDescribe().fields.getMap();
			List<ChatterActionLayoutItem> chatActionLI = new List<ChatterActionLayoutItem>();

			for(String fieldName : fieldNames){
				Schema.DescribeFieldResult dfr = mfields.get(fieldName).getDescribe();
				if (dfr.isCreateable()) {
					LayoutComponent lc = new LayoutComponent();
					lc.details = new LayoutComponentDetail();
					lc.details.type = String.valueOf(dfr.getType()).toLowerCase();
					chatActionLI.add(new ChatterActionLayoutItem(
						dfr.getLabel(),
						dfr.getName(),
						lc.getFieldType(),
						lc.getInputType(),
						String.valueOf(dfr.getDefaultValue()),
						'false',
						nameReq.get(fieldName),
						lc.getValidationClass()));
				}
			}
			result = new ChatterActionLayout(fName, objName, null, chatActionLI, null, false, 'Save'); 
		}

		return JSON.serialize(result);
	}

	
}
global with sharing class CommunityShareController {

	public String shareLinkUrl { get;set; }
	public String shareLinkName { get;set; }
	public String shareComment { get;set; }
	public String shareGroup { get;set; }
	public Boolean hasMessage { get { return hasMessage == NULL ? false : hasMessage; } set; }
	public String message { get; set; }
	public List<TagsForGroup> AvailableGroups { get; set; }
	public List<GroupFinderWrapper> listGroupFindWrapper { get; set; }
	public Boolean availGroups {
		get {
			return AvailableGroups != NULL;
		}
		set;
	}
/*
	public Boolean showShareButton { 
		get{
			Community_Settings__c cs = Community_Settings__c.getOrgDefaults();
			return cs.Disable_Share__c != true;
		}
	}
*/
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
	}

	//remote actions
	@RemoteAction
	global static String shareForGroups(String idsGroups, String shareComment, String shareLinkName, String sobjId, Boolean shareLinkProfile) {
		
		List<String> groupsIds = idsGroups.split(',');
		String shareLinkUrl;
		String message;
		String obj = String.valueOf(((Id)sobjId).getSObjectType());
		obj = obj.split('__').size() > 2 ? obj.split('__')[1] : obj.split('__')[0];
		if(obj.equalsIgnoreCase('Community_Events')){
			shareLinkUrl = Page.CommunityEventDetail.getUrl().replace('/apex/','') + '?id=' + sobjId;
			shareLinkName = shareLinkName;
		}else {
			shareLinkUrl = Page.CommunityNewsDetail.getUrl().replace('/apex/','') + '?id=' +  sobjId;
			shareLinkName = shareLinkName;
		}

		try {
			Set<String> gcSet2 = new Set<String>();
			for (Community_Group_Control__c cgc2 : [SELECT Chatter_Group_ID__c
													FROM Community_Group_Control__c
													WHERE Chatter_Group_ID__c IN :groupsIds
													AND Status__c = 'Approved']) {
				gcSet2.add(cgc2.Chatter_Group_ID__c);
			}
			String networkId = Network.getNetworkId();
			Network nRec = [SELECT UrlPathPrefix FROM Network WHERE Id = :networkId];
			String cprefix = nRec.UrlPathPrefix != null ? '/' + nRec.UrlPathPrefix + '/' : '/';
	
			List<CollaborationGroup> cgrec = new List<CollaborationGroup>();

			if(gcSet2.isEmpty() && !shareLinkProfile){
				message = 'ERR '+Label.LBL_No_share_destination;
				return message;
			
			}
			else if(!gcSet2.isEmpty()){
				cgrec = [ SELECT Id, NetworkId
						FROM CollaborationGroup
						WHERE NetworkId = :Network.getNetworkId() AND Id IN :gcSet2
						];
			}
			if(shareLinkProfile){
				insert new FeedItem (
									LinkUrl = cprefix + shareLinkUrl,
									Title = shareLinkName,
									ParentId = UserInfo.getUserId(),
									NetworkScope = Network.getNetworkId(),
									Body = shareComment	);
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
				insert shareFeeds;
				message	= 'SUCCESS';
			}
			else if(!shareLinkProfile){
				message = 'ERR Something wrong with group name';
			}
		}
		catch(Exception e) {
			message = '!ERR '+e.getMessage();
			return message;
		}
		return message;
	}

	public void availableGroupsProcess(){
		
		Map<Id, String> cGroups = new Map<Id, String>();

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
		AvailableGroups = tagsForGroups;
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
		try{
			List<ConnectApi.BatchResult> batchResults = ConnectApi.ChatterGroups.getGroupBatch(Network.getNetworkId(), groupIds);
			for(ConnectApi.BatchResult batchResult : batchResults){
				if (batchResult.isSuccess()) {
					ConnectApi.ChatterGroup aGroup = (ConnectApi.ChatterGroup) batchResult.getResult();
					if(String.valueOf(aGroup.myRole) != 'NotAMember' && String.valueOf(aGroup.myRole) != 'NotAMemberPrivateRequested'){
						groupsNames.add(aGroup.name);
					}
					// will need in a future
					/*if((String.valueOf(aGroup.myRole) != 'NotAMember' 
						&& String.valueOf(aGroup.myRole) != 'NotAMemberPrivateRequested' 
						&& String.valueOf(aGroup.visibility) == 'PrivateAccess') || String.valueOf(aGroup.visibility) == 'PublicAccess'){
						groupsNames.add(aGroup.name);
					}*/
				}
				else {
					// Operation failed. Print errors.
					System.debug('FAILURE');
					System.debug(batchResult.getErrorMessage());
				}
			}
		}catch(Exception e){
			System.debug('FAILURE: '+e.getMessage());
		}
		return groupsNames;
	}

	//remote actions
	@RemoteAction
	global static String getGroups(String query) {
		String result = '';
		Set<String> gcSet = new Set<String>();
		for (Community_Group_Control__c cgc : [SELECT Chatter_Group_ID__c FROM Community_Group_Control__c WHERE Chatter_Group_ID__c != NULL AND Status__c = 'Approved']) {
			gcSet.add(cgc.Chatter_Group_ID__c);
		}
		for (CollaborationGroup cg : [SELECT Name FROM CollaborationGroup WHERE Id IN :gcSet AND NetworkId = :Network.getNetworkId()]) {
			result += '<option value="' + cg.Name + '"></option>';
		}
		return result;
	}

	@RemoteAction
	global static String getGroupsSelector(String query){
		List<GroupFinderWrapper> result = new List<GroupFinderWrapper>();
		Set<String> gcSet = new Set<String>();
		List<String> gcList = new List<String>();
		for (Community_Group_Control__c cgc : [SELECT Chatter_Group_ID__c FROM Community_Group_Control__c 
												WHERE Chatter_Group_ID__c != NULL AND Status__c = 'Approved']) {
			gcSet.add(cgc.Chatter_Group_ID__c);
		}
		Set<String> groupsNamesSet = new Set<String>();
		
		if(gcSet.isEmpty()) return null;
		
		gcList.addAll(gcSet);
		groupsNamesSet.addAll(getNamesOfAvailableGroups(gcList));
		
		if(groupsNamesSet.isEmpty()) return null;
		
		for (CollaborationGroup cg : [SELECT Id, Name FROM CollaborationGroup WHERE Id IN :gcSet AND NetworkId = :Network.getNetworkId() ORDER BY Name]) {
			if(groupsNamesSet.contains(cg.Name)){
				result.add(new GroupFinderWrapper(cg.Name, cg.Id));
			}
		}
		return JSON.serialize(result);
	}

	global class TagsForGroup implements Comparable{
		public List<GroupFinderWrapper> wrapperGroup {get; set;}
		public String TagName {get; set;}

		TagsForGroup(String tagN, List<GroupFinderWrapper> gfw){
			this.TagName = tagN;
			this.wrapperGroup = gfw;
		}

		global Integer compareTo(Object compareTo) {
			TagsForGroup compareToEmp = (TagsForGroup)compareTo;
			if (this.TagName == compareToEmp.TagName) return 0;
			if (this.TagName > compareToEmp.TagName) return 1;
			return -1;   
		}
		
	}

	global class GroupFinderWrapper implements Comparable{
		public String name { get; set; }
		public Id id { get; set;}

		GroupFinderWrapper(String name, Id id){
			this.name = name;
			this.id = id;
		}

		global Integer compareTo(Object compareTo) {
			GroupFinderWrapper compareToEmp = (GroupFinderWrapper)compareTo;
			if (this.name == compareToEmp.name) return 0;
			if (this.name > compareToEmp.name) return 1;
			return -1;
		}

	}
	
	public List<Community_Group_Control__c> AvailableGroupsControls { 
		get {
			Set<String> filtredChatterGroups = new Set<String>();
			Set<String> filtredTotalChatterGroups = new Set<String>();
			for (CollaborationGroupMember cgmItem : [
					SELECT CollaborationGroupId FROM CollaborationGroupMember
					WHERE CollaborationGroup.NetworkId = :Network.getNetworkId() AND MemberId = :UserInfo.getUserId()
						]) {
				filtredChatterGroups.add(cgmItem.CollaborationGroupId);
			}
			//gQuery += ' WHERE Chatter_Group_ID__c IN :filtredChatterGroups';
			for (CollaborationGroup cgItem: [SELECT Id, Name, IsArchived FROM CollaborationGroup WHERE ID IN :filtredChatterGroups and IsArchived = false LIMIT 100]) {
				filtredTotalChatterGroups.add(cgItem.Id);
			}			
			return filtredTotalChatterGroups.size() > 0?[SELECT Id, Name, Chatter_Group_ID__c, Status__c FROM  Community_Group_Control__c WHERE Chatter_Group_ID__c IN :filtredTotalChatterGroups AND Status__c = 'Approved' ORDER BY Name ASC  LIMIT 100]:null;			
		}
		set;
	}
}
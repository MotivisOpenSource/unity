public without sharing class CommunityGroupFilesController {

	public transient Community_Group_Control__c control { get; set; }
	public transient CollaborationGroup chatterGroup { get; set; }
	public transient List<FileWrapper> FileList { get; set; }
	public Id chatterGroupId { get { return chatterGroupId == NULL ? chatterGroup.Id : chatterGroupId; } set; }
	public Id contentDetailId { get; set; }

	public String mode { get { return mode == NULL ? 'initial' : mode; } set; }
	public String modal { get { return modal == NULL ? 'none' : modal; } set; }
	public String stack { get; set; }

	public Integer filesPageNumber { get { return filesPageNumber == NULL ? 1 : filesPageNumber; } set; }
	public Integer filesPagesTotal { get { return (filesPagesTotal == NULL || filesPagesTotal == 0) ? 1 : filesPagesTotal; } set; }
	public Integer filesTotal { get { return filesTotal == NULL ? 0 : filesTotal; } set; }
	public Boolean filesHasNext { get { return filesPageNumber < filesPagesTotal; } }
	public Boolean filesHasPrevious { get { return filesPageNumber > 1; } }
	public String fileQuery { get; set; }
	private Integer FILES_PAGE_SIZE { get { return mode == 'initial' ? 5 : 10; } }
	public Boolean allOk { get; set; }
	public Boolean enableShare { get; set; }

	public ContentVersion cvRecord { get; set; }

	public CommunityGroupFilesController() {}

	public void initFromPage() {
		String detailParam = ApexPages.currentPage().getParameters().get('f');
		if (String.isBlank(detailParam)) {
			mode = 'list';
		}
		else {
			mode = 'detail';
			contentDetailId = Id.valueOf(detailParam);
		}
		control = CommunityGroupManageController.pullGroupControlRecord(false);
		if (control != NULL && control.Chatter_Group_ID__c != NULL) {
			chatterGroup = [SELECT Id, FullPhotoUrl, CollaborationType FROM CollaborationGroup WHERE Id = :control.Chatter_Group_ID__c];
			chatterGroupId = chatterGroup.Id;
		}
		allOk = chatterGroupId != NULL && Community_Settings__c.getInstance().Chatter_Action_Disable_Group_Files__c != true;
		if (allOk) {
			ConnectApi.GroupMembershipType groupRole = ConnectApi.ChatterGroups.getGroup(Network.getNetworkId(), chatterGroup.Id).MyRole;
			allOk = control.Type__c == 'Public' || (groupRole != ConnectApi.GroupMembershipType.NotAMember && groupRole != ConnectApi.GroupMembershipType.NotAMemberPrivateRequested);
		}
		if (allOk) {
			init();
			enableShare = Community_Settings__c.getInstance().Disable_Share__c != true && chatterGroup != NULL && chatterGroup.CollaborationType == 'Public';
		}
	}

	public void init() {
		FileList = new List<FileWrapper>();
		String fQuery = 'SELECT Id, CreatedById, CreatedBy.Name, ContentFileName, LastModifiedDate FROM FeedItem';
		fQuery += ' WHERE Type = \'ContentPost\' AND ParentId = :chatterGroupId';
		fQuery += ' LIMIT 500';
		List<String> feedElementsIds = new List<String>();
		for (FeedItem fi : Database.query(fQuery)) {
			feedElementsIds.add(fi.Id);
		}
		List<ConnectApi.FeedElement> elements = new List<ConnectApi.FeedElement>();
		Set<String> collectedVersionIds = new Set<String>();
		for (ConnectApi.BatchResult batchResult : ConnectApi.ChatterFeeds.getFeedElementBatch(Network.getNetworkId(), feedElementsIds)) {
			if (batchResult.isSuccess() && batchResult.getResult() instanceof ConnectApi.FeedElement) {
				ConnectApi.FeedElement fe = (ConnectApi.FeedElement)batchResult.getResult();
				if (fe.capabilities != NULL && fe.capabilities.content != NULL && fe.capabilities.content.versionId != NULL) {
					collectedVersionIds.add(fe.capabilities.content.versionId);
					elements.add(fe);
				}
			}
		}
		if (collectedVersionIds.size() > 0) {
			Set<String> subscribedToContent = new Set<String>();
			Map<String, String> contentDocumentToVersionMap = new Map<String, String>();
			Map<String, ContentDocument> cdMap = new Map<String, ContentDocument>();
			List<String> cvAsList = new List<String>();
			cvAsList.addAll(collectedVersionIds);
			String cvQuery = 'SELECT Id, ContentDocumentId, ContentDocument.Id, ContentDocument.OwnerId, ContentDocument.Owner.Name, ContentDocument.LastModifiedDate, ContentDocument.Description FROM ContentVersion';
			cvQuery += ' WHERE Id IN (\'' + String.join(cvAsList, '\',\'') + '\')';
			if (mode == 'detail') {
				cvQuery += ' AND ContentDocumentId = \'' + contentDetailId + '\'';
			}
			if (mode == 'list' && String.isNotBlank(fileQuery)) {
				cvQuery += ' AND ContentDocument.Title LIKE \'%' + String.escapeSingleQuotes(fileQuery) + '%\'';
			}
			
			for (ContentVersion cvItem : Database.query(cvQuery)) {
				contentDocumentToVersionMap.put(cvItem.ContentDocumentId, cvItem.Id);
				cdMap.put(cvItem.Id, cvItem.ContentDocument);
			}
			for (EntitySubscription esItem : [SELECT ParentId FROM EntitySubscription WHERE SubscriberId =:Userinfo.getUserId() AND ParentId IN :contentDocumentToVersionMap.keySet() LIMIT 1000]) {
				subscribedToContent.add(contentDocumentToVersionMap.get(esItem.ParentId));
			}
			Set<String> filtredContentVersionsId = new Set<String>();
			filtredContentVersionsId.addAll(contentDocumentToVersionMap.values());
			Set<String> checkForDuplicatingSet = new Set<String>();
			List<ConnectApi.FeedElement> filteredElements = new List<ConnectApi.FeedElement>();
			for (ConnectApi.FeedElement fe3 : elements) {
				if (filtredContentVersionsId.contains(fe3.capabilities.content.versionId) && !checkForDuplicatingSet.contains(fe3.capabilities.content.versionId)) {
					filteredElements.add(fe3);
					checkForDuplicatingSet.add(fe3.capabilities.content.versionId);
				}
			}
			Integer fqlSize = filteredElements.size();
			filesTotal = fqlSize;
			filesPagesTotal = fqlSize / FILES_PAGE_SIZE + ((Math.mod(fqlSize, FILES_PAGE_SIZE) == 0) ? 0 : 1);
			Integer startCopyInterval = filesPageNumber > 1 ? ((filesPageNumber - 1) * FILES_PAGE_SIZE) : 0;
			Integer endCopyInterval = (fqlSize <= (startCopyInterval + FILES_PAGE_SIZE)) ? fqlSize : (startCopyInterval + FILES_PAGE_SIZE);
			Boolean modifyAllDataAccess = CommunityUtils.isModifyAllData();
			for (Integer ii = startCopyInterval; ii < endCopyInterval; ii++) {
				String vId = filteredElements[ii].capabilities.content.versionId;
				Boolean subscribed = subscribedToContent.contains(vId);
				ContentDocument cdItem = cdMap.get(vId);
				Boolean modifiable = modifyAllDataAccess || cdItem.OwnerId == UserInfo.getUserId();
				FileList.add(new FileWrapper(filteredElements[ii], subscribed, modifiable, cdItem));
			}
		}
	}

	public FileWrapper getFileDetail() {
		return (mode == 'detail' && FileList != NULL && FileList.size() > 0) ? FileList[0] : NULL;
	}

	public void searchAction() {
		//System.debug('\n**\n' + json.serialize(this));
		filesPageNumber = 1;
		init();
	}

	public void modeAction() {
		shareChoice = NULL;
		shareComment = NULL;
		cvRecord = NULL;
		if (modal == 'update') {
			cvRecord = [SELECT Id, Title, Description FROM ContentVersion WHERE Id = :stack];
		}
	}

	public String getCommunityId() {
		return Network.getNetworkId();
	}

	public String getParentDocumentId() {
		String result;
		if (modal == 'newversion') {
			result = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :stack].ContentDocumentId;
		}
		return result;
	}

	public void filesNextPage() {
		filesPageNumber++;
		init();
	}

	public void filesLastPage() {
		filesPageNumber = filesPagesTotal;
		init();
	}

	public void filesPreviousPage() {
		filesPageNumber--;
		init();
	}

	public void filesFirstPage() {
		filesPageNumber = 1;
		init();
	}

	public String shareChoice { get; set; }
	public String shareComment { get; set; }

	public void shareAction() {
		List<ConnectApi.BatchInput> feedElements = new List<ConnectApi.BatchInput>();
		String documentIdToShare = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :stack].ContentDocumentId;
		for (String sId : shareChoice.split(',')) {
			if (String.isNotBlank(sId)) {
				ConnectApi.FeedElementCapabilitiesInput feci = new ConnectApi.FeedElementCapabilitiesInput();
				feci.content = new ConnectApi.ContentCapabilityInput();
				feci.content.contentDocumentId = documentIdToShare;
				ConnectApi.FeedItemInput fei = new ConnectApi.FeedItemInput();
				fei.capabilities = feci;
				fei.feedElementType = ConnectApi.FeedElementType.FeedItem;
				fei.subjectId = sId;
				if (String.isNotBlank(shareComment)) {
					fei.body = new ConnectApi.MessageBodyInput();
					fei.body.messageSegments = new List<ConnectApi.MessageSegmentInput>();
					ConnectApi.TextSegmentInput tsi = new ConnectApi.TextSegmentInput();
					tsi.text = shareComment;
					fei.body.messageSegments.add(tsi);
				}
				feedElements.add(new ConnectApi.BatchInput(fei));
			}
		}
		if (feedElements.size() > 0) {
			ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), feedElements);
		}
		modal = 'none';
		modeAction();
	}

	public void updateAction() {
		update cvRecord;
		modal = 'none';
		modeAction();
		init();
	}

	public PageReference deleteAction() {
		ContentDocument cdDelete = [SELECT Id FROM ContentDocument WHERE Id IN (SELECT ContentDocumentId FROM ContentVersion WHERE Id = :stack)];
		delete cdDelete;
		PageReference pr;
		if (mode == 'detail') {
			pr = Page.CommunityGroupFiles;
			String groupControlIdParam = ApexPages.currentPage().getParameters().get('gc');
			String chatterGroupIdParam = ApexPages.currentPage().getParameters().get('gr');
			String groupParam = String.escapeSingleQuotes(String.isBlank(chatterGroupIdParam) ? groupControlIdParam : chatterGroupIdParam);
			pr.getParameters().put('gr', groupParam);
			pr.setRedirect(true);
		}
		else {
			init();
		}
		return pr;
	}

	@RemoteAction
	public static String getGroupsSelector(String query) {
		List<BlockWrapper> result = pullGroups(query);
		return result.size() == 0 ? NULL : JSON.serialize(result);
	}

	@RemoteAction
	public static String getPeoplesSelector(String query) {
		List<BlockWrapper> result = new List<BlockWrapper>();
		String escapedQuery = String.escapeSingleQuotes(query) + '%';
		List<User> uList = [
			SELECT Id, Name FROM User 
			WHERE (ContactId != NULL OR Community_Contact_ID__c != NULL) AND isActive = true AND Id != :UserInfo.getUserId()
			AND (FirstName LIKE :escapedQuery OR LastName LIKE :escapedQuery OR Name LIKE :escapedQuery)
			ORDER BY Name ASC
				];
		for (User uItem : uList) {
			result.add(new BlockWrapper(uItem.Id, uItem.Name));
		}
		return result.size() == 0 ? NULL : JSON.serialize(result);
	}

	@RemoteAction
	public static String subscriberAction(String versionId, Boolean inf) {
		String cdId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :versionId].ContentDocumentId;
		CommunityUtils.subscriberUser(cdId, !inf);
		return '';
	}

	private static List<BlockWrapper> pullGroups(String inQuery) {
		List<BlockWrapper> resultList = new List<BlockWrapper>();
		Set<String> filtredChatterGroups = new Set<String>();
		for (CollaborationGroupMember cgmItem : [SELECT CollaborationGroupId FROM CollaborationGroupMember WHERE CollaborationGroup.NetworkId = :Network.getNetworkId() AND MemberId = :UserInfo.getUserId()]) {
			filtredChatterGroups.add(cgmItem.CollaborationGroupId);
		}
		if (filtredChatterGroups.size() > 0) {
			String queryString = 'SELECT Id, Name FROM Community_Group_Control__c WHERE Chatter_Group_ID__c IN :filtredChatterGroups';
			if (String.isNotBlank(inQuery)) {
				queryString += ' AND Name LIKE \'' + String.escapeSingleQuotes(inQuery) + '%\'';
			}
			queryString += ' ORDER BY Name';
			for (Community_Group_Control__c cgcItem : Database.query(queryString)) {
				resultList.add(new BlockWrapper(cgcItem.Id, cgcItem.Name));
			}
		}
		return resultList;
	}

	public List<BlockWrapper> getGroups() {
		return (modal == 'sharegroup') ? pullGroups(NULL) : NULL;
	}

	public class FileWrapper {
		public String name { get { return name == NULL ? 'undefined' : name; } set; }
		public String lastModified { get { return lastModified == NULL ? '' : lastModified; } set; }
		public String ownerId { get { return ownerId == NULL ? '' : ownerId; } set; }
		public String ownerName { get { return ownerName == NULL ? 'undefined' : ownerName; } set; }
		public String aicon { get { return aicon == NULL ? 'fa-file-o' : aicon; } set; }
		public String previewUrl { get; set; }
		public String downloadUrl { get; set; }
		public String versionId { get; set; }
		public String documentId { get; set; }
		public String description { get; set; }
		public Boolean following { get; set; }
		public Boolean modifiable { get; set; }

		public String getShortName() {
			return name.abbreviate(20);
		}

		public FileWrapper(ConnectApi.FeedElement inchf, Boolean inf, Boolean inm, ContentDocument incd) {
			if (inchf.capabilities != NULL && inchf.capabilities.content != NULL) {
				ConnectApi.ContentCapability cc = inchf.capabilities.content;
				previewUrl = cc.renditionUrl720By480;
				downloadUrl = cc.downloadUrl;
				name = cc.title;
				aicon = !CommunitySearchController.AWESOME_FILE_TYPES.containsKey(cc.fileExtension) ? 'fa-file-o' : CommunitySearchController.AWESOME_FILE_TYPES.get(cc.fileExtension);
				versionId = cc.versionId;
				following = inf;
				modifiable = inm && String.isNotBlank(cc.versionId);
				ownerId = incd.OwnerId;
				ownerName = incd.Owner.Name;
				lastModified = CommunityFeedController.convertTimeDiff(incd.LastModifiedDate);
				description = incd.Description;
				documentId = incd.Id;
			}
		}
	}

	public class BlockWrapper {
		public String id { get; set; }
		public String name { get; set; }

		public BlockWrapper(String inid, String inname) {
			id = inid;
			name = inname;
		}
	}
}
global without sharing class CommunityFeedController {

	private static Integer RECENT_COMMENT_COUNT = 3;
	private static Integer PAGE_SIZE = 8;

	public String parentId { get { return parentId == NULL ? UserInfo.getUserId() : parentId; } set; }
	public String feedType { get;set; }
	public Boolean fullMode { get;set; }
	public String NetworkId {get { 
		if(!parentId.startsWith('0F9') && (String.isBlank(feedType) || feedType == '4' || feedType == '5')){
			return 'AllNetworks';
		}else{
			return Network.getNetworkId();
		}
		} set;}

	public String communityPrefix
	{
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
			return ConnectApi.ChatterUsers.getPhoto(Network.getNetworkId(),'me').smallPhotoUrl;
		}
	}

	@RemoteAction
	global static String feeds(String inParentId, String inFeedType, String inPageToken) {
		FeedElementPage pf = pullFeeds(inParentId, inFeedType, inPageToken);
		return json.serialize(pf);
	}

	
	private static FeedElementPage pullFeeds(String inParentId2, String inFeedType2, String inPageToken2) {
		ConnectApi.FeedElementPage fep = ConnectApi.ChatterFeeds.getFeedElementsFromFeed(
					Network.getNetworkId(),
					determineFeedType(inParentId2, inFeedType2),
					inParentId2,
					RECENT_COMMENT_COUNT,
					ConnectApi.FeedDensity.FewerUpdates,
					inPageToken2,
					PAGE_SIZE,
					ConnectApi.FeedSortOrder.CreatedDateDesc
				);
		String result = json.serialize(fep);
		FeedElementPage fepResult = (FeedElementPage)JSON.deserialize(result,FeedElementPage.class);
		fepResult = initialRoles(fepResult);
			
		return fepResult;
	}

	public static List<String> getUsersIdsForElement(FeedElementPage currentFEP, Page2 page) {
		Set<String> UsersIds = new Set<String>(); 
		if(currentFEP != null ) {
			for(FeedElement fe : currentFEP.elements) {
				if(fe.actor != null && String.isNotBlank(fe.actor.id)) {
					if(!UsersIds.contains(fe.actor.id)) {
						UsersIds.add(fe.actor.id);
					}
				}
				if(!fe.capabilities.comments.page.items.isEmpty()) {
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
			if(!fe.capabilities.comments.page.items.isEmpty()) {
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
		Map<Id, String> UserIdAndRoleMap = new Map<Id, String>();
		Map<Id, Id> UserIdAndContactId = new Map<Id, Id>();
		if(!userIds.isEmpty()) {
			for(User u : [SELECT Id, Contact.Primary_Role__c, Community_Contact_ID__c FROM User WHERE Id IN: userIds]) {
				if(u.Contact != null && u.Contact.Primary_Role__c != null){
					UserIdAndRoleMap.put(u.Id, (String)u.Contact.Primary_Role__c);
				}
				else if(u.Community_Contact_ID__c != null) {
					UserIdAndContactId.put(u.Id, u.Community_Contact_ID__c);
				}
			}
		}
		Map<Id, String> ContactIdAndRoleMap = new Map<Id, String>();
		if(!UserIdAndContactId.values().isEmpty()) {
			for(Contact c : [SELECT Id, Primary_Role__c, Name FROM Contact WHERE Id IN: UserIdAndContactId.values() AND Primary_Role__c != null]) {
				ContactIdAndRoleMap.put(c.Id, c.Primary_Role__c);
			}
			for(String uId : UserIdAndContactId.keySet()) {
				if(ContactIdAndRoleMap.containsKey(UserIdAndContactId.get(uId))) {
					if(!UserIdAndRoleMap.containsKey(uId)) {
						UserIdAndRoleMap.put(uId, ContactIdAndRoleMap.get(UserIdAndContactId.get(uId)));
					}
				}
			}
		}
		return UserIdAndRoleMap;
	}
	/*
	private static FeedElementPage pullFeeds(String inParentId2, String inFeedType2, String inPageToken2) {
		String result = json.serialize(
				ConnectApi.ChatterFeeds.getFeedElementsFromFeed(
					Network.getNetworkId(),
					determineFeedType(inParentId2, inFeedType2),
					inParentId2,
					RECENT_COMMENT_COUNT,
					ConnectApi.FeedDensity.FewerUpdates,
					inPageToken2,
					PAGE_SIZE,
					ConnectApi.FeedSortOrder.CreatedDateDesc
				)
		);
		system.debug(result);
		//System.debug('\n'+result);
		return (FeedElementPage)JSON.deserialize(result,FeedElementPage.class);
	}
	*/

	/*
		feed type map:
		1 - What I Follow
		2 - To Me
		3 - Bookmarks
		4 - UserProfile
		5 - Record
	*/
	private static Map<String, ConnectApi.FeedType> FT_MAP = new Map<String, ConnectApi.FeedType> {
		'1' => ConnectApi.FeedType.News, '2' => ConnectApi.FeedType.To, '3' => ConnectApi.FeedType.Bookmarks, '4' => ConnectApi.FeedType.UserProfile,
		'5' => ConnectApi.FeedType.Record
	};

	private static ConnectApi.FeedType determineFeedType(String inp, String inft) {
		if (String.isBlank(inft) || !FT_MAP.containsKey(inft)) {
			inft = inp.startsWith('005') ? (inp == UserInfo.getUserId() ? '1' : '4') : '5';
		}
		return FT_MAP.get(inft);
	}

	@RemoteAction
	global static String postFeed(String inParentId3, String inText3) {
		ConnectApi.FeedItemInput fei = new ConnectApi.FeedItemInput();
		fei.subjectId = inParentId3;
		fei.body = werewolfText(inText3);
		fei.feedElementType = ConnectApi.FeedElementType.FeedItem;
		String newFeed = json.serialize(ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), fei, NULL));
		FeedElementPage fepResult = new FeedElementPage();
		fepResult.elements = new List<FeedElement> { (FeedElement)JSON.deserialize(newFeed,FeedElement.class) };
		fepResult = initialRoles(fepResult);
		return json.serialize(fepResult);
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

	@RemoteAction
	global static String postAction(String inParentId4, String inText4, String inFile, String inFileType, String inFileName) {
		ChatterActionLayout layout = (ChatterActionLayout)JSON.deserialize(inText4,ChatterActionLayout.class);
		String errField;
		for (ChatterActionLayoutItem layoutItem : layout.items) {
			if (layoutItem.required && String.isBlank(layoutItem.value)) {
				errField = layoutItem.label;
				break;
			}
		}
		ConnectApi.FeedItemInput fei = new ConnectApi.FeedItemInput();
		fei.subjectId = inParentId4;
		fei.feedElementType = ConnectApi.FeedElementType.FeedItem;
		String resultPage;
		if (String.isNotBlank(errField)) {
			resultPage = 'ERR"' + errField + '" is required';
		} else if (layout.name == 'FeedItem.TextPost') {
			resultPage = postFeed(inParentId4, layout.items[0].value);
		}
		else if (layout.name == 'FeedItem.ContentPost') {			
			fei.capabilities = new ConnectApi.FeedElementCapabilitiesInput();
			fei.capabilities.content = new ConnectApi.ContentCapabilityInput();
			fei.capabilities.content.title = inFileName;
			fei.capabilities.content.description = layout.items[1].value;
			fei.body = werewolfText(layout.items[1].value);
			
		}
		else if (layout.name == 'FeedItem.LinkPost') {
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
			}
			if(choisesInd.size() != choices.size()){
				resultPage = 'ERR'+label.ERR_Pole_SameValueWarning;
			}else{
				fei.capabilities.poll.choices = choices;
				fei.body = werewolfText(layout.items[0].value);
			}
		}
		else {
			//QuickAction.QuickActionRequest req = new QuickAction.QuickActionRequest();
			// Some quick action name
			//req.quickActionName = layout.name; 

			// Define a record for the quick action to create
			Schema.SObjectType targetType = Schema.getGlobalDescribe().get(layout.objectName);
			sObject sObj = targetType.newSObject();
			String namespacePrefix = layout.objectName.split('__').size() > 2 ? layout.objectName.split('__')[0]+'__' : '';

			Map<String, Schema.DescribeFieldResult> sObjectFields = getSobjectFieldsDescribe(new List<String> { layout.objectName }).get(layout.objectName);

			for (ChatterActionLayoutItem item : layout.items) {
				if (sObjectFields.containsKey(item.fieldName)) {
					Schema.DisplayType tpOfItem = sObjectFields.get(item.fieldName).getType();
					if (tpOfItem == Schema.DisplayType.Datetime) {
						//sObj.put(item.fieldName, Datetime.newInstance(Date.parse(item.value), Time.newInstance(0,0,0,0)));
						sObj.put(item.fieldName, Datetime.parse(item.value));
					} else if (tpOfItem == Schema.DisplayType.Date){
						sObj.put(item.fieldName, Date.parse(item.value));
					} else {
						sObj.put(item.fieldName, item.value);
					}
				}
			}
			//req.record = sObj; 
			Database.SaveResult res = Database.insert(sObj);

			// Provide the context ID (or parent ID). In this case, it is an Account record.
			//req.contextid = UserInfo.getUserId(); 

			//QuickAction.QuickActionResult res = QuickAction.performQuickAction(req);
			//system.debug(res);
			if(res.isSuccess()){
				//resultPage = postFeed(inParentId4, res.getIds()[0]);
				if (layout.name == 'Create_Event') {
					fei.capabilities = new ConnectApi.FeedElementCapabilitiesInput();
					fei.capabilities.link = new ConnectApi.LinkCapabilityInput();
					fei.capabilities.link.url = prepareUrl(Page.CommunityEventDetail.getUrl()) + '?id=' + res.getId();
					//fei.capabilities.link.url = prepareUrl(Page.CommunityEventDetail.getUrl()) + '?id=' + res.getIds()[0];
					for(ChatterActionLayoutItem item : layout.items) {
						if(item.fieldName == namespacePrefix + 'Name__c') {
							fei.capabilities.link.urlName = item.value;
						}
						else if(item.fieldName == namespacePrefix + 'Description__c') {
							fei.body = werewolfText(item.value);
						}
					}

					//fei.body = werewolfText('Description');
				}
			}
			else{
				resultPage = 'ERR"' + res.getErrors() + '"';
			}


		}
		if (String.isBlank(resultPage) && fei.body != NULL) {
			//Blob inFileBlob = Blob.valueOf(inFile);
			ConnectApi.BinaryInput bi = null;
			
			try {
				bi = (inFile != NULL) ? new ConnectApi.BinaryInput(EncodingUtil.base64Decode(inFile), inFileType, inFileName) : NULL;
			}
			catch (Exception e)  {
				resultPage = 'ERR"' + e.getMessage() + '"';
			}
			System.debug('bin input:    ' + bi);

			if(bi != null) {				
				String newFeed2 = json.serialize(ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), fei, bi));
				System.debug('newFeed2:    ' + newFeed2);
				FeedElementPage fepResult2 = new FeedElementPage();
				fepResult2.elements = new List<FeedElement> { (FeedElement)JSON.deserialize(newFeed2,FeedElement.class) };
				fepResult2 = initialRoles(fepResult2);
				resultPage = json.serialize(fepResult2);
			
			}else{
				String newFeedInsert = json.serialize(ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(),fei,null));
				FeedElementPage fepResult = new FeedElementPage();
				fepResult.elements = new List<FeedElement> { (FeedElement)JSON.deserialize(newFeedInsert,FeedElement.class) };
				fepResult = initialRoles(fepResult);
				resultPage = json.serialize(fepResult);
			}
		}
		return resultPage;
	}

	private static String prepareUrl(String inUncouthUrl) {
		return String.isNotBlank(Site.getPathPrefix()) ? inUncouthUrl.replace('/apex/', Site.getPathPrefix() + '/') : inUncouthUrl;
	}

	@RemoteAction
	global static String postComment(String inFeedId, String inCommentText) {
		ConnectApi.CommentInput ci = new ConnectApi.CommentInput();
		ci.body = werewolfText(inCommentText);
		String newComment = json.serialize(ConnectApi.ChatterFeeds.postCommentToFeedElement(Network.getNetworkId(), inFeedId, ci, NULL));
		Page2 commentPage = new Page2();
		commentPage.feedId = inFeedId;
		commentPage.items = new List<FeedElementComment> { (FeedElementComment)JSON.deserialize(newComment,FeedElementComment.class) };
		commentPage = initialRoles(commentPage);
		return json.serialize(commentPage);
	}

	@RemoteAction
	global static String getComments(String inFeedId, String inPageToken) {
		String commentsString = json.serialize(ConnectApi.ChatterFeeds.getCommentsForFeedElement(Network.getNetworkId(), inFeedId, inPageToken, RECENT_COMMENT_COUNT));
		Page2 commentPage2 = (Page2)JSON.deserialize(commentsString,Page2.class);
		commentPage2.feedId = inFeedId;
		commentPage2 = initialRoles(commentPage2);	
		return json.serialize(commentPage2);
	}

	@RemoteAction
	global static String getUsers(String query) {
		List<MentionUser> result = new List<MentionUser>();
		query = query + '%';
		for (User u : [
				SELECT Id, Name, SmallPhotoUrl, Contact.Primary_Role__c
				FROM User WHERE (ContactId != NULL OR Community_Contact_ID__c != NULL) AND isActive = true 
				AND (FirstName LIKE :query OR LastName LIKE :query)]) {
			result.add(new MentionUser(u));
		}
		for (Community_Group_Control__c cgc : [
				SELECT Chatter_Group_ID__c, Name
				FROM Community_Group_Control__c
				WHERE Chatter_Group_ID__c != NULL AND Name LIKE :query
					]) {
			result.add(new MentionUser(cgc));
		}
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

	@RemoteAction
	global static String voteOnPoll(Id pollId, Id choiceId, String inParentId, String inFeedType) {
		ConnectApi.PollCapability poll = ConnectApi.ChatterFeeds.voteOnFeedElementPoll(Network.getNetworkId(), pollId, choiceId);
		return feeds(inParentId, inFeedType, NULL);
	}

	@RemoteAction
	global static String werewolfTextRemote(String intxtr, String jsStr) {
		ChatterActionLayout layout = (ChatterActionLayout)JSON.deserialize(jsStr,ChatterActionLayout.class);			
		String intxt = layout.items[1].value;
		Body result = new Body();
		result.messageSegments = new List<MessageSegments>();
		while(intxt.length() > 0) {
			MessageSegments msi = new MessageSegments();
			msi.record = new Record();
			Integer index = intxt.indexOf('@[');
			index = index == -1 ? intxt.length() : index;
			if (index > 0) {
				msi.text = intxt.substring(0, index);
				msi.type = 'Text';
				result.messageSegments.add(msi);
				intxt = intxt.substring(index, intxt.length());
			}
			else {
				Integer endIndex = intxt.indexOf(']');
				if (endIndex != -1) {
					try {
						msi.type = 'Mention';
						msi.record.id = intxt.substring(index + 2, endIndex);
						result.messageSegments.add(msi);
					}
					catch (Exception e) {
						endIndex = index + 1;
					}
				}
				else {
					endIndex = index + 1;
				}
				intxt = intxt.substring(endIndex + 1, intxt.length());
			}
		}
System.debug('result R ==> '+result);			
		return json.serialize(result);
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
				if (endIndex != -1) {
					try {
						ConnectApi.MentionSegmentInput msi = new ConnectApi.MentionSegmentInput();
						msi.id = Id.valueOf(intxt.substring(index + 2, endIndex));
						result.messageSegments.add(msi);
					}
					catch (Exception e) {
						endIndex = index + 1;
					}
				}
				else {
					endIndex = index + 1;
				}
				intxt = intxt.substring(endIndex + 1, intxt.length());
			}
		}
	System.debug('result  ==> '+result);	
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
		public Boolean isDeleteRestricted { get; set; }
		public String countLikes { get { return (capabilities.chatterLikes != NULL) ? String.valueOf(capabilities.chatterLikes.page.total) : '0'; } }
		public String likeStyle { get { return (capabilities.chatterLikes != NULL && capabilities.chatterLikes.isLikedByCurrentUser) ? ' active' : ''; } }
		public String bookmarkStyle { get { return (capabilities.bookmarks != NULL && capabilities.bookmarks.isBookmarkedByCurrentUser) ? ' active' : ''; } }
		public String likeId { get { return (capabilities.chatterLikes != NULL && capabilities.chatterLikes.isLikedByCurrentUser) ? capabilities.chatterLikes.myLike.id : ''; } }
		public String bookmarkStatus { get { return (capabilities.bookmarks != NULL && capabilities.bookmarks.isBookmarkedByCurrentUser) ? 'true' : ''; } }
		public Boolean showLink { get { return capabilities.link != NULL; } }
		public String linkHref { get { return capabilities.link != NULL ? capabilities.link.url : ''; } }
		public String linkName { get { return capabilities.link != NULL ? capabilities.link.urlName : ''; } }

		public Boolean showContent { get { return capabilities.content != NULL; } }
		public Boolean showFlag { get { return capabilities.moderation != NULL; } }
		public Boolean flagged { get { return (showFlag && capabilities.moderation != NULL && capabilities.moderation.moderationFlags != NULL) ? capabilities.moderation.moderationFlags.flaggedByMe : false; } }
		public String flagStatus { get { return flagged ? 'true' : ''; } }
		public String flagStyle { get { return flagged ? ' active' : ''; } }
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

	public class Bookmarks {
		public Boolean isBookmarkedByCurrentUser { get; set; }
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
		public Actor user { get; set; }
		public Datetime createdDate { get; set; }
		public String dateStr { get { return convertTimeDiff(createdDate);} }
		public Boolean isDeleteRestricted { get; set; }
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

	public class MentionUser {
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

		public MentionUser(Community_Group_Control__c incgc) {
			id = incgc.Chatter_Group_ID__c;
			name = incgc.Name;
			avatar = CommunityUtils.checkUrl('/profilephoto/0F9/F');
			type = 'group';
		}
	}
	
	private static List<List<String>> CHATTER_ACTIONS = new List<List<String>> {
		new List<String> { label.LBL_Post, 'FeedItem.TextPost', 'fa-comment', 'Post'},
		new List<String> { label.LBL_File, 'FeedItem.ContentPost', 'fa-file-o', 'File'},
		new List<String> { label.LBL_Link, 'FeedItem.LinkPost', 'fa-link', 'Link'},
		new List<String> { Label.LBL_Poll, 'FeedItem.PollPost', 'fa-bar-chart', 'Poll'},
		new List<String> { 'Create Event', 'Create_Event', 'fa-calendar', 'Create Event'}
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
		for (List<String> caa : CHATTER_ACTIONS) {
			if (actionAvailable.containsKey(caa[3])) {
				resultList.add(new ChatterActionItem(caa[0],caa[1],caa[2]));
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

		//public ChatterActionLayoutItem(String l, String fn, String ft, String v, Boolean r) {
		//	this.label = l;
		//	this.fieldName = fn;
		//	this.ftype = ft;
		//	this.value = v;
		//	this.required = r;
		//}
		//public ChatterActionLayoutItem(String l, String fn, String ft, String v, Boolean r, String plchldr) {
		//	this.label = l;
		//	this.fieldName = fn;
		//	this.ftype = ft;
		//	this.value = v;
		//	this.required = r;
		//	this.placeholder = plchldr;
		//}
		//public ChatterActionLayoutItem(String l, String fn, String ft, String v, Boolean r, String plchldr, String vC) {
		//	this.label = l;
		//	this.fieldName = fn;
		//	this.ftype = ft;
		//	this.value = v;
		//	this.required = r;
		//	this.placeholder = plchldr;
		//	this.validationClass = vC;
		//}

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
		else {
			List<QuickAction.DescribeQuickActionResult> dqar = QuickAction.describeQuickActions(new List<String> {name});
			if (dqar.size() == 1) {
				result = new ChatterActionLayout(dqar[0]);
			}
		}
		return JSON.serialize(result);
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
public with sharing class CommunityFeedController {

	private static Integer RECENT_COMMENT_COUNT = 3;
	private static Integer PAGE_SIZE = 8;

	public String parentId { get { return parentId == NULL ? UserInfo.getUserId() : parentId; } set; }
	public String feedType { get;set; }
	public Boolean fullMode { get;set; }

	public String currentUserPhoto {
		get {
			return ConnectApi.ChatterUsers.getPhoto(Network.getNetworkId(),'me').smallPhotoUrl;
		}
	}

	@RemoteAction
	public static String feeds(String inParentId, String inFeedType, String inPageToken) {
		return json.serialize(pullFeeds(inParentId, inFeedType, inPageToken));
	}

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
				));
		//System.debug('\n'+result);
		return (FeedElementPage)JSON.deserialize(result,FeedElementPage.class);
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
	public static String postFeed(String inParentId3, String inText3) {
		ConnectApi.FeedItemInput fei = new ConnectApi.FeedItemInput();
		fei.subjectId = inParentId3;
		fei.body = werewolfText(inText3);
		fei.feedElementType = ConnectApi.FeedElementType.FeedItem;
		String newFeed = json.serialize(ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), fei, NULL));
		FeedElementPage fepResult = new FeedElementPage();
		fepResult.elements = new List<FeedElement> { (FeedElement)JSON.deserialize(newFeed,FeedElement.class) };
		return json.serialize(fepResult);
	}

	@RemoteAction
	public static String postComment(String inFeedId, String inCommentText) {
		ConnectApi.CommentInput ci = new ConnectApi.CommentInput();
		ci.body = werewolfText(inCommentText);
		String newComment = json.serialize(ConnectApi.ChatterFeeds.postCommentToFeedElement(Network.getNetworkId(), inFeedId, ci, NULL));
		Page2 commentPage = new Page2();
		commentPage.feedId = inFeedId;
		commentPage.items = new List<FeedElementComment> { (FeedElementComment)JSON.deserialize(newComment,FeedElementComment.class) };
		return json.serialize(commentPage);
	}

	@RemoteAction
	public static String getComments(String inFeedId, String inPageToken) {
		String commentsString = json.serialize(ConnectApi.ChatterFeeds.getCommentsForFeedElement(Network.getNetworkId(), inFeedId, inPageToken, RECENT_COMMENT_COUNT));
		Page2 commentPage2 = (Page2)JSON.deserialize(commentsString,Page2.class);
		commentPage2.feedId = inFeedId;
		return json.serialize(commentPage2);
	}

	@RemoteAction
	public static String getUsers(String query) {
		List<MentionUser> result = new List<MentionUser>();
		query = query + '%';
		for (User u : [
				SELECT Id, Name, SmallPhotoUrl
				FROM User WHERE (ContactId != NULL OR Community_Contact_ID__c != NULL) AND isActive = true 
				AND (FirstName LIKE :query OR LastName LIKE :query)]) {
			result.add(new MentionUser(u));
		}
		for (Community_Group_Control__c cgc : [
				SELECT Chatter_Group_ID__c, Image_Path__c, Name
				FROM Community_Group_Control__c
				WHERE Chatter_Group_ID__c != NULL AND Name LIKE :query
					]) {
			result.add(new MentionUser(cgc));
		}
		return json.serialize(result);
	}

	@RemoteAction
	public static String inlineAction(String inPid, String inCname, String inOid) {
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
		public Body body { get; set; }
		public Capabilities capabilities { get; set; }
		public Datetime createdDate { get; set; }
		public String id { get; set; }
		public String dateStr { get { return convertTimeDiff(createdDate);} }
		public Integer total { get { return capabilities.comments.page.total; }}
		public Boolean showCommentsCount { get {return total > 0;}}
		public Boolean showComments { get { return capabilities.comments.page.items.size() > 0; } }
		public Boolean isDeleteRestricted { get; set; }
		public String countLikes { get { return String.valueOf(capabilities.chatterLikes.page.total); } }
		public String likeStyle { get { return capabilities.chatterLikes.isLikedByCurrentUser ? ' active' : ''; } }
		public String bookmarkStyle { get { return capabilities.bookmarks.isBookmarkedByCurrentUser ? ' active' : ''; } }
		public String likeId { get { return capabilities.chatterLikes.isLikedByCurrentUser ? capabilities.chatterLikes.myLike.id : ''; } }
		public String bookmarkStatus { get { return capabilities.bookmarks.isBookmarkedByCurrentUser ? 'true' : ''; } }
		public Boolean showLink { get { return capabilities.link != NULL; } }
		public String linkHref { get { return capabilities.link != NULL ? capabilities.link.url : ''; } }
		public String linkName { get { return capabilities.link != NULL ? capabilities.link.urlName : ''; } }
		public Boolean showFlag { get { return capabilities.moderation != NULL; } }
		public Boolean flagged { get { return (showFlag && capabilities.moderation.moderationFlags != NULL) ? capabilities.moderation.moderationFlags.flaggedByMe : false; } }
		public String flagStatus { get { return flagged ? 'true' : ''; } }
		public String flagStyle { get { return flagged ? ' active' : ''; } }
	}

	public class Body {
		public String text { get; set; }
	}

	public class Actor {
		public String displayName { get; set; }
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
		public string url { get; set; }
		public string urlName { get; set; }
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

	private static String[] dLbl = String.isNotBlank(Label.Feeds_Time) ? Label.Feeds_Time.split(';') : (new String[]{});
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
		public String type { get; set; }

		public MentionUser(User inu) {
			id = inu.Id;
			name = inu.Name;
			avatar = inu.SmallPhotoUrl;
			type = 'user';
		}

		public MentionUser(Community_Group_Control__c incgc) {
			id = incgc.Chatter_Group_ID__c;
			name = incgc.Name;
			avatar = Site.getPathPrefix() + incgc.Image_Path__c;
			type = 'group';
		}
	}

	private static List<List<String>> CHATTER_ACTIONS = new List<List<String>> {
		new List<String> { 'Comment', 'FeedItem.TextPost', 'fa-comment'},
		/*new List<String> { 'File', 'FeedItem.ContentPost', 'fa-file-o'},*/
		new List<String> { 'Link', 'FeedItem.LinkPost', 'fa-link'}/*,
		new List<String> { 'Poll', 'FeedItem.PollPost', 'fa-bar-chart'},
		new List<String> { 'Create Event', 'Create_Event', 'fa-calendar'}*/
	};

	private static Map<String, String> ACTION_LAYOUT = new Map<String, String> {
		'FeedItem.TextPost' => '{"name":"FeedItem.TextPost","items":[{"required":true,"ftype":"post"}]}',
		'FeedItem.ContentPost' => '{label: "Link URL", fieldName: "", ftype: "input", value: "", required: true},{label: "", fieldName: "", ftype: "post", value: "", required: false},{label: "Link URL", fieldName: "", ftype: "input", value: "", required: true}',
		'FeedItem.LinkPost' => '{"name":"FeedItem.LinkPost","items":[{"required":true,"label":"Link URL","ftype":"input"},{"label":"Link Name","ftype":"input"},{"ftype":"post"}],"beforeFields":true}',
		'FeedItem.PollPost' => '{label: "Link URL", fieldName: "", ftype: "input", value: "", required: true},{label: "", fieldName: "", ftype: "post", value: "", required: false},{label: "Link URL", fieldName: "", ftype: "input", value: "", required: true}'
	};

	public List<ChatterActionItem> getAvailableActions() {
		List<ChatterActionItem> resultList = new List<ChatterActionItem>();
		for (List<String> caa : CHATTER_ACTIONS) {
			resultList.add(new ChatterActionItem(caa[0],caa[1],caa[2]));
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
	}

	public class ChatterActionLayoutItem {
		public String label { get { return label == NULL ? '' : label; } set; }
		public String fieldName { get { return fieldName == NULL ? '' : fieldName; } set; }
		public String ftype { get { return ftype == NULL ? 'text' : ftype; } set; }
		public String value { get { return value == NULL ? '' : value; } set; }
		public Boolean required { get { return required == NULL ? false : required; } set; }
	}

	@RemoteAction
	public static String actionLayout(String name) {
		/*ChatterActionLayout cal = new ChatterActionLayout();
		cal.name = 'FeedItem.LinkPost';
		cal.beforeFields = true;
		cal.items = new List<ChatterActionLayoutItem>();
		ChatterActionLayoutItem cali1 = new ChatterActionLayoutItem();
		cali1.label = 'Link URL';
		cali1.ftype = 'input';
		cali1.required = true;
		cal.items.add(cali1);
		ChatterActionLayoutItem cali2 = new ChatterActionLayoutItem();
		cali2.label = 'Link Name';
		cali2.ftype = 'input';
		cali2.required = true;
		cal.items.add(cali2);
		ChatterActionLayoutItem cali = new ChatterActionLayoutItem();
		cali.ftype = 'post';
		cal.items.add(cali);
		System.debug(json.serialize(cal));
		return name;*/
		return JSON.serialize((ChatterActionLayout)JSON.deserialize(ACTION_LAYOUT.get(name),ChatterActionLayout.class));
	}
}
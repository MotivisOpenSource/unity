@isTest
private class CommunityUrlRewriterTest {
	private static final String STANDARD_CHATTER_PAGE = '/chatter/';
	private static final String STANDARD_GROUP_DETAIL_PAGE = '/groups/';
	private static final String STANDARD_USER_DETAIL_PAGE = '/userprofile/';
	private static final String CHATTER_COMMENT_NOTIFICATION = 'chatterCommentNotification';
	private static final String CHATTER_POST_NOTIFICATION = 'chatterPostNotification';
	private static final String CHATTER_PRIVATE_MESSAGE_NOTIFICATION = 'chatterPrivateMessageNotification';
	private static final String CHATTER_LIKE_NOTIFICATION = 'chatterLikeNotification';
	private static final String testUrl = 'testUrl';
	private static final String messageTypeParam = 'emkind';
	private static final String testId = '123456789';

	private static String prepareFeedItemData() {
		FeedItem testFeedItem = new FeedItem(
			ParentId = UserInfo.getUserId(),
			Body = 'testBody'
		);
		insert testFeedItem;

		return testFeedItem.Id;
	}

	static testMethod void commonRewriterTest() {
		String feedItemId = prepareFeedItemData();
		CommunityUrlRewriter testRewriter = new CommunityUrlRewriter();

		PageReference testPageRef = new PageReference(STANDARD_USER_DETAIL_PAGE + testUrl);
		testPageRef.getParameters().put('u', testId);
		testPageRef.getParameters().put('fi', testId);
		testRewriter.mapRequestUrl(testPageRef);

		testPageRef = new PageReference(STANDARD_CHATTER_PAGE + testUrl);
		testRewriter.mapRequestUrl(testPageRef);

		testPageRef = new PageReference(STANDARD_GROUP_DETAIL_PAGE + testUrl);
		testPageRef.getParameters().put('u', testId);
		testPageRef.getParameters().put('g', UserInfo.getUserId());
		testRewriter.mapRequestUrl(testPageRef);

		testPageRef = new PageReference(testUrl);
		testPageRef.getParameters().put(messageTypeParam, CHATTER_PRIVATE_MESSAGE_NOTIFICATION);
		testRewriter.mapRequestUrl(testPageRef);

		testPageRef = new PageReference(testUrl);
		testPageRef.getParameters().put(messageTypeParam, CHATTER_POST_NOTIFICATION);
		testPageRef.getParameters().put('fid', testId);
		testRewriter.mapRequestUrl(testPageRef);

		testPageRef = new PageReference(testUrl);
		testPageRef.getParameters().put(messageTypeParam, CHATTER_COMMENT_NOTIFICATION);
		testPageRef.getParameters().put('fId', feedItemId);
		testPageRef.getParameters().put('s1uid', Userinfo.getUserId());
		testRewriter.mapRequestUrl(testPageRef);

		testPageRef = new PageReference(testUrl);
		testPageRef.getParameters().put(messageTypeParam, CHATTER_COMMENT_NOTIFICATION);
		testPageRef.getParameters().put('fId', feedItemId);
		testPageRef.getParameters().put('s1uid', testId);
		testRewriter.mapRequestUrl(testPageRef);

		System.assertEquals(testRewriter.generateUrlFor(new List<PageReference>()), null);
	}
}
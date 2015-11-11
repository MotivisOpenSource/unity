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

global without sharing class CommunityUrlRewriter implements Site.UrlRewriter {

	public final String STANDARD_CHATTER_PAGE = '/chatter/';
	public final String STANDARD_GROUP_DETAIL_PAGE = '/groups/';
	public final String STANDARD_USER_DETAIL_PAGE = '/userprofile/';
	public final String STANDARD_TOPIC_PAGE = '/topics/';
	public final String CHATTER_COMMENT_NOTIFICATION = 'chatterCommentNotification';
	public final String CHATTER_POST_NOTIFICATION = 'chatterPostNotification';
	public final String CHATTER_PRIVATE_MESSAGE_NOTIFICATION = 'chatterPrivateMessageNotification';
	public final String CHATTER_LIKE_NOTIFICATION = 'chatterLikeNotification';


	global PageReference mapRequestUrl(PageReference myFriendlyUrl) {
		String url = myFriendlyUrl.getUrl();
		String messageType = myFriendlyUrl.getParameters().get('emkind');
		PageReference redirect;

		if (myFriendlyUrl.getParameters().containsKey('nr')) {

		}
		else if (url.contains(STANDARD_USER_DETAIL_PAGE)) {
			redirect = Page.CommunityProfilePage;
			String uId = '';
			Pattern myP = Pattern.compile('[\\?&]u=([^&]*)');
			Matcher myM = myP.matcher(url);
			if (myM.find()) {
				uId = myM.group(1);
				redirect.getparameters().put('id', uId);
			}
		}
		else if (url.contains(STANDARD_CHATTER_PAGE)) {
			redirect = Page.CommunityFeed_MyFeed;
		}

		if (url.contains(STANDARD_GROUP_DETAIL_PAGE)) {
			redirect = Page.CommunityGroupDetailPage;
			redirect.getParameters().put('gr', String.valueOf(Id.valueof(myFriendlyUrl.getparameters().get('g'))));
			String filterParam = myFriendlyUrl.getparameters().get('filter');
			String userParam = myFriendlyUrl.getparameters().get('u');
			if ((String.isNotBlank(filterParam) && filterParam == 'requests') || String.isNotBlank(userParam)) {
				redirect.getParameters().put('pending', 'true');
				if (String.isNotBlank(userParam)) {
					redirect.getParameters().put('u', userParam);
				}
			}
		}
		else if (messageType == CHATTER_PRIVATE_MESSAGE_NOTIFICATION && !url.contains(STANDARD_USER_DETAIL_PAGE)) {
			redirect = Page.CommunityFeed_MyMessages;
		}
		else if (messageType == CHATTER_POST_NOTIFICATION && myFriendlyUrl.getParameters().get('fId') != null) {
			redirect = Page.CommunityFeed_MyFeed;
		}
		else if (messageType == CHATTER_COMMENT_NOTIFICATION || messageType == CHATTER_LIKE_NOTIFICATION) {
			String feedItemId = myFriendlyUrl.getParameters().get('fId');
			if (!String.isBlank(feedItemId)) {
				String parentId = [SELECT Id, ParentId FROM FeedItem WHERE Id = :feedItemId LIMIT 1].ParentId;
				String currentId = myFriendlyUrl.getParameters().get('s1uid');
				if (parentId.substring(0, currentId.length()) == currentId) {
					redirect = Page.CommunityFeed_MyFeed;
				}
				else {
					redirect = Page.CommunityProfilePage;
					redirect.getParameters().put('id', parentId);
					redirect.getParameters().put('f', '2');
				}
			}
		}
		
		if (url.contains(STANDARD_TOPIC_PAGE)) {
			redirect = Page.CommunityTopic;            
			redirect.getParameters().put('id', myFriendlyUrl.getParameters().get('id'));
		}

		return redirect;
	}

	global List<PageReference> generateUrlFor(List<PageReference> mySalesforceUrls) {
		return NULL;
	}

}
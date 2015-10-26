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

	/*//Variables to represent the user-friendly URLs for community*/
	String STANDARD_CHATTER_PAGE = '/chatter/';
	String STANDARD_GROUP_DETAIL_PAGE = '/groups/';
	String STANDARD_USER_DETAIL_PAGE = '/userprofile/';
	/*String STANDARD_DIRECT_MESSAGE = 'deepLinkType=directMessage';
	String STANDARD_CONTACT_PAGE = '/learning/005';
	//String STANDARD_CONTACT_PAGE = '/learning/005';*/
	private final String CHATTER_COMMENT_NOTIFICATION = 'chatterCommentNotification';
	private final String CHATTER_POST_NOTIFICATION = 'chatterPostNotification';
	private final String CHATTER_PRIVATE_MESSAGE_NOTIFICATION = 'chatterPrivateMessageNotification';

	global PageReference mapRequestUrl(PageReference myFriendlyUrl) {
		String url = myFriendlyUrl.getUrl();
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
		else if (myFriendlyUrl.getParameters().get('emkind') == CHATTER_PRIVATE_MESSAGE_NOTIFICATION) {
			redirect = Page.CommunityFeed_MyMessages;
		}
		else if (myFriendlyUrl.getParameters().get('emkind') == CHATTER_POST_NOTIFICATION) {
			redirect = Page.CommunityFeed_MyFeed;
		}
		else if (myFriendlyUrl.getParameters().get('emkind') == CHATTER_COMMENT_NOTIFICATION) {
			String feedItemId = myFriendlyUrl.getParameters().get('fId');
			if (!String.isBlank(feedItemId)) {
				String parentId = [SELECT Id, ParentId FROM FeedItem WHERE Id = :feedItemId LIMIT 1].ParentId;
				redirect = Page.CommunityProfilePage;
				redirect.getParameters().put('id', parentId);
			}
		}

		return redirect;
	}

	global List<PageReference> generateUrlFor(List<PageReference> mySalesforceUrls) {
		return NULL;
	}

}
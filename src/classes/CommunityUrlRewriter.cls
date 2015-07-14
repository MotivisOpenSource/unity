global without sharing class CommunityUrlRewriter implements Site.UrlRewriter {

	/*//Variables to represent the user-friendly URLs for community*/
	String STANDARD_CHATTER_PAGE = '/chatter/';
	String STANDARD_GROUP_DETAIL_PAGE = '/groups/';
	String STANDARD_USER_DETAIL_PAGE = '/userprofile/';
	/*String STANDARD_DIRECT_MESSAGE = 'deepLinkType=directMessage';
	String STANDARD_CONTACT_PAGE = '/learning/005';
	//String STANDARD_CONTACT_PAGE = '/learning/005';*/

	global PageReference mapRequestUrl(PageReference myFriendlyUrl) {
		String url = myFriendlyUrl.getUrl();
		PageReference redirect;
		
		if (myFriendlyUrl.getParameters().containsKey('nr')) {
			
		}
		else if(url.contains('_ui/core/')){
			redirect = Page.CommunityHome;
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
			if((String.isNotBlank(filterParam) && filterParam == 'requests') || String.isNotBlank(userParam)) {
				redirect.getParameters().put('pending', 'true');
				if (String.isNotBlank(userParam)) {
					redirect.getParameters().put('u', userParam);
				}
			}
		}

		return redirect;
	}

	global List<PageReference> generateUrlFor(List<PageReference> mySalesforceUrls) {
		return NULL;
	}
		
}
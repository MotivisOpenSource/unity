public with sharing class CommunityFeedNavigationController {
/*
	// -- common variables --
	public User currentUser { get; set; }
	public String SitePrefix {
		get {
			if (this.SitePrefix == NULL) {
				this.SitePrefix = Site.getPathPrefix();
			}
			return this.SitePrefix;
		}
		private set;
	}
	public String currentPanel { get; set; }
	public String currentElement { get; set; }
	public Boolean isAllowMessage { get; set; }
	private final String CurrentCommunityId = CommunityGroupsBase.getCurrentCommunityId();

	//CONSTRUCTOR
	public CommunityFeedNavigationController() {

		List<User> userList = new List<User>();

		userList = getListUsersFromId(UserInfo.getUserId());
		if (!userList.isEmpty()) {
			this.currentUser = userList[0];
		}

		isAllowMessage = true;

		try {
//			ConnectApi.?Chatter?ConversationPage conversationPage =
				ConnectApi.ChatterMessages.getConversations(CurrentCommunityId);
		}
		catch (exception e) {
			isAllowMessage = false;
		}

		return;
	}


	//PUBLIC METHODS




	//PRIVATE METHODS


	//GET CurrentUser
	private List<User> getListUsersFromId(String userId) {

		List<User> result = new List<User>();

		if (!String.isBlank(userId)) {
			result = [
				SELECT Id, FirstName, LastName
				FROM User
				WHERE Id =: userId
				LIMIT 1
			];
		}

		return result;
	}
*/

	public Integer MessageUnreadCount { get; set; }
	public Boolean showMessages {
		get {
			Boolean result = true;
			try {
				ConnectApi.ChatterConversationPage cp = ConnectApi.ChatterMessages.getConversations(Network.getNetworkId());
				ConnectApi.UnreadConversationCount unreadCount = ConnectApi.ChatterMessages.getUnreadCount(CommunityGroupsBase.getCurrentCommunityId());
				MessageUnreadCount  = unreadCount.UnreadCount;
			}
			catch (exception e) {
				result = false;
			}
			return result;
		}
	}

	public Boolean showGroupManager {
		get {
			if(ApexPages.currentPage().getParameters().containsKey('g'))
			{
				String groupId = ApexPages.currentPage().getParameters().get('g');
				List<Community_Group_Membership__c> cgmList = [SELECT Id FROM Community_Group_Membership__c WHERE Group_Membership_User__c = :UserInfo.getUserId() AND Group_Control__r.Chatter_Group_ID__c = :groupId];
				return cgmList.size() > 0;
			} else {
				return false;
			}
		}
	}
}
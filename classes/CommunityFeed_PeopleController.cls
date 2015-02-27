public with sharing class CommunityFeed_PeopleController extends CommunityFeedBase {

	public CommunityFeed_PeopleController() {
	}
	@RemoteAction
	public static List<ChatterGroupMember> getPeoples() {
		List<ChatterGroupMember> peoples = new List<ChatterGroupMember>();
		List<EntitySubscription> followings = [
			Select SubscriberId, ParentId, IsDeleted, Id, CreatedDate, CreatedById
			From EntitySubscription
			WHERE SubscriberId =:Userinfo.getUserId()
			AND IsDeleted = false
			LIMIT 1000
		];
		Set<Id> followingsIds = new Set<Id>();
		for (EntitySubscription subscription : followings) {
			followingsIds.add(subscription.ParentId);
		}
		for (User u : [
				SELECT Id, Name, FirstName, LastName, SmallPhotoUrl, FullPhotoUrl, ContactId, Contact.Primary_Role__c
				FROM User 
				WHERE (ContactId != NULL OR Community_Contact_ID__c != NULL) 
				AND isActive = true 
				AND Id != :UserInfo.getUserId()
				ORDER BY Name ASC
		]) {
			peoples.add(new ChatterGroupMember(u, followingsIds.contains(u.Id)));
		}
		return peoples;
	}

	@RemoteAction
	public static Boolean subscriberAction(Id memberId, Boolean isSubscribe) {
		if (!isSubscribe) {
			List<EntitySubscription> followings = [
				Select SubscriberId, ParentId, IsDeleted, Id, CreatedDate, CreatedById
				From EntitySubscription
				WHERE SubscriberId =:Userinfo.getUserId()
				AND ParentId = :memberId
				LIMIT 1
			];
			if (!followings.isEmpty()) {
				ConnectApi.Chatter.deleteSubscription(CommunityGroupsBase.getCurrentCommunityId(), followings[0].Id);
			}
		} else if (isSubscribe) {
			ConnectApi.ChatterUsers.follow(CommunityGroupsBase.getCurrentCommunityId(), 'me', memberId);
		}
		return true;
	}
}
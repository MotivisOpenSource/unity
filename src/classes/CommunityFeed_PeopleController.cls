public with sharing class CommunityFeed_PeopleController {

	public CommunityFeed_PeopleController() {
	}
	@RemoteAction
	public static List<UserItem> getPeoples() {
		List<UserItem> peoples = new List<UserItem>();
		List<EntitySubscription> followings = [
			SELECT SubscriberId, ParentId, IsDeleted, Id, CreatedDate, CreatedById
			FROM EntitySubscription WHERE SubscriberId =:Userinfo.getUserId() AND IsDeleted = false
			LIMIT 1000
		];
		Set<Id> followingsIds = new Set<Id>();
		for (EntitySubscription subscription : followings) { 
			followingsIds.add(subscription.ParentId); 
		}
		
		List<User> uList = CommunityHelperWithoutSharing.getCommunityUsers(null,100,new List<String>{'FirstName', 'LastName', 'SmallPhotoUrl', 'FullPhotoUrl', 'ContactId', 'Contact.Primary_Role__c', 'Community_Contact_ID__c'},'Name',true);
		/*List<User> uList = [
			SELECT Id, Name, FirstName, LastName, SmallPhotoUrl, FullPhotoUrl, ContactId, Contact.Primary_Role__c, Community_Contact_ID__c
			FROM User 
			WHERE (ContactId != NULL OR Community_Contact_ID__c != NULL) AND isActive = true AND Id != :UserInfo.getUserId()
			ORDER BY Name ASC
				];*/ 
		securityWrapper sw = new securityWrapper();
		Map<Id,String> contactRoles = sw.prepareRoles(uList);
		for (User uItem2 : uList) {
			Id cId2 = getId(uItem2);
			peoples.add(new UserItem(
				uItem2,
				followingsIds.contains(uItem2.Id),
				cId2 == NULL ? '' : contactRoles.get(cId2)
			));
		}
		return peoples;
	}

	private static Id getId(User inu) {
		Id result;
		try {
			result = Id.valueOf(inu.ContactId == NULL ? inu.Community_Contact_ID__c : inu.ContactId);
		}
		catch (Exception e) {}
		return result;
	}

	@RemoteAction
	public static Boolean subscriberAction(Id memberId, Boolean isSubscribe) {
		CommunityUtils.subscriberUser(memberId,isSubscribe);
		return true;
	}

	public class UserItem {
		public Id MemberId { get; set; }
		public String MemberName { get; set; }
		public String MemberRole { get; set; }
		public String MemberPhotoUrl {
			get {
				if (String.isBlank(this.MemberPhotoUrl)) {
					this.MemberPhotoUrl = '/profilephoto/005/T';
				}
				this.MemberPhotoUrl = this.MemberPhotoUrl.replace(Site.getBaseUrl(), '');
				return this.MemberPhotoUrl;
			}
			set;
		}
		public Boolean MemberIsFollowing { get; set; }

		public UserItem(User member, Boolean isFollowing, String role) {
			this.MemberId = member.Id;
			this.MemberName = String.format('{0}{1}',
				new List<String> {
					!String.isBlank(member.FirstName) ? member.FirstName + ' ' : '',
					!String.isBlank(member.LastName) ? member.LastName : ''
				}
			);
			this.MemberRole = role;
			this.MemberPhotoUrl = member.SmallPhotoUrl;
			this.MemberIsFollowing = isFollowing;
		}
	}

	private without sharing class securityWrapper {
		public Map<Id,String> prepareRoles(List<User> inUsers) {
			Map<Id,String> resultRoles = new Map<Id,String>();
			Set<Id> contactsToFindRole = new Set<Id>();
			for (User uItem : inUsers) {
				if (uItem.ContactId != NULL) {
					resultRoles.put(uItem.ContactId, uItem.Contact.Primary_Role__c);
				}
				else {
					Id cId = getId(uItem);
					if (cId != NULL) {
						contactsToFindRole.add(cId);
					}
				}
			}
			if (contactsToFindRole.size() > 0) {
				for (Contact cItem : [SELECT Id, Primary_Role__c FROM Contact WHERE Id IN :contactsToFindRole]) {
					resultRoles.put(cItem.Id, cItem.Primary_Role__c);
				}
			}
			return resultRoles;
		}
	}
}
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

public with sharing class CommunityFeed_PeopleController {

	public CommunityFeed_PeopleController() {
	}
	@RemoteAction
	public static List<UserItem> getPeoples() {
		List<UserItem> peoples = new List<UserItem>();
		if (!SObjectType.EntitySubscription.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.EntitySubscription);
		List<EntitySubscription> followings = [
			SELECT SubscriberId, ParentId, IsDeleted, Id, CreatedDate, CreatedById
			FROM EntitySubscription WHERE SubscriberId =:Userinfo.getUserId() AND IsDeleted = false
			LIMIT 1000
		];
		Set<Id> followingsIds = new Set<Id>();
		for (EntitySubscription subscription : followings) { 
			followingsIds.add(subscription.ParentId); 
		}
		
		List<User> uList = CommunityHelperWithoutSharing.getCommunityUsers(null, 50000, new List<String>{'FirstName', 'LastName', 'SmallPhotoUrl', 'FullPhotoUrl', 'ContactId', 'Contact.Primary_Role__c', 'Community_Contact_ID__c'}, 'Name', true);
		securityWrapper sw = new securityWrapper();
		Map<Id,String> contactRoles = sw.prepareRoles(uList);
		for (User uItem2 : uList) {
			Id cId2 = getId(uItem2);
			peoples.add(new UserItem(uItem2, followingsIds.contains(uItem2.Id), cId2 == NULL ? '' : contactRoles.get(cId2)));
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
				if (!SObjectType.Contact.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Contact);
				for (Contact cItem : [SELECT Id, Primary_Role__c FROM Contact WHERE Id IN :contactsToFindRole]) {
					resultRoles.put(cItem.Id, cItem.Primary_Role__c);
				}
			}
			return resultRoles;
		}
	}
}

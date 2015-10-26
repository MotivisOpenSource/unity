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

public with sharing class CommunityFollowController {

	public EntitySubscription subscription { get;set; }
	public Id subscriptionParentId {
		get;
		set {
			if (subscriptionParentId == NULL) {
				subscriptionParentId = value;
				String querySubscrParentId = String.escapeSingleQuotes(subscriptionParentId);
				List<EntitySubscription> subscriptionForEventList = [SELECT Id FROM EntitySubscription 
					WHERE ParentId = :querySubscrParentId
					AND SubscriberId = :UserInfo.getUserId() 
					LIMIT 1
				];
				subscription = (subscriptionForEventList.size() == 0) ? new EntitySubscription() : subscriptionForEventList[0];
			}
		}
	}

	public PageReference follow() {
		if (subscription.Id != NULL) {
			delete subscription;
			subscription = new EntitySubscription();
		}
		else {
			subscription.ParentId = this.subscriptionParentId;
			subscription.SubscriberId = UserInfo.getUserId();
			if (Network.getNetworkId() != NULL) {
				subscription.put('NetworkId', Network.getNetworkId());
			}
			insert subscription;
		}
		return NULL;
	}

	public Boolean followed {
		get {
			return subscription.Id != NULL;
		}
	}
}

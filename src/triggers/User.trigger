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

trigger User on User (before insert, after update) {

	if(trigger.isBefore && trigger.isInsert){

		List<String> contactIdList = new List<String>();
		Map<String, String> userContactMap = new Map<String, String>(); 

		for (User userItem : Trigger.New) {
			if (userItem.Community_Contact_ID__c != NULL) {
				contactIdList.add(userItem.Community_Contact_ID__c);
			}
		}

		if (!contactIdList.isEmpty()) {
			for( Contact con : [SELECT Id, Primary_Role__c FROM Contact WHERE Id IN :contactIdList]){
				userContactMap.put(con.id, con.Primary_Role__c);
			}
		}

		if(!userContactMap.isEmpty()){
			for (User userItem : Trigger.New) {
				userItem.CompanyName = userContactMap.get(userItem.Community_Contact_ID__c);
			}
		}

	}
	if (trigger.isAfter && trigger.isUpdate) {
		Set<Id> newActiveUsersIds =  new Set<Id>();
		for (User u : trigger.new) {
			if (u.isActive == true && trigger.oldMap.get(u.id).isActive == false) {
				newActiveUsersIds.add(u.Id);
			}
		}
		Set<Id> expectUsersIds =  new Set<Id>();
		for (NetworkMember nm : [SELECT Id, MemberId FROM NetworkMember WHERE MemberId IN :newActiveUsersIds]) {
			expectUsersIds.add(nm.MemberId);
		}
		Set<Id> collaborationMemberIds = CommunityUtils.checkGroupManagers(expectUsersIds);
		if (!collaborationMemberIds.isEmpty()) {
			CommunityUtils.changeManagerRoleToStandard(collaborationMemberIds);
		}

	}

}
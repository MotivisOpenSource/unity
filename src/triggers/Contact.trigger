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

trigger Contact on Contact (after insert, after update, before insert, before update) {

	if (Trigger.isBefore) {
		Map<String, String> contactRole = new Map<String, String>();
		for (Contact cItem : Trigger.new) {
			if (String.isBlank(cItem.Primary_Role__c) && cItem.Primary_Community_Profile__c != NULL) {
				cItem.Primary_Community_Profile__c = NULL;
			}
			if(Trigger.isUpdate && cItem.Primary_Role__c != Trigger.oldMap.get(cItem.Id).Primary_Role__c){
				contactRole.put(cItem.Id, cItem.Primary_Role__c);
			}
		}
		if(!contactRole.isEmpty()){
			List<User> users = [SELECT Id, CompanyName, ContactID, Community_Contact_ID__c FROM User WHERE Community_Contact_ID__c IN :contactRole.keySet()];
			for(User us : users){
				us.CompanyName = contactRole.get(us.Community_Contact_ID__c);
			}
			update users;
		}

	}

	if (Trigger.isAfter) {
		Map<Id,String> contactToRoleMap = new Map<Id,String>();
		for (Contact cItem : Trigger.new) {
			if (String.isNotBlank(cItem.Primary_Role__c)
				&& (Trigger.isInsert
					|| cItem.Primary_Role__c != Trigger.oldMap.get(cItem.Id).Primary_Role__c
					|| cItem.Primary_Community_Profile__c != Trigger.oldMap.get(cItem.Id).Primary_Community_Profile__c
					)
				) {
				contactToRoleMap.put(cItem.Id, cItem.Primary_Role__c);
			}
		}
		if (contactToRoleMap.size() > 0) {
			CommunityUtils.checkPrimaryProfile(contactToRoleMap);
		}
	}

}
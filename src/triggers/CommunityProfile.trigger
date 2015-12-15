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

trigger CommunityProfile on Community_Profile__c (before insert, before update, after insert, after update) {

	//List<Community_Profile__c> changedProfiles = new List<Community_Profile__c>();
	//Set<Id> recordTypeIds = new Set<Id>();
	//for (Community_Profile__c cpItem : Trigger.new) {
	//	if (cpItem.Primary__c == true
	//		&& (!Trigger.isUpdate || cpItem.Primary__c != Trigger.oldMap.get(cpItem.Id).Primary__c)
	//			) {
	//		recordTypeIds.add(cpItem.RecordTypeId);
	//		changedProfiles.add(cpItem);
	//	}
	//}

	//if (changedProfiles.size() > 0) {
	//	Map<Id,Schema.RecordTypeInfo> recordTypeIdToName = Schema.SObjectType.Community_Profile__c.getRecordTypeInfosById();
	//	Map<Id,String> contactToRoleMap = new Map<Id,String>();
	//	for (Community_Profile__c cpItem2 : changedProfiles) {
	//		contactToRoleMap.put(cpItem2.Contact__c, recordTypeIdToName.get(cpItem2.RecordTypeId).getName());
	//	}
	//	CommunityUtils.checkPrimaryProfile(contactToRoleMap);
	//}

	if (trigger.isBefore) {
		if (trigger.isInsert || trigger.isUpdate) {
			//Start Block: Only One Primary Community Profile Record
			Map<String, String> communityProfileMap = new Map<String, String>();
			Map<String, String> contactWithPrimaryMap = new Map<String, String>();
			List<Community_Profile__c> communityProfileList = new List<Community_Profile__c>();

			for (Community_Profile__c communityProfileItem : Trigger.New) {
				if (communityProfileItem.Primary__c == true) {
					communityProfileMap.put(communityProfileItem.Id, communityProfileItem.Contact__c);
				}
			}

			if (!communityProfileMap.isEmpty()) {
				communityProfileList = [
					SELECT Id, Primary__c, Contact__c
					FROM Community_Profile__c
					WHERE Contact__c IN :CommunityProfileMap.values()
				];
			}
			if (!communityProfileList.isEmpty()) {
				for (Community_Profile__c communityProfileItem : communityProfileList) {
					if (communityProfileItem.Primary__c == true) {
						contactWithPrimaryMap.put(communityProfileItem.Contact__c, communityProfileItem.Id);
					}
				}
			}
			if (!contactWithPrimaryMap.isEmpty()) {
				for (Community_Profile__c communityProfileItem : Trigger.New) {
					if (contactWithPrimaryMap.get(communityProfileItem.Contact__c) != NULL) {

						if (contactWithPrimaryMap.get(communityProfileItem.Contact__c) != communityProfileItem.Id) {
							communityProfileItem.Primary__c.addError(Label.ERR_Primary_Profile);
						}

					}
				}
			}
			//End Block: Only One Primary Community Profile Record

			//Start Block: Only One Community Profile per record type
			communityProfileMap = new Map<String, String>();
			communityProfileList = new List<Community_Profile__c>();
			Map<String, Set<String>> RecordTypeMap = new Map<String, Set<String>>();

			for (Community_Profile__c communityProfileItem : Trigger.New) {
				communityProfileMap.put(communityProfileItem.Id, communityProfileItem.Contact__c);
			}

			if (!CommunityProfileMap.isEmpty()) {
				communityProfileList = [
					SELECT Id, Contact__c, RecordTypeId
					FROM Community_Profile__c
					WHERE Contact__c IN :CommunityProfileMap.values()
				];
			}
			if (!communityProfileList.isEmpty()) {
				for (Community_Profile__c communityProfileItem : communityProfileList) {
					if (communityProfileMap.get(communityProfileItem.Id) == NULL) {

						if (RecordTypeMap.get(communityProfileItem.Contact__c) ==  NULL) {
							RecordTypeMap.put(
								communityProfileItem.Contact__c,
								new Set<String>{communityProfileItem.RecordTypeId}
							);
						}
						else {
							RecordTypeMap.get(communityProfileItem.Contact__c).add(communityProfileItem.RecordTypeId);
						}

					}
				}
			}
			if (!RecordTypeMap.isEmpty()) {
				for (Community_Profile__c communityProfileItem : Trigger.New) {
					if (RecordTypeMap.containsKey(communityProfileItem.Contact__c) && RecordTypeMap.get(communityProfileItem.Contact__c).contains(communityProfileItem.RecordTypeId)) {
						communityProfileItem.RecordTypeId.addError(Label.ERR_Profile_RecordType);
					}
				}
			}
			//End Block: Only One Community Profile per record type

			//Start Block: Update Contact.Primary_Community_Profile__c
			communityProfileMap = new Map<String, String>();
			communityProfileList = new List<Community_Profile__c>();
			contactWithPrimaryMap = new Map<String, String>();

			for (Community_Profile__c communityProfileItem : Trigger.New) {
				if (communityProfileItem.Primary__c == false) {
					communityProfileMap.put(communityProfileItem.Contact__c, communityProfileItem.Id);
				}
			}
			if (!communityProfileMap.isEmpty()) {
				communityProfileList = [
					SELECT Id, Primary__c, Contact__c
					FROM Community_Profile__c
					WHERE Contact__c IN :CommunityProfileMap.keySet()
				];
			}
			if (!communityProfileList.isEmpty()) {
				for (Community_Profile__c communityProfileItem : communityProfileList) {
					if (communityProfileItem.Primary__c == true) {
						contactWithPrimaryMap.put(communityProfileItem.Contact__c, communityProfileItem.Id);
					}
				}
			}

			for (Community_Profile__c communityProfileItem : Trigger.New) {
				if(
					contactWithPrimaryMap.get(communityProfileItem.Contact__c) == NULL &&
					communityProfileItem.Primary__c == false
				) {
					communityProfileItem.Primary__c = true;
				}
			}
			//End Block: Update Contact.Primary_Community_Profile__c
		}
	}

	if (trigger.isAfter) {
		if (trigger.isInsert || trigger.isUpdate) {
			//Start Block: Update Contact.Primary_Community_Profile__c
			Map<String, Community_Profile__c> communityProfileMap = new Map<String, Community_Profile__c>();
			List<Contact> contactUpdateList = new List<Contact>();
			List<Contact> contactList = new List<Contact>();
			List<RecordType> recordTypeList = new List<RecordType>();
			Map<String, String> recordTypeMap = new Map<String, String>();

			for (Community_Profile__c communityProfileItem : Trigger.New) {
				if (communityProfileItem.Primary__c == true) {
					communityProfileMap.put(communityProfileItem.Contact__c, communityProfileItem);
				}

			}
			if (!communityProfileMap.isEmpty()) {
				recordTypeList = [
					SELECT Id, SobjectType, Name
					FROM RecordType
					WHERE SobjectType = :Community_Profile__c.SObjectType.getDescribe().getName()
				];

				contactList = [
					SELECT Id, Primary_Community_Profile__c, Primary_Role__c
					FROM Contact
					WHERE Id IN :communityProfileMap.keySet()
				];
			}

			if (!recordTypeList.isEmpty()) {
				for (RecordType recordTypeItem : recordTypeList) {
					recordTypeMap.put(recordTypeItem.Id, recordTypeItem.Name);
				}
			}

			if (!contactList.isEmpty()) {
				for (Contact contactItem : contactList) {
					if (
						communityProfileMap.get(contactItem.Id) != NULL &&
						(contactItem.Primary_Community_Profile__c == NULL ||
							(contactItem.Primary_Community_Profile__c != communityProfileMap.get(contactItem.Id).Id)
						)
					) {
						contactItem.Primary_Community_Profile__c = communityProfileMap.get(contactItem.Id).Id;
						if (recordTypeMap.get(communityProfileMap.get(contactItem.Id).RecordTypeId) != NULL) {
							contactItem.Primary_Role__c =
								recordTypeMap.get(communityProfileMap.get(contactItem.Id).RecordTypeId);
						}
						contactUpdateList.add(contactItem);
					}
				}
			}

			if (!contactUpdateList.isEmpty()) {
				update contactUpdateList;
			}
			//End Block: Update Contact.Primary_Community_Profile__c
		}
	}

}
trigger Contact on Contact (after insert, after update) {

	if (trigger.isAfter) {

		if (trigger.isUpdate) {
			//Start Block: Create Primary Community Profile if there is not one
			Map<String, String> ContactMap = new Map<String, String>();
			List<Community_Profile__c> communityProfileList = new List<Community_Profile__c>();
			List<RecordType> recordTypeList = new List<RecordType>();
			Map<String, String> recordTypeMap = new Map<String, String>();
			Map<String, Map<String, Community_Profile__c>> communityProfileMap =
				new Map<String, Map<String, Community_Profile__c>>();
			List<Community_Profile__c> communityProfileInsertList = new List<Community_Profile__c>();
			List<String> contactUpdateList = new List<String>();
			List<Community_Profile__c> communityProfileUpdatePrimaryFalseList = new List<Community_Profile__c>();
			List<Community_Profile__c> communityProfileUpdatePrimaryTrueList = new List<Community_Profile__c>();

			for (Contact ContactItem : Trigger.New) {
				ContactMap.put(ContactItem.Id ,ContactItem.Primary_Role__c);
			}

			if (!ContactMap.isEmpty()) {
				recordTypeList = [
					SELECT Id, SobjectType, Name
					FROM RecordType
					WHERE SobjectType = :Community_Profile__c.SObjectType.getDescribe().getName()
				];

				communityProfileList = [
					SELECT Id, Primary__c, Contact__c, RecordTypeId
					FROM Community_Profile__c
					WHERE Contact__c IN :ContactMap.keySet()
				];
			}

			if (!recordTypeList.isEmpty()) {
				for (RecordType recordTypeItem : recordTypeList) {
					recordTypeMap.put(recordTypeItem.Name, recordTypeItem.Id);
				}
			}

			if (!communityProfileList.isEmpty()) {
				for (Community_Profile__c communityProfileItem : communityProfileList) {
					if (communityProfileMap.get(communityProfileItem.Contact__c) == NULL) {
						communityProfileMap.put(
							communityProfileItem.Contact__c,
							new Map<String, Community_Profile__c>{
								communityProfileItem.RecordTypeId => communityProfileItem
							}
						);
					}
					else {
						communityProfileMap.get(communityProfileItem.Contact__c).put(
							communityProfileItem.RecordTypeId,
							communityProfileItem
						);
					}
				}
			}

			for (Contact ContactItem : Trigger.New) {
				if (
					communityProfileMap.get(ContactItem.Id) == NULL &&
					recordTypeMap.get(ContactItem.Primary_Role__c) != NULL &&
					ContactItem.Primary_Role__c != NULL
				) {
					Community_Profile__c communityProfileNew = new Community_Profile__c();
					communityProfileNew.RecordTypeId = recordTypeMap.get(ContactItem.Primary_Role__c);
					communityProfileNew.Contact__c = ContactItem.Id;
					communityProfileNew.Primary__c = true;

					communityProfileInsertList.add(communityProfileNew);
				}
				else if(
					communityProfileMap.get(ContactItem.Id) != NULL &&
					recordTypeMap.get(ContactItem.Primary_Role__c) != NULL &&
					communityProfileMap.get(ContactItem.Id).get(recordTypeMap.get(ContactItem.Primary_Role__c)) == NULL &&
					ContactItem.Primary_Role__c != NULL
				) {
					Community_Profile__c communityProfileNew = new Community_Profile__c();
					communityProfileNew.RecordTypeId = recordTypeMap.get(ContactItem.Primary_Role__c);
					communityProfileNew.Contact__c = ContactItem.Id;
					communityProfileNew.Primary__c = true;

					communityProfileInsertList.add(communityProfileNew);
					communityProfileUpdatePrimaryFalseList.addAll(communityProfileMap.get(ContactItem.Id).values());
				}
				else if(
					communityProfileMap.get(ContactItem.Id) != NULL &&
					recordTypeMap.get(ContactItem.Primary_Role__c) != NULL &&
					communityProfileMap.get(ContactItem.Id).get(recordTypeMap.get(ContactItem.Primary_Role__c)) == NULL
				) {
					//do nothing
				}
				else if(
					ContactItem.Primary_Role__c != NULL &&
					ContactItem.Primary_Role__c != Trigger.OldMap.get(ContactItem.Id).Primary_Role__c &&
					recordTypeMap.get(ContactItem.Primary_Role__c) != NULL &&
					communityProfileMap.get(ContactItem.Id).get(recordTypeMap.get(ContactItem.Primary_Role__c)) != NULL &&
					communityProfileMap.get(ContactItem.Id).get(recordTypeMap.get(ContactItem.Primary_Role__c)).Primary__c == false
				) {
					communityProfileUpdatePrimaryFalseList.addAll(communityProfileMap.get(ContactItem.Id).values());
					communityProfileUpdatePrimaryTrueList.add(
						communityProfileMap.get(ContactItem.Id).get(recordTypeMap.get(ContactItem.Primary_Role__c))
					);
				}
			}

			if (!communityProfileUpdatePrimaryFalseList.isEmpty()) {
				for (Community_Profile__c communityProfileItem : communityProfileUpdatePrimaryFalseList) {
					communityProfileItem.Primary__c = false;
				}
				update communityProfileUpdatePrimaryFalseList;
			}

			if (!communityProfileUpdatePrimaryTrueList.isEmpty()) {
				for (Community_Profile__c communityProfileItem : communityProfileUpdatePrimaryTrueList) {
					communityProfileItem.Primary__c = true;
				}
				update communityProfileUpdatePrimaryTrueList;
			}

			if (!communityProfileInsertList.isEmpty()) {
				insert communityProfileInsertList;

			}
			//End Block: Create Primary Community Profile if there is not one
		}

	}

	if (trigger.isAfter) {
		if (trigger.isInsert) {
			//Start Block: Create Primary Community Profile if there is not one
			List<Contact> contactList = new List<Contact>();
			List<String> contactIdList = new List<String>();

			for (Contact ContactItem : Trigger.New) {
				if (ContactItem.Primary_Role__c != NULL) {
					contactIdList.add(ContactItem.Id);
				}
			}
			if (!contactIdList.isEmpty()) {
				contactList = [
					SELECT Id, Primary_Community_Profile__c, Primary_Role__c
					FROM Contact
					WHERE Id IN :contactIdList
				];
			}

			if (!contactList.isEmpty()) {
				update contactList;
			}
			//End Block: Create Primary Community Profile if there is not one
		}
	}

}
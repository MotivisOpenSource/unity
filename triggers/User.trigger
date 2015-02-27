trigger User on User (before insert) {

	if (trigger.isBefore) {
		if (trigger.isInsert) {
			//Start Block: Enable Portal User Requires Community Profile for the Contact.
			List<User> userList = new List<User>();
			List<String> contactIdList = new List<String>();
			List<Contact> contactList = new List<Contact>();
			Map<String, String> contactPrimaryCommunity = new Map<String, String>();
			List<Community_Profile__c> communityProfileList = new List<Community_Profile__c>();
			Map<String, Set<String>> communityProfileMap = new Map<String, Set<String>>();

			for (User userItem : Trigger.New) {
				if (userItem.ContactId != NULL ) {
					contactIdList.add(userItem.ContactId);
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
				for (Contact contactItem : contactList) {
					contactPrimaryCommunity.put(contactItem.Id, contactItem.Primary_Community_Profile__c);
				}

				communityProfileList = [
					SELECT Id, Contact__c, RecordTypeId
					FROM Community_Profile__c
					WHERE Contact__c IN :contactList
				];
			}

			if (!communityProfileList.isEmpty()) {
				for (Community_Profile__c communityProfileItem : communityProfileList) {
					if (communityProfileMap.get(communityProfileItem.Contact__c) == NULL) {
						communityProfileMap.put(
							communityProfileItem.Contact__c,
							new Set<String>{communityProfileItem.Id}
						);
					}
					else {
						communityProfileMap.get(communityProfileItem.Contact__c).add(communityProfileItem.Id);
					}
				}
			}

			for (User userItem : Trigger.New) {
				if (userItem.ContactId != NULL ) {
					if (contactPrimaryCommunity.get(userItem.ContactId) == NULL ) {
						userItem.addError(Label.ERR_Community_Profile);
					}
					else if (communityProfileMap.get(userItem.ContactId) == NULL) {
						userItem.addError(Label.ERR_Community_Profile);
					}
					else if (!communityProfileMap.get(userItem.ContactId)
							.contains(contactPrimaryCommunity.get(userItem.ContactId))) {
						userItem.addError(Label.ERR_Community_Profile);
					}
				}
			}

			//End Block: Enable Portal User Requires Community Profile for the Contact.
		}
	}

}
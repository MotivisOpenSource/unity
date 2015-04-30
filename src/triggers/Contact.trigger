trigger Contact on Contact (after insert, after update, before insert, before update) {

	if (Trigger.isBefore) {
		for (Contact cItem : Trigger.new) {
			if (String.isBlank(cItem.Primary_Role__c) && cItem.Primary_Community_Profile__c != NULL) {
				cItem.Primary_Community_Profile__c = NULL;
			}
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
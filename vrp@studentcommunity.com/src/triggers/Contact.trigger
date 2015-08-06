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
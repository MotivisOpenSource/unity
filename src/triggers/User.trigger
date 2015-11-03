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
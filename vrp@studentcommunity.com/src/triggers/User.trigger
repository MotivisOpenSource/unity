trigger User on User (before insert) {

	if(trigger.isBefore){

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

}
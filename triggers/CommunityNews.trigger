trigger CommunityNews on Community_News__c (before insert, before update) {

	List<Community_News__c> newsList = new List<Community_News__c>();
	Map<String, Map<String, DateTime>> userIdMap = new Map<String, Map<String, DateTime>>();
	Map<String, Map<String, DateTime>> userIdMapNew = new Map<String, Map<String, DateTime>>();
	Map<String, Community_News__c> userAndSobjectMap = new Map<String, Community_News__c>();

	for (Community_News__c item : trigger.new) {

		Map<String, DateTime> slotMap = new Map<String, DateTime>();

		if (item.Feature_on_Home_Page_Slot__c != NULL && item.Expiration_Date__c != NULL && item.OwnerId != NULL) {
			slotMap.put(item.Feature_on_Home_Page_Slot__c, item.Expiration_Date__c);
			userIdMap.put(item.OwnerId, slotMap);
		}

	}

	if (!userIdMap.isEmpty()) {
		newsList = [
			SELECT Id, Name, Feature_on_Home_Page_Slot__c, Entry_Date__c, Expiration_Date__c, OwnerId
			FROM Community_News__c
			WHERE OwnerId IN: userIdMap.keySet()
			AND Feature_on_Home_Page_Slot__c != NULL
			ORDER BY Expiration_Date__c ASC
			LIMIT 50000
		];
	}

	if (!newsList.isEmpty()) {
		for (Community_News__c item : newsList) {

			Map<String, DateTime> slotMap = new Map<String, DateTime>();

			if (item.Feature_on_Home_Page_Slot__c != NULL && item.Expiration_Date__c != NULL && item.OwnerId != NULL) {
				if (userIdMap.get(item.OwnerId) != NULL
					&& userIdMap.get(item.OwnerId).get(item.Feature_on_Home_Page_Slot__c) != NULL
				) {
					slotMap.put(item.Feature_on_Home_Page_Slot__c, item.Expiration_Date__c);
					userIdMapNew.put(item.OwnerId, slotMap);
					userAndSobjectMap.put(item.OwnerId, item);
				}
			}

		}

		for (Community_News__c item : trigger.new) {

			if (userIdMapNew.get(item.OwnerId) != NULL) {
				if (userIdMapNew.get(item.OwnerId).get(item.Feature_on_Home_Page_Slot__c) != NULL) {
					if (item.Entry_Date__c <= userIdMapNew.get(item.OwnerId).get(item.Feature_on_Home_Page_Slot__c)) {
						if (userAndSobjectMap.get(item.OwnerId).Id == NULL) {
							item.addError(Label.ERR_3_Alerts);
						}
						else if (userAndSobjectMap.get(item.OwnerId).Id != item.Id) {
							item.addError(Label.ERR_3_Alerts);
						}
					}
				}
			}

		}
	}

}
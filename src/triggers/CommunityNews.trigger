trigger CommunityNews on Community_News__c (before insert, before update) {

	List<Community_News__c> newsList = new List<Community_News__c>();
	Map<String, Map<String, DateTime>> userIdMap = new Map<String, Map<String, DateTime>>();
	Map<String, Map<String, DateTime>> userIdMapNew = new Map<String, Map<String, DateTime>>();
	Map<String, Community_News__c> userAndSobjectMap = new Map<String, Community_News__c>();
	List<Community_News__c> newsBreakingList = new List<Community_News__c>();
	Map<Id, Community_News__c> breakingNewsErrorMap = new Map<Id, Community_News__c>();

	for (Community_News__c item : trigger.new) {

		Map<String, DateTime> slotMap = new Map<String, DateTime>();

		if (item.Feature_on_Home_Page_Slot__c != NULL && item.Expiration_Date__c != NULL && item.OwnerId != NULL) {
			slotMap.put(item.Feature_on_Home_Page_Slot__c, item.Expiration_Date__c);
			userIdMap.put(item.OwnerId, slotMap);
		}

		if (item.Alert__c == true) {
			newsBreakingList.add(item);
		}

	}

	if (!newsBreakingList.isEmpty()) {

		List<Community_News__c> breakingNewsLastList = new List<Community_News__c>();

		breakingNewsLastList = [
			SELECT Id, Name, Expiration_Date__c, Entry_Date__c, OwnerId, Alert__c
			FROM Community_News__c
			WHERE Alert__c = true
			ORDER BY Expiration_Date__c DESC
			LIMIT 45000
		];

		if (breakingNewsLastList.isEmpty()) {
			breakingNewsLastList.add(newsBreakingList[0]);
			newsBreakingList.remove(0);
		}

		for (Community_News__c item : newsBreakingList) {

			Boolean isCorrect = true;
			for (Community_News__c item2 : breakingNewsLastList) {
				isCorrect = (
					(item2.Entry_Date__c < item.Entry_Date__c && item2.Expiration_Date__c < item.Expiration_Date__c && item2.Expiration_Date__c > item.Entry_Date__c)
					|| (item2.Entry_Date__c > item.Entry_Date__c && item2.Expiration_Date__c > item.Expiration_Date__c && item2.Entry_Date__c < item.Expiration_Date__c)
					|| (item2.Entry_Date__c < item.Entry_Date__c && item2.Expiration_Date__c > item.Expiration_Date__c)
					|| (item2.Entry_Date__c > item.Entry_Date__c && item2.Expiration_Date__c < item.Expiration_Date__c)
						) ? false : isCorrect;
			}

			if (isCorrect == true) {
				breakingNewsLastList.add(item);
			}
			else {
				breakingNewsErrorMap.put(item.Id, item);
			}

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

			if (breakingNewsErrorMap.get(item.Id) != NULL) {
				item.addError(Label.ERR_1_Breaking_News);
			}

		}
	}

	if (!breakingNewsErrorMap.isEmpty()) {
		for (Community_News__c item : trigger.new) {
			if (breakingNewsErrorMap.get(item.Id) != NULL) {
				item.addError(Label.ERR_1_Breaking_News);
			}
		}
	}

}
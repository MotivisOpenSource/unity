trigger CommunityNews on Community_News__c (before insert, before update) {

	Boolean validated = true;
	Community_News__c alertNews;
	Map<String,Community_News__c> slotMap = new Map<String,Community_News__c>();

	for (Community_News__c cnItem : Trigger.new) {
		if (cnItem.Alert__c == true
			&& (Trigger.isInsert || cnItem.Alert__c != Trigger.oldMap.get(cnItem.Id).Alert__c)
				) {
			if (alertNews != NULL) {
				validated = false;
				cnItem.addError(Label.ERR_1_Breaking_News);
			}
			else {
				alertNews = cnItem;
			}
		}

		if (String.isNotBlank(cnItem.Feature_on_Home_Page_Slot__c)
			&& (Trigger.isInsert || cnItem.Feature_on_Home_Page_Slot__c != Trigger.oldMap.get(cnItem.Id).Feature_on_Home_Page_Slot__c)
				) {
			if (slotMap.containsKey(cnItem.Feature_on_Home_Page_Slot__c)) {
				validated = false;
				cnItem.addError(Label.ERR_3_Alerts);
			}
			else {
				slotMap.put(cnItem.Feature_on_Home_Page_Slot__c, cnItem);
			}
		}
	}

	if (validated && alertNews != NULL) {
		if (CommunityUtils.checkNewsOverlapInterval('Alert__c = true', alertNews.Entry_Date__c, alertNews.Expiration_Date__c)) {
			alertNews.addError(Label.ERR_1_Breaking_News);
		}
	}

	if (validated && slotMap.size() > 0) {
		if (slotMap.containsKey('1')) {
			Community_News__c slotNews = slotMap.get('1');
			if (CommunityUtils.checkNewsOverlapInterval('Feature_on_Home_Page_Slot__c = \'1\'', slotNews.Entry_Date__c, slotNews.Expiration_Date__c)) {
				slotNews.addError(Label.ERR_3_Alerts);
			}
		}
		if (slotMap.containsKey('2')) {
			Community_News__c slotNews = slotMap.get('2');
			if (CommunityUtils.checkNewsOverlapInterval('Feature_on_Home_Page_Slot__c = \'2\'', slotNews.Entry_Date__c, slotNews.Expiration_Date__c)) {
				slotNews.addError(Label.ERR_3_Alerts);
			}
		}
		if (slotMap.containsKey('3')) {
			Community_News__c slotNews = slotMap.get('3');
			if (CommunityUtils.checkNewsOverlapInterval('Feature_on_Home_Page_Slot__c = \'3\'', slotNews.Entry_Date__c, slotNews.Expiration_Date__c)) {
				slotNews.addError(Label.ERR_3_Alerts);
			}
		}
	}
}
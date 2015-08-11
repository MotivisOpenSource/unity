trigger CommunityResource on Community_Resource__c (after undelete, before insert, before update) {

	Boolean checkForDuplicate = false;
	Boolean duplicated = false;

	for (Community_Resource__c crItem : Trigger.new) {
		if (crItem.Quick_Link__c != true && crItem.Help_Link__c != true && String.isBlank(crItem.Primary_Tag__c)) {
			crItem.Primary_Tag__c.addError(Label.ERR_Please_Enter_Value);
		}

		if (crItem.Quick_Link__c == true
			&& (String.isBlank(crItem.Name) || crItem.Name.length() > 20)
			&& (!Trigger.isUpdate || crItem.Quick_Link__c != Trigger.oldMap.get(crItem.Id).Quick_Link__c)
			) {
			crItem.Name.addError(Label.LBL_ERR_Quick_Link);
		}

		if (crItem.Help_Link__c == true && crItem.Status__c == 'Active'
			&& (!Trigger.isUpdate
				|| crItem.Help_Link__c != Trigger.oldMap.get(crItem.Id).Help_Link__c
				|| crItem.Status__c != Trigger.oldMap.get(crItem.Id).Status__c)
			) {
			duplicated = checkForDuplicate;
			checkForDuplicate = true;
		}
	}

	if (checkForDuplicate && !duplicated) {
		List<Community_Resource__c> crForCheck = [SELECT Id FROM Community_Resource__c WHERE Status__c = 'Active' AND Help_Link__c = true];
		duplicated = crForCheck.size() > 0;
	}

	if (duplicated) {
		for (Community_Resource__c crItem2 : Trigger.new) {
			if (crItem2.Help_Link__c == true) {
				if (!Trigger.isUpdate || crItem2.Help_Link__c != Trigger.oldMap.get(crItem2.Id).Help_Link__c) {
					crItem2.Help_Link__c.addError(Label.LBL_ERR_Help_Link);
				}
				else if (Trigger.isUpdate && crItem2.Status__c != Trigger.oldMap.get(crItem2.Id).Status__c) {
					crItem2.Status__c.addError(Label.LBL_ERR_Help_Link);
				}
			}
		}
	}
}
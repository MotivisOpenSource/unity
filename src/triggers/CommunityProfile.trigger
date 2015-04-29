trigger CommunityProfile on Community_Profile__c (after insert, after update, after undelete) {

	List<Community_Profile__c> changedProfiles = new List<Community_Profile__c>();
	Set<Id> recordTypeIds = new Set<Id>();
	for (Community_Profile__c cpItem : Trigger.new) {
		if (cpItem.Primary__c == true
			&& (!Trigger.isUpdate || cpItem.Primary__c != Trigger.oldMap.get(cpItem.Id).Primary__c)
				) {
			recordTypeIds.add(cpItem.RecordTypeId);
			changedProfiles.add(cpItem);
		}
	}

	if (changedProfiles.size() > 0) {
		Map<Id,Schema.RecordTypeInfo> recordTypeIdToName = Schema.SObjectType.Community_Profile__c.getRecordTypeInfosById();
		Map<Id,String> contactToRoleMap = new Map<Id,String>();
		for (Community_Profile__c cpItem2 : changedProfiles) {
			contactToRoleMap.put(cpItem2.Contact__c, recordTypeIdToName.get(cpItem2.RecordTypeId).getName());
		}
		CommunityUtils.checkPrimaryProfile(contactToRoleMap);
	}

}
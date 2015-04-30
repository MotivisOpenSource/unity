trigger CommunityAdmin on Community_Admins__c (before insert, before update, after undelete) {

	Id CommunityTermsRTid = Schema.SObjectType.Community_Admins__c.getRecordTypeInfosByName().get('Community Terms').getRecordTypeId();


	if(Trigger.isBefore){
		
		List<Community_Registration__c> regSelects = new List<Community_Registration__c>();
		Set<Id> newAdminIds = new Set<Id>();
		List<Id> newAdmins = new List<Id>();
		
		for (Community_Admins__c ca : Trigger.new) {
			
			if (ca.Terms_Status__c == 'Published' && ca.RecordTypeId == CommunityTermsRTid) {
				newAdmins.add(ca.Id);
				if(newAdmins.size() > 1){
					Trigger.new[0].Terms_Status__c.addError('Duplicate Term Status "Published"');
				}

				ca.Terms_Published_Date__c = datetime.now();
				if (ca.Terms_Req_New_Signature__c == TRUE) {
					Community_Registration__c regSelect = Community_Registration__c.getOrgDefaults();
					regSelect.T_C_Published_Current_Date__c = datetime.now();
					regSelects.add(regSelect);				
				}
				if (Trigger.oldMap == null || Trigger.oldMap.get(ca.Id).Terms_Status__c != ca.Terms_Status__c) {
					newAdminIds.add(ca.id);
				}
			}
		}

		if(!regSelects.isEmpty()){
			upsert regSelects;
		}
		
		if(!newAdminIds.isEmpty()){
			
			List<Community_Admins__c> publishedListToArchive = [ SELECT Id, Terms_Status__c, Terms_Archived_Date__c
																FROM Community_Admins__c
																WHERE Terms_Status__c = 'Published'
																	AND RecordType.Name = 'Community Terms'
																 	AND Id != :newAdminIds];

			if (!publishedListToArchive.isEmpty()) {
				for (Community_Admins__c ca2 : publishedListToArchive) {
					ca2.Terms_Status__c = 'Archived';
					ca2.Terms_Archived_Date__c = Datetime.now();
				}

				update publishedListToArchive;
			}
		}



	}
	if(Trigger.isAfter){
		
		Set<Id> CommunityAdminsIds = new Set<Id>();

		for (Community_Admins__c ca : Trigger.new){
			CommunityAdminsIds.add(ca.Id);
		}
		if(!CommunityAdminsIds.isEmpty()){
			List<Community_Admins__c> undeleteListAdmins = [SELECT Id, Terms_Status__c, Terms_Archived_Date__c
																FROM Community_Admins__c
																WHERE RecordType.Name = 'Community Terms'
																 	AND Id IN :CommunityAdminsIds];
			
			for(Community_Admins__c newCommAdmin : undeleteListAdmins){
				newCommAdmin.Terms_Status__c = 'Archived';
			}
			update undeleteListAdmins;
		}
	}
}
trigger CommunityGroupControl on Community_Group_Control__c (before insert, after insert) {

	if (Trigger.isBefore) {
		Boolean validationPassed = true;
		Map<Id, CollaborationGroup> newChatterGroupsByGCid = new Map<Id, CollaborationGroup>();
		Map<String, Community_Group_Control__c> checkUniqueNamesMap = new Map<String, Community_Group_Control__c>();
		Map<String, Id> communityIdByName = new Map<String, Id>();
		Boolean firstCommunity = true;
		for (Network nItem : [SELECT Id, Name FROM Network]) {
			communityIdByName.put(nItem.Name, nItem.Id);
			if (firstCommunity) {
				communityIdByName.put('Community', nItem.Id);
				firstCommunity = false;
			}
		}
		for (Community_Group_Control__c cgcItem : Trigger.new) {
			// Validation block
			if (checkUniqueNamesMap.containsKey(cgcItem.Name)) {
				cgcItem.addError(Label.ERR_Dup_Group_Name);
				validationPassed = false;
			}
			else {
				checkUniqueNamesMap.put(cgcItem.Name, cgcItem);
			}
			// Operation block
			if (validationPassed && cgcItem.Chatter_Group_ID__c == NULL) {
				newChatterGroupsByGCid.put(cgcItem.Id, new CollaborationGroup(
					CollaborationType = cgcItem.Type__c,
					Description = cgcItem.Description__c,
					IsArchived = false,
					Name = cgcItem.Name,
					NetworkId = Network.getNetworkId()
				));
			}
		}
		// Check for duplicated Group Name
		if (validationPassed) {
			for (Community_Group_Control__c cgcItem2 : [SELECT Name FROM Community_Group_Control__c WHERE Name IN :checkUniqueNamesMap.keySet()]) {
				checkUniqueNamesMap.get(cgcItem2.Name).addError(Label.ERR_Dup_Group_Name);
				validationPassed = false;
			}
		}
		// Create CollaborationGroup and populate Chatter_Group_ID__c field
		if (validationPassed && newChatterGroupsByGCid.size() > 0) {
			insert newChatterGroupsByGCid.values();
			for (Community_Group_Control__c cgcItem3 : Trigger.new) {
				if (cgcItem3.Chatter_Group_ID__c == NULL ) {
					cgcItem3.Chatter_Group_ID__c = newChatterGroupsByGCid.get(cgcItem3.Id).Id;
				}
			}
		}
	}

	if (Trigger.isAfter) {
		Map<Id, Id> GroupControlIdByChatterGroupId = new Map<Id, Id>();
		for (Community_Group_Control__c cgcItem : Trigger.new) {
			if (cgcItem.Chatter_Group_ID__c != NULL) {
				GroupControlIdByChatterGroupId.put(Id.valueOf(cgcItem.Chatter_Group_ID__c), cgcItem.Id);
			}
		}
		if (GroupControlIdByChatterGroupId.size() > 0) {
			List<Community_Group_Manager__c> membersCommunityGroup = new List<Community_Group_Manager__c>();
			for (CollaborationGroupMember cgmItem : [
						SELECT MemberId, CollaborationGroupId
						FROM CollaborationGroupMember
						WHERE CollaborationGroupId IN :GroupControlIdByChatterGroupId.keySet()]
							) {
				membersCommunityGroup.add(
					new Community_Group_Manager__c(
						Group_Control__c = GroupControlIdByChatterGroupId.get(cgmItem.CollaborationGroupId),
						Group_Manager_User__c = cgmItem.MemberId
					)
				);
			}
			if (membersCommunityGroup.size() > 0) {
				insert membersCommunityGroup;
			}
		}
	}
}
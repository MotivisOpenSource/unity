trigger NetworkMember on NetworkMember (after insert) {

	if (trigger.isAfter && trigger.isInsert) {
		Set<Id> membersIds = new Set<Id>();
		for (NetworkMember nm : trigger.new) {
			membersIds.add(nm.MemberId);
		}
		Set<Id> collaborationMemberIds = CommunityUtils.checkGroupManagers(membersIds);
		if (!collaborationMemberIds.isEmpty()) {
			CommunityUtils.changeManagerRoleToStandard(collaborationMemberIds);
		}
	}

}
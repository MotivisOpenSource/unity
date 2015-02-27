public with sharing class CommunityDiscoverController extends CommunityGroupsBase {

	public List<CommunityThemeCategory> Themes { get; set; }
	public Community_Tag__c CurrentTag { get; set; }
	public List<String> EventsFieldsSet { get; set; }
	public List<String> GroupsFieldsSet { get; set; }
	public List<String> NewsFieldsSet { get; set; }
	public List<String> ResourcesFieldsSet { get; set; }

	public Boolean IsEventsRendered { get; set; }
	public Boolean IsGroupsRendered { get; set; }
	public Boolean IsNewsRendered { get; set; }
	public Boolean IsResourcesRendered { get; set; }

	public CommunityDiscoverController() {
		
		String tagId = ApexPages.currentPage().getParameters().get('t');
		if (String.isBlank(tagId)) {
			this.Themes = new List<CommunityThemeCategory>();

			List<Community_Tag__c> allTags = [
				SELECT Id, Community_Theme__c, Community_Theme__r.Name, Name, Icon_Style__c,
				(SELECT Id, Name FROM Events_Tag_Joins__r), 
				(SELECT Id, Name FROM Community_Tag_Group_Control__r), 
				(SELECT Id, Name FROM Community_Tag_News__r WHERE Community_News__r.Entry_Date__c >= TODAY AND Community_News__r.Expiration_Date__c <= TODAY), 
				(SELECT Id, Name FROM Resource_Tag_Joins__r) 
				FROM Community_Tag__c
			];
			Map<Id, List<Community_Tag__c>> themeTagsMap = new Map<Id, List<Community_Tag__c>>();
			for (Community_Tag__c tag : allTags) {
				Boolean eventsNotEmpty = !tag.Events_Tag_Joins__r.isEmpty();
				Boolean groupControlNotEmpty = !tag.Community_Tag_Group_Control__r.isEmpty();
				Boolean newsNotEmpty = !tag.Community_Tag_News__r.isEmpty();
				Boolean resourcesNotEmpty = !tag.Resource_Tag_Joins__r.isEmpty();
				if (eventsNotEmpty || groupControlNotEmpty || newsNotEmpty || resourcesNotEmpty) {

					List<Community_Tag__c> tags = themeTagsMap.containsKey(tag.Community_Theme__c) ? themeTagsMap.get(tag.Community_Theme__c) : new List<Community_Tag__c>();
					tags.add(tag);

					themeTagsMap.put(tag.Community_Theme__c, tags);
				}
			}
			List<Community_Theme__c> allThemes = [
				SELECT Id, Name
				FROM Community_Theme__c
				//WHERE Enable_in_Wizard__c = TRUE
				LIMIT 100
			];
			for (Community_Theme__c theme : allThemes) {
				if (themeTagsMap.containsKey(theme.Id)) {
					List<Community_Tag__c> tags = themeTagsMap.get(theme.Id);
					if (tags.size() > 0 ) {
						this.Themes.add(new CommunityThemeCategory(theme, tags));

					}
				}
			}

		} else {
			this.IsEventsRendered = false;
			this.IsGroupsRendered = false;
			this.IsNewsRendered = false;
			this.IsResourcesRendered = false;

			this.EventsFieldsSet = new List<String> { 'Name__c', 'Teaser__c', 'Start__c' }; //getFieldSet('EditEvent', Community_Events__c.sObjectType);
			this.GroupsFieldsSet = new List<String> { 'Name', 'Description__c', 'Image_Path__c' }; //getFieldSet('CreateGroup', Community_Group_Control__c.sObjectType);
			this.NewsFieldsSet = new List<String> { 'Title__c', 'Teaser__c', 'Entry_Date__c', 'Image_Path__c' }; //getFieldSet('ViewNews', Community_News__c.sObjectType);
			this.ResourcesFieldsSet = new List<String> { 'Name' }; //getFieldSet('CreateGroup', Community_Resource__c.sObjectType);

			if (this.EventsFieldsSet.isEmpty()) {
				this.EventsFieldsSet.add('Name');
			}
			if (this.GroupsFieldsSet.isEmpty()) {
				this.GroupsFieldsSet.add('Name');
			}
			if (this.NewsFieldsSet.isEmpty()) {
				this.NewsFieldsSet.add('Name');
			}
			if (this.ResourcesFieldsSet.isEmpty()) {
				this.ResourcesFieldsSet.add('Name');
			}

			String query = 'SELECT Id, Community_Theme__c, Community_Theme__r.Name, Name, ';
			query += String.format('(SELECT Id, {0} FROM Events_Tag_Joins__r), ', new List<String> { formatFieldSet(this.EventsFieldsSet, 'Community_Event__r')});
			query += String.format('(SELECT Id, {0} FROM Community_Tag_Group_Control__r), ', new List<String> { formatFieldSet(this.GroupsFieldsSet, 'Group_Control__r') });
			query += String.format('(SELECT Id, {0} FROM Community_Tag_News__r WHERE Community_News__r.Entry_Date__c >= TODAY AND Community_News__r.Expiration_Date__c >= TODAY), ', new List<String> { formatFieldSet(this.NewsFieldsSet, 'Community_News__r') });
			query += String.format('(SELECT Id, {0} FROM Resource_Tag_Joins__r) ', new List<String> { formatFieldSet(this.ResourcesFieldsSet, 'Resource__r') });
			query += 'FROM Community_Tag__c WHERE Id =: tagId ';
			system.debug(query);
			List<Community_Tag__c> allTags = Database.query(query);

			if (!allTags.isEmpty()) {
				this.CurrentTag = allTags.get(0);
				if (this.CurrentTag != NULL) {
					this.IsEventsRendered = !this.CurrentTag.Events_Tag_Joins__r.isEmpty();
					this.IsGroupsRendered = !this.CurrentTag.Community_Tag_Group_Control__r.isEmpty();
					this.IsNewsRendered = !this.CurrentTag.Community_Tag_News__r.isEmpty();
					this.IsResourcesRendered = !this.CurrentTag.Resource_Tag_Joins__r.isEmpty();
				}
			}
		}
	}

	public static List<List<Community_Tag__c>> chunkList(List<Community_Tag__c> oldArray, Integer chunkSize) {
		List<List<Community_Tag__c>> newArray = new List<List<Community_Tag__c>>();
		Integer arraySize = oldArray.size();

		for (Integer i=0; i < arraySize; i += chunkSize) {
			List<Community_Tag__c> innerArray = new List<Community_Tag__c>();
			for (Integer j = 0; j < chunkSize; j++) {
				Integer sliceValue = i+j;
				if (arraySize > sliceValue) {
					innerArray.add(oldArray[i+j]);
				}
			}

			newArray.add(innerArray);
		}
		system.debug(newArray);
        return newArray;
	}

	private static String formatFieldSet(List<String> fieldSet, String relationshipName) {
		String result = '';
		List<String> fieldSetCopy = new List<String>();
		for (String field : fieldSet) {
			field = relationshipName + '.' + field;
			fieldSetCopy.add(field);
		}
		return String.join(fieldSetCopy, ', ');
	}

	public class CommunityThemeCategory {
		public Community_Theme__c Theme { get; set; }
		public List<List<Community_Tag__c>> Tags { get; set; }

		public CommunityThemeCategory(Community_Theme__c t, List<Community_Tag__c> themeTags) {
			this.Theme = t;
			this.Tags = CommunityDiscoverController.chunkList(themeTags, 4);
		}
	}


	@RemoteAction
	public static DiscoverResultClass getGroups(Integer limitSize, Integer startFrom, String targetId) {
		String currentCommunityId = CommunityGroupsBase.getCurrentCommunityId();

		List<CollaborationGroupMember> collaborationGroupMemberList = [
			SELECT MemberId, Id, CollaborationRole,
				CollaborationGroupId,
				CollaborationGroup.Id, CollaborationGroup.Name, CollaborationGroup.Description,
				CollaborationGroup.InformationTitle, CollaborationGroup.InformationBody,
				CollaborationGroup.SmallPhotoUrl, CollaborationGroup.FullPhotoUrl, CollaborationGroup.MemberCount,
				CollaborationGroup.LastFeedModifiedDate,
				CollaborationGroup.OwnerId, CollaborationGroup.NetworkId, CollaborationGroup.IsArchived,
				CollaborationGroup.CollaborationType, CollaborationGroup.CanHaveGuests,
				CollaborationGroup.Owner.Name, CollaborationGroup.Owner.FirstName,
				CollaborationGroup.Owner.LastName, CollaborationGroup.Owner.SmallPhotoUrl
			FROM CollaborationGroupMember
			WHERE CollaborationGroup.NetworkId =: currentCommunityId
			AND MemberId =: UserInfo.getUserId()
			ORDER BY CollaborationGroup.Name
		];
		Map<Id, CollaborationGroupMember> CollaborationGroupMemberMap = new Map<Id, CollaborationGroupMember>();
		for (CollaborationGroupMember item : collaborationGroupMemberList) {
			CollaborationGroupMemberMap.put(item.CollaborationGroup.Id, item);
		}

		List<ChatterGroupDetail> result = new List<ChatterGroupDetail>();
		List<Community_Group_Control__c> allGroups = [
			SELECT Id, Name, Description__c, Image_Path__c,
			Chatter_Group_ID__c, Type__c
			FROM Community_Group_Control__c 
			WHERE Id IN (SELECT Group_Control__c FROM Community_Group_Control_Tag__c WHERE Community_Tag__c = :targetId AND Group_Control__c != NULL)
			AND Chatter_Group_ID__c != NULL
			LIMIT :limitSize 
			OFFSET :startFrom
		];
		Set<String> chatterGroupsIds = new Set<String>();
		for (Community_Group_Control__c item : allGroups) {
			chatterGroupsIds.add(item.Chatter_Group_ID__c);
		}
		//ALL MEMBERS
		List<CollaborationGroupMember> collaborationGroupMembersList = [
			SELECT MemberId, Id, CollaborationGroupId
			FROM CollaborationGroupMember
			WHERE CollaborationGroup.NetworkId =: currentCommunityId
			AND CollaborationGroupId IN :chatterGroupsIds
			ORDER BY CollaborationGroup.Name
		];
		Map<Id, Integer> groupMembersCountMap = new Map<Id, Integer>();
		for (CollaborationGroupMember item : collaborationGroupMembersList) {
			Integer cnt = groupMembersCountMap.containsKey(item.CollaborationGroupId) ? groupMembersCountMap.get(item.CollaborationGroupId) : 0;
			cnt += 1;
			groupMembersCountMap.put(item.CollaborationGroupId, cnt);
		}
		for (Community_Group_Control__c item : allGroups) {
			ChatterGroupDetail groupDetail = new ChatterGroupDetail(item);
			if (CollaborationGroupMemberMap.get(item.Id) == NULL) {
				groupDetail.CurrentMemberRole = 'NotAMember';
			}
			else {
				groupDetail.CurrentMemberRole = CollaborationGroupMemberMap.get(item.Id).CollaborationRole;
			}
			groupDetail.GroupMembersCount = groupMembersCountMap.containsKey(item.Chatter_Group_ID__c) ? groupMembersCountMap.get(item.Chatter_Group_ID__c) : 0;
			result.add(groupDetail);
		}
		DiscoverResultClass outputResult = new DiscoverResultClass(allGroups.size(), result);
		return outputResult;
	}
	@RemoteAction
	public static DiscoverResultClass getEvents(Integer limitSize, Integer startFrom, String targetId) {
		String currentCommunityId = CommunityGroupsBase.getCurrentCommunityId();
		
		List<Community_Events__c> pageRecords = [
			SELECT Id, Name__c, Teaser__c, Start__c
			FROM Community_Events__c 
			WHERE Id IN (SELECT Community_Event__c FROM Community_Event_Tag__c WHERE Community_Tag__c = :targetId)
			LIMIT :limitSize 
			OFFSET :startFrom
		];

		DiscoverResultClass outputResult = new DiscoverResultClass();
		outputResult.TotalRecords = pageRecords.size();
		outputResult.Events = pageRecords;
		return outputResult;
	}
	@RemoteAction
	public static DiscoverResultClass getNews(Integer limitSize, Integer startFrom, String targetId) {
		String currentCommunityId = CommunityGroupsBase.getCurrentCommunityId();

		List<Community_News__c> pageRecords = [
			SELECT Id, Image_Path__c, Teaser__c, Name, Title__c, Entry_Date__c
			FROM Community_News__c 
			WHERE Id IN (SELECT Community_News__c FROM Community_News_Tag__c WHERE Community_Tag__c = :targetId)
			LIMIT :limitSize 
			OFFSET :startFrom
		];

		DiscoverResultClass outputResult = new DiscoverResultClass();
		outputResult.TotalRecords = pageRecords.size();
		outputResult.News = pageRecords;
		return outputResult;
	}
}
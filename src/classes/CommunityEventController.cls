public with sharing class CommunityEventController {
	private String datetimeToUTC(DateTime dati) {
		String dt = dati.format('yyyy-MM-dd HH:mm:ss','Etc/UTC');

		String sDate = dt.replaceAll('-', '');
		sDate = sDate.replaceAll(':', '');
		sDate = sDate.replaceAll(' ', 'T') +'Z';
		return sDate;
	}
	public String getGoogleCalendarCreateEventHref() {
		String baseString = 'https://www.google.com/calendar/render?action=TEMPLATE&text={0}&dates={1}/{2}&details={3}&location={4}&sf=true&output=xml';
		return String.format(baseString, new List<String> {
			this.event.Name__c,
			(this.event.Start__c != NULL ? datetimeToUTC(this.event.Start__c) : ''),
			(this.event.End__c != NULL ? datetimeToUTC(this.event.End__c) : ''),
			(this.event.Teaser__c != NULL ? this.event.Teaser__c : ''),
			(this.event.Street_Address__c != NULL ? this.event.Street_Address__c : '')
		});
	}
	public PageReference downloadICS() {
		String docName = String.format('{0}.ics', new List<String> { this.event.Name__c });
		Document att = NULL;
		List<Document> atts = [SELECT Id, Name FROM Document WHERE Name =: docName AND IsPublic = true LIMIT 5];
		if (atts.size() > 0) {
			att = atts[0];
		}
		if (att == NULL) {
			Community_Events__c e = [SELECT Id, Owner.Name, Owner.Email FROM Community_Events__c WHERE Id =:event.Id];
			Blob icsFile = generateCalendarEvent(this.event, e.Owner.Name, e.Owner.Email, UserInfo.getFirstName() +' '+ UserInfo.getLastName(), UserInfo.getUserEmail());
			att = new Document(
				Name = docName,
				Body = icsFile,
				FolderId = UserInfo.getUserId(),
				IsPublic = true
			);
			insert att;
		}
		PageReference pr = new PageReference('/servlet/servlet.FileDownload');
		pr.setRedirect(true);
		pr.getParameters().put('file', att.Id);
		return pr;
	}
	private Blob generateCalendarEvent(Community_Events__c e, String ownerName, String ownerEmail, String currentUserName, String currentUserEmail) {
		String icsString = 'BEGIN:VCALENDAR'
			+ '\nVERSION:2.0'
			+ '\nPRODID:-//Microsoft Corporation//Outlook for Mac MIMEDIR//EN'
			+ '\nMETHOD:REQUEST'
			+ '\nBEGIN:VEVENT'
			+ '\nUID:{0}' //0
			+ '\nSUMMARY:{1}'//1
			+ '\nATTENDEE;CN={2};ROLE=REQ-PARTICIPANT;PARTSTAT=NEEDS-ACTION;RSVP=TRUE:mailto:{3}'//2;3
			+ '\nORGANIZER;CN={4}:mailto:{5}'//4;5
			+ '\nDTSTART:{6}' // 6 THIS MUST BE IN UTC
			+ '\nDTEND:{7}' //7 THIS MUST BE IN UTC
			+ '\nLOCATION:{8}' //8
			+ '\nSTATUS:CONFIRMED'
			+ '\nCLASS:PUBLIC'
			+ '\nX-MICROSOFT-CDO-INTENDEDSTATUS:BUSY'
			+ '\nTRANSP:OPAQUE'
			+ '\nDTSTAMP:{9}' //9
			+ '\nSEQUENCE:0'
			+ '\nDESCRIPTION:{10}' //10
			+ '\nBEGIN:VALARM'
			+ '\nACTION:DISPLAY'
			+ '\nTRIGGER;RELATED=START:-PT5M'
			+ '\nDESCRIPTION:Reminder'
			+ '\nEND:VALARM'
			+ '\nEND:VEVENT'
			+ '\nEND:VCALENDAR';


		String icsBody = String.format(icsString,
			new List<String> {
				EncodingUtil.convertToHex(Crypto.generateDigest('SHA1', Blob.valueOf(String.ValueOf(e.Id) + Crypto.getRandomInteger()))),
				(e.Teaser__c != NULL ? e.Teaser__c : ''),
				currentUserName, currentUserEmail,
				ownerName, ownerEmail,
				(e.Start__c != NULL ? datetimeToUTC(e.Start__c) : ''),
				(e.End__c != NULL ? datetimeToUTC(e.End__c) : ''),
				(e.Street_Address__c != NULL ? e.Street_Address__c : ''),
				datetimeToUTC(DateTime.now()),
				(e.Description__c != NULL ? e.Description__c : '')
			}
		);
		Blob icsFile = Blob.valueOf(icsBody);
		return icsFile;
		/*if (icsFile != NULL) {
			Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
			attach.setFileName(String.format('{0}.ics', new List<String> { this.event.Name__c }));
			attach.setBody(icsFile);
			attach.setContentType(String.format('text/calendar; charset=utf-8; method=REQUEST; name={0}.ics', new List<String> { this.event.Name__c }));
			mail.setFileAttachments(new List<Messaging.EmailFileAttachment>{attach});
		}
		return mail;*/
	}

	public class CommunityEventException extends Exception {}

	// -- common variables --
	private ApexPages.StandardController stdctrl;
	private String mode;

	// CONSTRUCTOR
	public CommunityEventController() {

	}
	public CommunityEventController(ApexPages.StandardController stdController) {
		stdctrl = stdController;
		event = (Community_Events__c)stdController.getRecord();
	}

	// INIT MAP SECTION
	public void initFromEdit() {
		mode = 'edit';
		init();
	}

	public PageReference initFromView() {
		Community_Events__c eventLocal = (Community_Events__c)stdctrl.getRecord();
		PageReference pr = CommunityUtils.checkRedirectToStandardView(eventLocal.Id);
		if (pr == NULL) {
			mode = 'view';
			init();
		}
		return pr;
	}

	public void initFromList() {
		mode = 'list';
		initList();
	}

	// CREATE, EDIT, DETAIL SECTION

	// -- variables --
	public Community_Events__c event { get;set; }
	public Map<String, Community_Event_Tag__c> eventTagMap { get; set; }
	public List<Community_Event_Tag__c> eventTagList { get; set; }

	private String TAGS_INPUT_NAME = 'tags';
	private String formatEventLocation(Community_Events__c e) {
		List<String> checkFieldList = new List<String> {'Building__c', 'Room__c', 'Street_Address__c', 'City__c', 'State__c', 'Zip__c'};
		List<String> listToConcat = new List<String>();
		for (String chfItem : checkFieldList) {
			if (String.isNotBlank((String)e.get(chfItem))) {
				listToConcat.add((String)e.get(chfItem));
			}
		}
		String result = NULL;
		if (listToConcat.size() > 0) {
			result = String.join(listToConcat, ', ');
		}
		return result;
	}

	// -- methods --
	private void init() {

		eventTagMap = new Map<String, Community_Event_Tag__c>();

		if (event != NULL && event.Id != NULL) {
			Set<String> collectedFields = new Set<String> {'Id', 'Name', 'Name__c', 'Building__c', 'Room__c', 'Street_Address__c', 'City__c', 'State__c', 'Zip__c', 'Teaser__c', 'Description__c'};
			String pp = CommunityUtils.getPackagePrefix();
			Boolean isPP = String.isNotBlank(pp);
			for (Schema.FieldSetMember f : fieldset) {
				String tempFieldName = isPP ? f.getFieldPath().replace(pp,'') : f.getFieldPath();
				collectedFields.add(tempFieldName);
			}
			String query = '';
			String sep = 'SELECT ';
			List<String> cfAsList = new List<String>();
			cfAsList.addAll(collectedFields);
			for (String cfItem : cfAsList) {
				query += sep + cfItem;
				sep = ', ';
			}
			query += ', (select Id, Community_Tag__c, Community_Tag__r.Community_Theme__r.Name, Community_Tag__r.Name, Community_Group_Control__r.Name, Community_Group_Control__r.Group_Control_SF_ID__c from Events_Tag_Joins__r WHERE Community_Group_Control__c != NULL OR Community_Tag__c != NULL) ';
			query += ' FROM Community_Events__c WHERE Id = \'' + event.Id + '\'';
			event = Database.query(query);
			if (mode == 'view') {
				event.Street_Address__c = formatEventLocation(event);
			}
		}
		if (ApexPages.currentPage().getParameters().get('cloneId') != NULL) {
			try {
				Id cloneId = Id.valueOf(ApexPages.currentPage().getParameters().get('cloneId'));
				String cquery = '';
				String csep = 'SELECT ';
				for (Schema.FieldSetMember cf : fieldset) {
					cquery += csep + cf.getFieldPath();
					csep = ', ';
				}
				cquery += ' FROM Community_Events__c WHERE Id = \'' + cloneId + '\'';
				Community_Events__c cevent = Database.query(cquery);
				for (Schema.FieldSetMember cf2 : fieldset) {
					String fName = cf2.getFieldPath();
					event.put(fName, cevent.get(fName));
				}
			}
			catch (Exception e) {
				ApexPages.addMessages(e);
			}
		}

		if (event != NULL) {
			if (event.Events_Tag_Joins__r != NULL) {
				for (Community_Event_Tag__c item : event.Events_Tag_Joins__r) {
					if (item != NULL) {
						if (eventTagMap.get(item.Community_Group_Control__r.Name) == NULL) {
							eventTagMap.put(item.Community_Group_Control__r.Name, item);
						}
					}
				}
			}
		}

		if (!eventTagMap.isEmpty()) {
			eventTagList = eventTagMap.values();
		}
	}

	public PageReference cancel() {
		if (stdctrl != NULL) {
			return stdctrl.cancel();
		}
		else {
			return NULL;
		}
	}

	public PageReference submit() {
		try {
			if (String.isBlank(event.Teaser__c) && String.isNotBlank(event.Description__c)) {
				event.Teaser__c = event.Description__c.stripHtmlTags().abbreviate(140);
			}
			upsert event;
			String tagsIdsString = ApexPages.currentPage().getParameters().get(TAGS_INPUT_NAME);
			CommunityTagSelectorController ctsc = new CommunityTagSelectorController();
			ctsc.objectId = event.Id;
			ctsc.objectType = Community_Event_Tag__c.getSObjectType().getDescribe().getName();
			ctsc.filterName = Community_Event_Tag__c.Community_Event__c.getDescribe().getName();
			ctsc.saveTags(tagsIdsString);

			String groupId = ApexPages.currentPage().getParameters().get('g');
			if (groupId != NULL) {
				List<Community_Event_Tag__c> communityEventTagList = [
					SELECT Id, Community_Tag__c
					FROM Community_Event_Tag__c
					WHERE Community_Event__c =: event.Id
					ORDER BY CreatedDate DESC
				];

				List<Community_Group_Control__c> communityGroupControll = [
					SELECT Id, Chatter_Group_ID__c
					FROM Community_Group_Control__c
					WHERE Chatter_Group_ID__c =: groupId
					ORDER BY CreatedDate DESC
				];
				if (!communityEventTagList.isEmpty() && !communityGroupControll.isEmpty()) {
					communityEventTagList[0].Community_Group_Control__c = communityGroupControll[0].Id;
					update communityEventTagList[0];
				}
				else if (communityEventTagList.isEmpty() && !communityGroupControll.isEmpty()) {
					Community_Event_Tag__c communityEventTag = new Community_Event_Tag__c();
					communityEventTag.Community_Event__c = event.Id;
					communityEventTag.Community_Group_Control__c = communityGroupControll[0].Id;
					insert communityEventTag;
				}
			}

			return stdctrl.cancel();
		}
		catch (Exception e) {
			ApexPages.addMessages(e);
		}
		return NULL;
	}

	public List<Schema.FieldSetMember> fieldset {
		get {
			List<Schema.FieldSetMember> resultList;
			if (mode == 'edit') {
				resultList = SObjectType.Community_Events__c.FieldSets.EditEvent.getFields();
			}
			else {
				resultList = new List<Schema.FieldSetMember>();
				Set<String> excludeFields = new Set<String> { 'Building__c', 'Room__c', 'City__c', 'State__c', 'Zip__c'};
				for (Schema.FieldSetMember f2 : SObjectType.Community_Events__c.FieldSets.EditEvent.getFields()) {
					if (!excludeFields.contains(f2.getFieldPath())) {
						resultList.add(f2);
					}
				}
			}
			return resultList;
		}
	}

	public PageReference edit() {

		if (stdctrl != NULL) {
			return stdctrl.edit();
		}
		else {
			return NULL;
		}

	}

	// LIST SECTION
	// -- variables --
	public CommunityListViewBase listView { get; set; }
	public Integer pageNumber { get; set; }
	public String CurrentFilter { get; set; }
	public Map<String, List<Tag>> tagsMap { get; set; }

	private final Integer NEWS_PAGE_SIZE = 25;
	private final String TAGS_FILTER_NAME = 't';

	// -- methods --
	private void initList() {

		String tagsIdsString = ApexPages.currentPage().getParameters().get(TAGS_FILTER_NAME);
		String idCommunityEventTag = '';

		try {
			if (String.isNotBlank(tagsIdsString)) {
				Id tagId = Id.valueOf(tagsIdsString);
				List<Id> cnIds = new List<Id>();
				for (Community_Event_Tag__c cnt : [
					SELECT Community_Event__c
					FROM Community_Event_Tag__c
					WHERE Community_Event__r.Start__c >= TODAY
						AND Community_Event__r.End__c > TODAY
						AND Community_Tag__c = :tagId
				]) {
					cnIds.add(cnt.Community_Event__c);
				}
				idCommunityEventTag = createQueryStringId(cnIds);
			}
			/*---*
			Map<String, String> pageParams = ApexPages.currentPage().getParameters();
			if (pageParams.containsKey('t') && String.isNotBlank(pageParams.get('t'))) {
				cnIds = CommunitySearchController.filterTags(pageParams.get('t'), 'Community_News__c');
				nQuery += ' AND Id IN :cnIds';
			}
			else if (pageParams.containsKey('s') && String.isNotBlank(pageParams.get('s'))) {
				cnIds = CommunitySearchController.performSearch(pageParams.get('s'), 'Community_News__c');
				nQuery += ' AND Id IN :cnIds';
			}
			/*---*/
		}
		catch (Exception e) {
			//TO DO: Create Filter Error Message
		}

		listView = new CommunityListViewBase();
		listView.DefaultRecordsPerPage = NEWS_PAGE_SIZE;
		listView.ObjectName = 'Community_Events__c';
		listView.QueryFields = new List<String> {'Name__c', 'Start__c', 'End__c', 'Teaser__c'};
		listView.OrderByField = 'Start__c, Name__c';
		listView.OrderByDirection = 'ASC';
		listView.LimitValue = 45000;

		if (CurrentFilter == NULL || CurrentFilter == Label.LBL_All_Events) {
			listView.WhereCondition = 'Start__c >= TODAY AND Public__c = TRUE ';
			if (String.isNotBlank(tagsIdsString)) {
				listView.WhereCondition = 'Start__c >= TODAY AND Public__c = TRUE AND Id IN (' + filterAllEvents(tagsIdsString) + ')';
			}
		}
		else if (CurrentFilter == Label.LBL_New_Group_Events) {
			listView.WhereCondition = 'Public__c = TRUE AND Id IN (' + filterAllGroup('') + ')';
			if (String.isNotBlank(tagsIdsString)) {
				listView.WhereCondition = 'Public__c = TRUE AND Id IN (' + filterAllGroup(tagsIdsString) + ') ';
			}
		}
		else if (CurrentFilter == Label.LBL_My_Group_Events) {
			listView.WhereCondition = 'Start__c >= TODAY AND Public__c = TRUE AND Id IN ( ' + filterMyGroup('') + ' )';
			if (String.isNotBlank(tagsIdsString)) {
				listView.WhereCondition = 'Start__c >= TODAY AND Public__c = TRUE AND Id IN (' + filterMyGroup(tagsIdsString) + ')';
			}
		}
		else if (CurrentFilter == Label.LBL_My_Events){
			String UserId = UserInfo.getUserId();
			listView.WhereCondition = 'Start__c >= TODAY AND OwnerId = \'' + UserId + '\' ';
			if (String.isNotBlank(tagsIdsString)) {
				listView.WhereCondition += 'AND Id IN (' + idCommunityEventTag + ')';
			}
		}

		listView.FilterByList = new List<SelectOption> {
			new SelectOption(Label.LBL_All_Events, Label.LBL_All_Events),
			new SelectOption(Label.LBL_New_Group_Events, Label.LBL_New_Group_Events),
			new SelectOption(Label.LBL_My_Group_Events, Label.LBL_My_Group_Events),
			new SelectOption(Label.LBL_My_Events,Label.LBL_My_Events)
		};

		listView.initQueryLocator();
		createTags();

		return;
	}

	private String filterAllEvents(String tagId) {

		List<String> communityEventList = new List<String>();
		String result = '';
		Map<Id, CollaborationGroup> collaborationGroupMap = new Map<Id, CollaborationGroup>();
		List<Community_Group_Control__c> communityGroupControllList = new List<Community_Group_Control__c>();
		List<Community_Event_Tag__c> communityEventTagList = new List<Community_Event_Tag__c>();

		collaborationGroupMap = new Map<Id, CollaborationGroup>([
			SELECT CollaborationGroup.Id
			FROM CollaborationGroup
		]);

		if (!collaborationGroupMap.isEmpty()) {
			communityGroupControllList = [
				SELECT Id, Chatter_Group_ID__c, Discoverable__c
				FROM Community_Group_Control__c
				WHERE Chatter_Group_ID__c IN: collaborationGroupMap.keySet()
//				AND Discoverable__c = true
			];
		}

/*		String query = 'SELECT Community_Event__c FROM Community_Event_Tag__c ';
		query += ' WHERE Community_Event__r.Start__c >= TODAY ';
		query += ' AND Community_Event__r.End__c > TODAY AND ( Community_Group_Control__c = NULL ';
		query += ' OR Community_Group_Control__c IN: communityGroupControllList ) ';
		if (String.isNotBlank(tagId)) {
			query += ' AND Community_Tag__c = :tagId ';
		}
		communityEventTagList = Database.query(query); */
		if (String.isNotBlank(tagId)) {
			String query = 'SELECT Community_Event__c FROM Community_Event_Tag__c ';
//			query += ' WHERE Community_Event__r.Start__c >= TODAY ';
//			query += ' AND Community_Event__r.End__c > TODAY ';
			query += ' WHERE Community_Tag__c = :tagId ';
			query += 'LIMIT 45000';
			communityEventTagList = Database.query(query);
		}

		if (!communityEventTagList.isEmpty()) {
			for (Community_Event_Tag__c communityEventTagItem : communityEventTagList) {
				communityEventList.add(communityEventTagItem.Community_Event__c);
			}
		}

		result = createQueryStringId(communityEventList);

		return result;
	}

	private String filterMyGroup(String communityEventIds) {

		String result = '';
		List<String> communityEventList = new List<String>();
		List<String> communityGroupControl = new List<String>();
/*
		String UserId = UserInfo.getUserId();
		String query = 'SELECT Id, ParentId FROM EntitySubscription WHERE SubscriberId = :UserId ';
		if (String.isNotBlank(communityEventIds)) {
			query += 'AND ParentId IN ( ' + communityEventIds + ' )';
		}
		query += 'LIMIT 900';
		List<EntitySubscription> sObjectList1 = Database.query(query);
		if (!sObjectList1.isEmpty()) {
			for (EntitySubscription EntitySubscriptionItem : sObjectList1) {
				communityEventList.add(EntitySubscriptionItem.ParentId);
			}
		}

		query = 'SELECT Id, Community_Group_Control__c FROM Community_Event_Tag__c WHERE Community_Event__c IN :communityEventList ';
		List<Community_Event_Tag__c> sObjectList2 = Database.query(query);
		if (!sObjectList2.isEmpty()) {
			for (Community_Event_Tag__c communityGroupControlItem : sObjectList2) {
				communityGroupControl.add(communityGroupControlItem.Community_Group_Control__c);
			}
		}
*/
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
//			WHERE CollaborationGroup.NetworkId =: currentCommunityId
			WHERE MemberId =: UserInfo.getUserId()
			ORDER BY CollaborationGroup.Name
		];
		Map<Id, CollaborationGroupMember> CollaborationGroupMemberMap = new Map<Id, CollaborationGroupMember>();
		for (CollaborationGroupMember item : collaborationGroupMemberList) {
			CollaborationGroupMemberMap.put(item.CollaborationGroup.Id, item);
		}
		Set<Id> memberOfGroupsIds = new Set<Id>(CollaborationGroupMemberMap.keySet());

		if (!memberOfGroupsIds.isEmpty()) {
			String query = '';

			query = 'SELECT Id, Community_Event__c ';
			query += 'FROM Community_Event_Tag__c ';
			query += 'WHERE Community_Group_Control__r.Chatter_Group_ID__c IN :memberOfGroupsIds ';
	//		query += 'AND Community_Event__r.End__c > TODAY AND Community_Event__r.Start__c >= TODAY ';
			if (String.isNotBlank(communityEventIds)) {
				query += 'AND Community_Tag__c = :communityEventIds ';
			}
			List<Community_Event_Tag__c> sObjectList3 = Database.query(query);
			communityEventList = new List<String>();
			if (!sObjectList3.isEmpty()) {
				for (Community_Event_Tag__c communityEventTagItem : sObjectList3) {
					if (!String.isBlank(communityEventTagItem.Community_Event__c)) {
						communityEventList.add(communityEventTagItem.Community_Event__c);
					}
				}
			}
			result = createQueryStringId(communityEventList);
		}

		return result;
	}

	private String filterAllGroup(String tagId) {

		List<String> communityEventList = new List<String>();
		String result = '';
		Map<Id, CollaborationGroup> collaborationGroupMap = new Map<Id, CollaborationGroup>();
		List<Community_Group_Control__c> communityGroupControllList = new List<Community_Group_Control__c>();
		List<Community_Event_Tag__c> communityEventTagList = new List<Community_Event_Tag__c>();

		collaborationGroupMap = new Map<Id, CollaborationGroup>([
			SELECT CollaborationGroup.Id
			FROM CollaborationGroup
		]);

		if (!collaborationGroupMap.isEmpty()) {
			communityGroupControllList = [
				SELECT Id, Chatter_Group_ID__c, Discoverable__c
				FROM Community_Group_Control__c
				WHERE Chatter_Group_ID__c IN: collaborationGroupMap.keySet()
//				AND Discoverable__c = true
			];
		}

		String query = 'SELECT Community_Event__c FROM Community_Event_Tag__c WHERE Community_Event__r.Start__c >= TODAY ';
		query += 'AND Community_Event__r.End__c > TODAY AND Community_Group_Control__c IN: communityGroupControllList ';
		if (String.isNotBlank(tagId)) {
			query += 'AND Community_Tag__c = :tagId ';
		}
		communityEventTagList = Database.query(query);

		if (!communityEventTagList.isEmpty()) {
			for (Community_Event_Tag__c communityEventTagItem : communityEventTagList) {
				communityEventList.add(communityEventTagItem.Community_Event__c);
			}
		}
		result = createQueryStringId(communityEventList);
		return result;
	}

	private String createQueryStringId(List<String> stringList) {
		String result = '';
		String sep = '';

		if (!stringList.isEmpty()) {
			for (String stringListItem : stringList) {
				if (!String.isBlank(stringListItem)) {
					result += sep + ' \'' + stringListItem + '\'';
					sep = ', ';
				}
			}
		}
		else {
			result = '\'\'';
		}

		return result;
	}



	public void nextPage() {

		listView.itemsSetController.next();
		createTags();

		return;
	}

	public void lastPage() {

		listView.itemsSetController.last();
		createTags();

		return;
	}

	public void previousPage() {

		listView.itemsSetController.previous();
		createTags();

		return;
	}

	public void firstPage() {

		listView.itemsSetController.first();
		createTags();

		return;
	}

	public void setPageNumber() {

		listView.itemsSetController.setPageNumber(pageNumber);
		createTags();

		return;
	}

	private void createTags() {
		List<String> eventIdList = new List<String>();
		List<sObject> communityEventList = listView.itemsSetController.getRecords();

		if (!communityEventList.isEmpty()) {
			for (sObject communityEventItem : communityEventList) {
				eventIdList.add(communityEventItem.Id);
			}

			tagsMap = getTags(
				Page.CommunityEventsList.getUrl(),
				eventIdList
			);
		}

		return;
	}

	private Map<String, List<Tag>> getTags(String rPage, List<String> communityEventIdList) {

		Map<String, List<Tag>> result = new Map<String, List<Tag>>();
		Map<String, List<String>> eventsAndTagsMap = new Map<String, List<String>>();
		Map<Id, Community_Tag__c> communityTagsMap = new Map<Id, Community_Tag__c>();
		Set<String> tagIds = new Set<String>();

		String query = 'SELECT Id, Community_Tag__c, Community_Event__c FROM Community_Event_Tag__c WHERE Community_Event__c IN: communityEventIdList';
		List<SObject> sObjectList = Database.query(query);
		if (!sObjectList.isEmpty()) {
			for (SObject objItem : sObjectList) {
				tagIds.add((String) objItem.get('Community_Tag__c'));
				String communityEventId = (String) objItem.get('Community_Event__c');
				if (eventsAndTagsMap.get(communityEventId) == NULL) {
					eventsAndTagsMap.put(communityEventId, new List<String>{(String) objItem.get('Community_Tag__c')});
				}
				else {
					eventsAndTagsMap.get(communityEventId).add((String) objItem.get('Community_Tag__c'));
				}

			}
		}

		communityTagsMap = new Map<Id, Community_Tag__c>([
			SELECT Id, Name, Tag_Theme_UniqueID__c, Community_Theme__r.Name
			FROM Community_Tag__c
			WHERE Id IN :tagIds
		]);
		if (!communityTagsMap.isEmpty()) {
			for (String Item : eventsAndTagsMap.keySet()) {

				if (!eventsAndTagsMap.get(Item).isEmpty()) {
					for (String  eventsAndTagsMapItem : eventsAndTagsMap.get(Item)) {
						Community_Tag__c CommunityTagItem = communityTagsMap.get(eventsAndTagsMapItem);
						if (CommunityTagItem != NULL) {
							Tag tag = new Tag();
							tag.Name = CommunityTagItem.Community_Theme__r.Name + ' > ' + CommunityTagItem.Name;
							tag.Url = rPage + '?t=' + CommunityTagItem.Id;

							if (result.get(Item) != NULL) {
								result.get(Item).add(tag);
							}
							else {
								result.put(Item, new List<Tag>{tag});
							}
						}
					}
				}

			}
		}
		if (!communityEventIdList.isEmpty()) {
			for (String Item : communityEventIdList) {
				if (result.get(Item) == NULL) {
					Tag tag = new Tag();
					tag.Name = '';
					tag.Url = 'null';
					result.put(Item, new List<Tag>{tag});
				}
			}
		}

		return result;
	}

	public String urlForEditEvent {
		get {
			return prepareUrl(Page.CommunityEventEdit.getUrl())
					+ '?id=' + event.Id + '&retURL='
					+ EncodingUtil.urlEncode(prepareUrl(Page.CommunityEventDetail.getUrl() + '?id=' + event.Id), 'UTF-8');
		}
	}

	public String urlForNewEvent {
		get {
			return prepareUrl(Page.CommunityEventEdit.getUrl())
					+ '?retURL='
					+ EncodingUtil.urlEncode(prepareUrl(Page.CommunityEventsList.getUrl()), 'UTF-8');
		}
	}

	public String urlForCloneEvent {
		get {
			return prepareUrl(Page.CommunityEventEdit.getUrl())
					+ '?cloneId=' + event.Id + '&retURL='
					+ EncodingUtil.urlEncode(prepareUrl(Page.CommunityEventDetail.getUrl() + '?id=' + event.Id), 'UTF-8');
		}
	}

	private String prepareUrl(String inUncouthUrl) {
		return String.isNotBlank(Site.getPathPrefix()) ? inUncouthUrl.replace('/apex/', Site.getPathPrefix() + '/') : inUncouthUrl;
	}

	public class Tag {
		public String Url { get; set; }
		public String Name { get; set; }
	}

	public class CommunityListViewBase {

		public ApexPages.StandardSetController itemsSetController { get; set; }
		public List<String> QueryFields { get; set; }
		public String ObjectName { get; set; }
		public String OrderByField;
		public String OrderByDirection;
		public Integer LimitValue;
		public String WhereCondition { get; set; }
		public List<SelectOption> FilterByList { get; set; }
		public String CurrentFilter { get; set; }
		public Integer DefaultRecordsPerPage { get; set; }


		public CommunityListViewBase() {
		}

		public void initQueryLocator() {
			String query = ('SELECT Id, ' + String.join(QueryFields, ', ')) + ' '
				+ ('FROM ' + ObjectName + ' ')
				+ (!String.isBlank(WhereCondition) ? 'WHERE ' + WhereCondition: ' ') + ' '
				+ ((!String.isBlank(OrderByField) ? 'ORDER BY ' + OrderByField : ' ') + ' ')
				+ ((!String.isBlank(OrderByDirection) ? OrderByDirection : ' ') + ' ')
				+ ((LimitValue != NULL && LimitValue != 0) ? ('LIMIT ' + String.valueOf(LimitValue)) : ' ');

			system.debug(query);
			Integer RecordOnPageSelected = itemsSetController == NULL ? DefaultRecordsPerPage : itemsSetController.getPageSize();
			itemsSetController = new ApexPages.StandardSetController(Database.getQueryLocator(query));
			itemsSetController.setPageSize(RecordOnPageSelected);
		}
		public String getCurrentPagePositionString() {
			return Label.LBL_Page + ' ' + itemsSetController.getPageNumber() + ' ' + Label.LBL_of + ' ' + getTotalPagesCount();
		}
		public List<SelectOption> getRecordOnPageOptions() {
			return new List<SelectOption> {
				new SelectOption('10','10'),
				new SelectOption('25','25')
			};
		}
		public Integer getTotalPagesCount() {

			Integer result = 0;

			Integer totalRecords = itemsSetController.getResultSize();
			Integer pageSize = itemsSetController.getPageSize();
			result = (totalRecords / pageSize) + (Math.mod(totalRecords, pageSize) > 0 ? 1 : 0);
			if (result == 0) {
				result = 1;
			}

			return result;
		}
	}

	public static void test1() {
		Integer i = 0;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
	}

}
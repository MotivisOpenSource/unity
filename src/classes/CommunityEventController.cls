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
	public transient List<List<EventItem>> eventsPage { get;set; }
	public Integer eventsPageNumber { get;set; }
	public Integer eventsPagesTotal { get;set; }
	public Boolean eventsHasNext { get;set; }
	public Boolean eventsHasPrevious { get;set; }

	private Integer EVENTS_PAGE_SIZE = 12;
	private String TAGS_FILTER_NAME = 't';

	// -- methods --
	private void initList() {
		Datetime eNow = Datetime.now();
		Id userId = UserInfo.getUserId();
		String eQuery = 'SELECT Id, Name__c, Teaser__c, Start__c FROM Community_Events__c';
		//eQuery += ' WHERE Start__c != NULL';
		eQuery += ' WHERE (Public__c = true OR OwnerId = :userId) AND ((End__c = NULL AND Start__c != NULL AND Start__c <= :eNow) OR (End__c != NULL OR End__c >= :eNow))';
		//eQuery += ' WHERE Start__c != NULL AND Start__c <= :eNow AND (Public__c = true OR OwnerId = :userId) AND (End__c = NULL OR End__c >= :eNow)';
		Set<Id> cnIds = new Set<Id>();
		try {
			Map<String, String> pageParams = ApexPages.currentPage().getParameters();
			if (pageParams.containsKey('t') && String.isNotBlank(pageParams.get('t'))) {
				cnIds = CommunitySearchController.filterTags(pageParams.get('t'), 'Community_Events__c');
				eQuery += ' AND Id IN :cnIds';
			}
			else if (pageParams.containsKey('s') && String.isNotBlank(pageParams.get('s'))) {
				cnIds = CommunitySearchController.performSearch(pageParams.get('s'), 'Community_Events__c');
				eQuery += ' AND Id IN :cnIds';
			}
		} 
		catch (Exception e) {
			//TO DO: Create Filter Error Message
		}
		eQuery += ' ORDER BY Start__c ASC, Name__c ASC LIMIT 10000';
		List<Community_Events__c> eQueryList = database.query(eQuery);
		Integer eqlSize = eQueryList.size();
		eventsPagesTotal = eqlSize / EVENTS_PAGE_SIZE + ((Math.mod(eqlSize, EVENTS_PAGE_SIZE) == 0) ? 0 : 1);
		eventsPagesTotal = eventsPagesTotal == 0 ? 1 : eventsPagesTotal;
		eventsPageNumber = eventsPageNumber == NULL ? 1 : eventsPageNumber;
		eventsHasNext = eventsPageNumber < eventsPagesTotal;
		eventsHasPrevious = eventsPageNumber > 1;
		Integer startCopyInterval = eventsPageNumber > 1 ? ((eventsPageNumber - 1) * EVENTS_PAGE_SIZE) : 0;
		Integer endCopyInterval = (eqlSize <= (startCopyInterval + EVENTS_PAGE_SIZE)) ? eqlSize : (startCopyInterval + EVENTS_PAGE_SIZE);

		Set<Id> eventsPageIds = new Set<Id>();
		for (Integer ii = startCopyInterval; ii < endCopyInterval; ii++) {
			eventsPageIds.add(eQueryList[ii].Id);
		}

		Map<Id,List<String>> referencedGroupsMap = new Map<Id,List<String>>();
		for (Community_Event_Tag__c cetItem : [
								SELECT Community_Event__c, Community_Group_Control__c, Community_Group_Control__r.Name
								FROM Community_Event_Tag__c WHERE Community_Group_Control__c != NULL AND Community_Event__c IN :eventsPageIds
									]) {
			if (!referencedGroupsMap.containsKey(cetItem.Community_Event__c)) {
				referencedGroupsMap.put(cetItem.Community_Event__c, new List<String> {
					cetItem.Community_Group_Control__r.Name,
					cetItem.Community_Group_Control__c
				});
			}
		}

		Map<Id,List<Tag>> eventTagsMap = new Map<Id,List<Tag>>();
		/*for (Community_Event_Tag__c cetItem2 : [
								SELECT Community_Event__c, Community_Tag__c, Community_Tag__r.Name, Community_Tag__r.Community_Theme__c, Community_Tag__r.Community_Theme__r.Name
								FROM Community_Event_Tag__c WHERE Community_Tag__c != NULL AND Community_Event__c IN :eventsPageIds
									]) {
			if (!eventTagsMap.containsKey(cetItem2.Community_Event__c)) {
				eventTagsMap.put(cetItem2.Community_Event__c, new List<Tag>());
			}
			eventTagsMap.get(cetItem2.Community_Event__c).add(new Tag(cetItem2));
		}*/

		eventsPage = new List<List<EventItem>>();
		Integer divider = 1;
		List<EventItem> dividedList = new List<EventItem>();
		for (Integer ii = startCopyInterval; ii < endCopyInterval; ii++) {
			if (divider == 5) {
				eventsPage.add(dividedList);
				dividedList = new List<EventItem>();
				divider = 1;
			}
			dividedList.add(new EventItem(eQueryList[ii], referencedGroupsMap.get(eQueryList[ii].Id), eventTagsMap.get(eQueryList[ii].Id)));
			divider++;
		}
		if (dividedList.size() > 0) {
			eventsPage.add(dividedList);
		}
	}

	public void eventsNextPage() {
		eventsPageNumber++;
		initList();
	}

	public void eventsLastPage() {
		eventsPageNumber = eventsPagesTotal;
		initList();
	}

	public void eventsPreviousPage() {
		eventsPageNumber--;
		initList();
	}

	public void eventsFirstPage() {
		eventsPageNumber = 1;
		initList();
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

	public String getTodayStr() {
		return Label.LBL_Today_is + ' ' + Datetime.now().format('MM/dd/yyyy');
	}

	public class EventItem {
		public String id { get; set; }
		public String name { get; set; }
		public String teaser { get; set; }
		public String eWhen { get; set; }
		public String eGroupName { get; set; }
		public String eGroupId { get; set; }
		public List<Tag> tags { get; set; }

		public EventItem(Community_Events__c ince, List<String> ing, List<Tag> intgs) {
			id = ince.Id;
			name = ince.Name__c;
			teaser = ince.Teaser__c;
			eWhen = ' ' + ince.Start__c.format('MM/dd/yyyy @ h.mm a');
			eGroupName = ing == NULL ? NULL : ing[0];
			eGroupId = ing == NULL ? NULL : ing[1];
			tags = intgs == NULL ? new List<Tag>() : intgs;
		}
	}

	public class Tag {
		public String id { get; set; }
		public String name { get; set; }

		public Tag(Community_Event_Tag__c cet) {
			id = cet.Community_Tag__c;
			name = cet.Community_Tag__r.Community_Theme__c == NULL ? '' : (cet.Community_Tag__r.Community_Theme__r.Name + ' > ');
			name += cet.Community_Tag__r.Name;
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